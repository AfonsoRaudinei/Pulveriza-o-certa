import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/formatters/digitos_maximo_formatter.dart';
import '../../models/configuracoes.dart';
import '../../models/marca_pdf.dart';
import '../../providers/configuracoes_provider.dart';
import '../../services/marca_logo_service.dart';
import '../../providers/regulagens_provider.dart';
import '../../services/storage_service.dart';
import '../../theme.dart';
import '../../core/marca_cabecalho_laudo.dart';
import '../../widgets/app_button.dart';
import 'widgets/seletor_cor_marca_dialog.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final _nome = TextEditingController();
  final _empresa = TextEditingController();
  final _crea = TextEditingController();
  final _nomeFocus = FocusNode();
  final _empresaFocus = FocusNode();
  final _creaFocus = FocusNode();
  final _storage = StorageService();
  final _marcaLogo = MarcaLogoService();
  final _imagePicker = ImagePicker();
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
    _configProvider?.removeListener(_onConfigChanged);
    _nomeFocus.dispose();
    _empresaFocus.dispose();
    _creaFocus.dispose();
    _nome.dispose();
    _empresa.dispose();
    _crea.dispose();
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
    _syncField(_crea, _creaFocus, config.registroProfissional);
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
          registroProfissional: _crea.text.trim(),
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
              _marcaLaudoSection(),
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
      textoLivre: true,
      capitalization: TextCapitalization.words,
    );
    final empresa = _ConfigTextField(
      controller: _empresa,
      focusNode: _empresaFocus,
      label: 'Nome da Empresa',
      expand: !wide,
      textoLivre: true,
      capitalization: TextCapitalization.words,
    );
    final crea = _ConfigTextField(
      controller: _crea,
      focusNode: _creaFocus,
      label: 'Registro profissional (CREA)',
      expand: !wide,
      textoLivre: true,
    );
    if (!wide) {
      return Column(children: [nome, empresa, crea]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: nome),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: empresa),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        crea,
      ],
    );
  }

  Widget _marcaLaudoSection() {
    final config = context.watch<ConfiguracoesProvider>().configuracoes;
    final temLogo = config.marcaLogoArquivo.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Marca no laudo PDF',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Consultor e empresa aparecem no cabeçalho. O ${AppConstants.nomeMarcaRodapePdf} aparece no rodapé.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _LogoMarcaPreview(
                marcaLogoArquivo: config.marcaLogoArquivo,
                marcaLogoService: _marcaLogo,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _escolherLogoMarca,
                      icon: const Icon(Icons.image_outlined, size: 20),
                      label: Text(temLogo ? 'Trocar logo' : 'Escolher logo'),
                    ),
                    if (temLogo) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: _removerLogoMarca,
                        child: const Text('Remover logo'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Cor do cabeçalho',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          _CorMarcaSelector(
            config: config,
            onPreset: _salvarCorMarca,
            onPersonalizada: _abrirCorPersonalizada,
          ),
          const SizedBox(height: AppSpacing.md),
          _PreviewCabecalhoLaudo(
            config: config,
            marcaLogoService: _marcaLogo,
          ),
        ],
      ),
    );
  }

  Future<void> _abrirCorPersonalizada() async {
    try {
      final provider = context.read<ConfiguracoesProvider>();
      final atual = provider.configuracoes;
      final picked = await showSeletorCorMarcaDialog(
        context,
        initial: corMarcaCabecalhoLaudo(atual),
      );
      if (picked == null) return;
      await provider.save(
        atual.copyWith(
          corMarcaPdf: CorMarcaPdf.personalizada,
          corMarcaPersonalizadaArgb: picked.toARGB32(),
        ),
      );
    } on StorageException catch (error) {
      _feedback(error.message, erro: true);
    }
  }

  Future<void> _escolherLogoMarca() async {
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final arquivo = await _marcaLogo.salvarLogo(File(picked.path));
      final provider = context.read<ConfiguracoesProvider>();
      await provider.save(
        provider.configuracoes.copyWith(marcaLogoArquivo: arquivo),
      );
      _feedback('Logo salvo para o laudo.');
    } on StateError catch (error) {
      _feedback(error.message, erro: true);
    } on StorageException catch (error) {
      _feedback(error.message, erro: true);
    } catch (error) {
      debugPrint('Erro ao salvar logo: $error');
      _feedback('Não foi possível salvar o logo.', erro: true);
    }
  }

  Future<void> _removerLogoMarca() async {
    try {
      await _marcaLogo.removerLogo();
      final provider = context.read<ConfiguracoesProvider>();
      await provider.save(
        provider.configuracoes.copyWith(marcaLogoArquivo: ''),
      );
      _feedback('Logo removido.');
    } on StorageException catch (error) {
      _feedback(error.message, erro: true);
    } catch (error) {
      debugPrint('Erro ao remover logo: $error');
      _feedback('Não foi possível remover o logo.', erro: true);
    }
  }

  Future<void> _salvarCorMarca(CorMarcaPdf cor) async {
    try {
      final provider = context.read<ConfiguracoesProvider>();
      if (provider.configuracoes.corMarcaPdf == cor) return;
      await provider.save(
        provider.configuracoes.copyWith(
          corMarcaPdf: cor,
          limparCorPersonalizada: true,
        ),
      );
    } on StorageException catch (error) {
      _feedback(error.message, erro: true);
    } catch (error) {
      debugPrint('Erro ao salvar cor da marca: $error');
    }
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

class _PreviewCabecalhoLaudo extends StatelessWidget {
  const _PreviewCabecalhoLaudo({
    required this.config,
    required this.marcaLogoService,
  });

  final Configuracoes config;
  final MarcaLogoService marcaLogoService;

  @override
  Widget build(BuildContext context) {
    final fundo = corMarcaCabecalhoLaudo(config);
    final texto = textoSobreCorMarcaLaudo(fundo);
    final marca = config.textoMarcaCabecalho();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pré-visualização do cabeçalho',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: fundo,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              _LogoMarcaPreview(
                marcaLogoArquivo: config.marcaLogoArquivo,
                marcaLogoService: marcaLogoService,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  marca,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: texto,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
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
    this.numerico = false,
    this.textoLivre = false,
    this.capitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String? helper;
  final TextInputType? keyboardType;
  final bool expand;
  final VoidCallback? onChanged;
  final bool numerico;
  final bool textoLivre;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      autocorrect: textoLivre,
      enableSuggestions: textoLivre,
      spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
      inputFormatters: numerico
          ? [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              const DigitosMaximoFormatter(),
            ]
          : null,
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

class _LogoMarcaPreview extends StatelessWidget {
  const _LogoMarcaPreview({
    required this.marcaLogoArquivo,
    required this.marcaLogoService,
  });

  final String marcaLogoArquivo;
  final MarcaLogoService marcaLogoService;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return FutureBuilder<File?>(
      future: marcaLogoService.arquivoExistente(marcaLogoArquivo),
      builder: (context, snapshot) {
        final file = snapshot.data;
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: file != null
              ? Image.file(file, fit: BoxFit.contain)
              : Icon(Icons.business_outlined, color: colors.textTertiary),
        );
      },
    );
  }
}

class _CorMarcaSelector extends StatelessWidget {
  const _CorMarcaSelector({
    required this.config,
    required this.onPreset,
    required this.onPersonalizada,
  });

  final Configuracoes config;
  final ValueChanged<CorMarcaPdf> onPreset;
  final VoidCallback onPersonalizada;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        for (final cor in CorMarcaPdf.values)
          _CorMarcaOption(
            cor: cor,
            swatch: cor == CorMarcaPdf.personalizada
                ? corMarcaCabecalhoLaudo(config)
                : cor.color,
            selected: cor == config.corMarcaPdf,
            onTap: () {
              if (cor == CorMarcaPdf.personalizada) {
                onPersonalizada();
              } else {
                onPreset(cor);
              }
            },
          ),
      ],
    );
  }
}

class _CorMarcaOption extends StatelessWidget {
  const _CorMarcaOption({
    required this.cor,
    required this.swatch,
    required this.selected,
    required this.onTap,
  });

  final CorMarcaPdf cor;
  final Color swatch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Semantics(
      label: 'Cor ${cor.label}',
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: swatch,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? colors.textPrimary : colors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                cor.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : null,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
