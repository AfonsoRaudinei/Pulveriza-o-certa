import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/configuracoes.dart';
import '../../providers/configuracoes_provider.dart';
import '../../providers/regulagens_provider.dart';
import '../../services/storage_service.dart';
import '../../theme.dart';
import '../../widgets/app_button.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final _nome = TextEditingController();
  final _empresa = TextEditingController();
  final _desgaste = TextEditingController();
  final _irregular = TextEditingController();
  final _tolMin = TextEditingController();
  final _tolMax = TextEditingController();
  final _nomeFocus = FocusNode();
  final _empresaFocus = FocusNode();
  final _desgasteFocus = FocusNode();
  final _irregularFocus = FocusNode();
  final _tolMinFocus = FocusNode();
  final _tolMaxFocus = FocusNode();
  final _storage = StorageService();
  Timer? _limitesDebounce;
  ConfiguracoesProvider? _configProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncFromProvider();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<ConfiguracoesProvider>();
    if (_configProvider != provider) {
      _configProvider?.removeListener(_onConfigChanged);
      _configProvider = provider;
      _configProvider!.addListener(_onConfigChanged);
    }
  }

  @override
  void dispose() {
    _limitesDebounce?.cancel();
    _configProvider?.removeListener(_onConfigChanged);
    _nomeFocus.dispose();
    _empresaFocus.dispose();
    _desgasteFocus.dispose();
    _irregularFocus.dispose();
    _tolMinFocus.dispose();
    _tolMaxFocus.dispose();
    _nome.dispose();
    _empresa.dispose();
    _desgaste.dispose();
    _irregular.dispose();
    _tolMin.dispose();
    _tolMax.dispose();
    super.dispose();
  }

  void _onConfigChanged() {
    if (!mounted) return;
    _syncFromProvider();
  }

  void _syncFromProvider() {
    final config = _configProvider?.configuracoes ??
        context.read<ConfiguracoesProvider>().configuracoes;
    _syncField(_nome, _nomeFocus, config.nomeConsultor);
    _syncField(_empresa, _empresaFocus, config.empresaNome);
    _syncField(
        _desgaste, _desgasteFocus, config.limiteDesgaste.toStringAsFixed(2));
    _syncField(
        _irregular, _irregularFocus, config.limiteIrregular.toStringAsFixed(2));
    _syncField(_tolMin, _tolMinFocus, config.toleranciaMin.toStringAsFixed(2));
    _syncField(_tolMax, _tolMaxFocus, config.toleranciaMax.toStringAsFixed(2));
  }

  void _syncField(
    TextEditingController controller,
    FocusNode focus,
    String value,
  ) {
    if (controller.text == value) return;
    if (focus.hasFocus) return;
    controller.text = value;
  }

  void _onLimiteChanged() {
    _limitesDebounce?.cancel();
    _limitesDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_persistLimites());
    });
  }

  Future<void> _persistLimites() async {
    if (!mounted) return;
    final desgaste = _parse(_desgaste.text, 0);
    final entupido = _parse(_irregular.text, 0);
    if (desgaste <= 0 || entupido <= 0) return;
    try {
      await context.read<ConfiguracoesProvider>().saveLimites(
            limiteDesgaste: desgaste,
            limiteIrregular: entupido,
          );
    } on StorageException catch (error) {
      _feedback(error.message, erro: true);
    } catch (error) {
      debugPrint('Erro ao salvar limites: $error');
    }
  }

  void _feedback(String mensagem, {bool erro = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? AppColors.danger : null,
      ),
    );
  }

  /// Âncora do popover da folha de compartilhamento (exigida em iPad).
  Rect? _origemCompartilhar() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _save() async {
    try {
      final provider = context.read<ConfiguracoesProvider>();
      final atual = provider.configuracoes;
      await provider.save(
        atual.copyWith(
          nomeConsultor: _nome.text.trim(),
          empresaNome: _empresa.text.trim(),
          limiteDesgaste: _parse(_desgaste.text, atual.limiteDesgaste),
          limiteIrregular: _parse(_irregular.text, atual.limiteIrregular),
          toleranciaMin: _parse(_tolMin.text, atual.toleranciaMin),
          toleranciaMax: _parse(_tolMax.text, atual.toleranciaMax),
        ),
      );
      _feedback('Configurações salvas.');
    } on StorageException catch (error) {
      _feedback(error.message, erro: true);
    } catch (error) {
      debugPrint('Erro ao salvar configurações: $error');
      _feedback('Não foi possível salvar as configurações.', erro: true);
    }
  }

  Future<void> _saveTema(TemaApp tema) async {
    try {
      await context.read<ConfiguracoesProvider>().saveTema(tema);
    } on StorageException catch (error) {
      _feedback(error.message, erro: true);
    } catch (error) {
      debugPrint('Erro ao salvar tema: $error');
      _feedback('Não foi possível salvar o tema.', erro: true);
    }
  }

  Future<void> _export() async {
    try {
      await _storage.exportBackup(sharePositionOrigin: _origemCompartilhar());
      _feedback('Backup gerado. Escolha onde salvar ou enviar.');
    } on StorageException catch (error) {
      _feedback(error.message, erro: true);
    } catch (error) {
      debugPrint('Erro ao exportar na tela: $error');
      _feedback('Não foi possível exportar o backup.', erro: true);
    }
  }

  Future<void> _import() async {
    try {
      final configuracoesProvider = context.read<ConfiguracoesProvider>();
      final regulagensProvider = context.read<RegulagensProvider>();
      final ok = await _confirm(
        'Importar backup?',
        'Isso irá substituir todos os dados atuais. Continuar?',
      );
      if (!ok) return;
      final importado = await _storage.importBackup();
      if (!importado) return;
      if (!mounted) return;
      await configuracoesProvider.load();
      await regulagensProvider.load();
      _syncFromProvider();
      _feedback('Backup importado com sucesso.');
    } on StorageException catch (error) {
      _feedback(error.message, erro: true);
    } catch (error) {
      debugPrint('Erro ao importar na tela: $error');
      _feedback('Não foi possível importar o backup.', erro: true);
    }
  }

  Future<void> _clearAll() async {
    try {
      final configuracoesProvider = context.read<ConfiguracoesProvider>();
      final regulagensProvider = context.read<RegulagensProvider>();
      final first = await _confirm(
          'Apagar dados?', 'Essa ação remove regulagens e configurações.');
      if (!first) return;
      final second =
          await _confirm('Confirmar exclusão', 'Não há desfazer. Apagar tudo?');
      if (!second) return;
      await _storage.clearAll();
      if (!mounted) return;
      await configuracoesProvider.load();
      await regulagensProvider.load();
      _syncFromProvider();
      _feedback('Todos os dados foram apagados.');
    } on StorageException catch (error) {
      _feedback(error.message, erro: true);
    } catch (error) {
      debugPrint('Erro ao apagar tudo: $error');
      _feedback('Não foi possível apagar os dados.', erro: true);
    }
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    return result ?? false;
  }

  double _parse(String text, double fallback) {
    return double.tryParse(text.replaceAll(',', '.')) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<ConfiguracoesProvider>().configuracoes.tema;
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 360;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const _SectionTitle('Aparência'),
              _TemaSelector(value: tema, onChanged: _saveTema),
              const _SectionTitle('Perfil'),
              _perfilFields(wide),
              const _SectionTitle('Limites de Regulagem'),
              _limitesFields(wide),
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: 'Salvar', onPressed: _save),
              const _SectionTitle('Dados e Backup'),
              _backupTiles(wide),
              const _SectionTitle('Sobre'),
              const _AboutCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _perfilFields(bool wide) {
    final nome = _ConfigTextField(
      controller: _nome,
      focusNode: _nomeFocus,
      label: 'Nome do Consultor',
      expand: !wide,
    );
    final empresa = _ConfigTextField(
      controller: _empresa,
      focusNode: _empresaFocus,
      label: 'Nome da Empresa',
      expand: !wide,
    );
    if (!wide) {
      return Column(children: [nome, empresa]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: nome),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: empresa),
      ],
    );
  }

  Widget _limitesFields(bool wide) {
    final desgaste = _ConfigTextField(
      controller: _desgaste,
      focusNode: _desgasteFocus,
      label: 'Limite desgaste (%)',
      helper: 'Acima disso o bico fica Desgaste. Salva sozinho.',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      expand: !wide,
      onChanged: _onLimiteChanged,
    );
    final irregular = _ConfigTextField(
      controller: _irregular,
      focusNode: _irregularFocus,
      label: 'Limite entupido (%)',
      helper: 'Abaixo disso o bico fica Entupido. Salva sozinho.',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      expand: !wide,
      onChanged: _onLimiteChanged,
    );
    final tolMin = _ConfigTextField(
      controller: _tolMin,
      focusNode: _tolMinFocus,
      label: 'Tolerância Mínima (%)',
      helper: 'Início da zona aceitável.',
      keyboardType: TextInputType.number,
      expand: !wide,
    );
    final tolMax = _ConfigTextField(
      controller: _tolMax,
      focusNode: _tolMaxFocus,
      label: 'Tolerância Máxima (%)',
      helper: 'Fim da zona aceitável.',
      keyboardType: TextInputType.number,
      expand: !wide,
    );
    if (!wide) {
      return Column(children: [irregular, desgaste, tolMin, tolMax]);
    }
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: irregular),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: desgaste),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: tolMin),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: tolMax),
          ],
        ),
      ],
    );
  }

  Widget _backupTiles(bool wide) {
    final tiles = [
      _ActionTile(
          icon: Icons.ios_share, title: 'Exportar Dados', onTap: _export),
      _ActionTile(
          icon: Icons.file_open, title: 'Importar Backup', onTap: _import),
      _ActionTile(
        icon: Icons.delete_forever,
        title: 'Apagar Todos os Dados',
        onTap: _clearAll,
        danger: true,
      ),
    ];
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(child: tiles[i]),
          ],
        ],
      );
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final tile in tiles)
          SizedBox(
            width: 160,
            child: tile,
          ),
      ],
    );
  }
}

class _TemaSelector extends StatelessWidget {
  const _TemaSelector({required this.value, required this.onChanged});

  final TemaApp value;
  final ValueChanged<TemaApp> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<TemaApp>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: TemaApp.system, label: Text('Sistema')),
          ButtonSegment(value: TemaApp.light, label: Text('Claro')),
          ButtonSegment(value: TemaApp.dark, label: Text('Escuro')),
        ],
        selected: {value},
        onSelectionChanged: (selected) => onChanged(selected.first),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}

class _ConfigTextField extends StatelessWidget {
  const _ConfigTextField({
    required this.controller,
    required this.label,
    this.focusNode,
    this.helper,
    this.keyboardType,
    this.expand = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String? helper;
  final TextInputType? keyboardType;
  final bool expand;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 2,
      ),
      onChanged: onChanged == null ? null : (_) => onChanged!(),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: expand ? SizedBox(width: double.infinity, child: field) : field,
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.primary;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: danger ? color : null,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('${AppConstants.appName} v${AppConstants.appVersion}'),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Calculadora de regulagem para grandes culturas',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Dados armazenados localmente neste dispositivo',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
