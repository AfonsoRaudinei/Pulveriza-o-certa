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
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _nome.dispose();
    _empresa.dispose();
    _desgaste.dispose();
    _irregular.dispose();
    _tolMin.dispose();
    _tolMax.dispose();
    super.dispose();
  }

  void _load() {
    final config = context.read<ConfiguracoesProvider>().configuracoes;
    _nome.text = config.nomeConsultor;
    _empresa.text = config.empresaNome;
    _desgaste.text = config.limiteDesgaste.toStringAsFixed(2);
    _irregular.text = config.limiteIrregular.toStringAsFixed(2);
    _tolMin.text = config.toleranciaMin.toStringAsFixed(2);
    _tolMax.text = config.toleranciaMax.toStringAsFixed(2);
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
      final config = Configuracoes(
        nomeConsultor: _nome.text.trim(),
        empresaNome: _empresa.text.trim(),
        limiteDesgaste: _parse(_desgaste.text, 105),
        limiteIrregular: _parse(_irregular.text, 100),
        toleranciaMin: _parse(_tolMin.text, 100.5),
        toleranciaMax: _parse(_tolMax.text, 104.99),
      );
      await context.read<ConfiguracoesProvider>().save(config);
      _feedback('Configurações salvas.');
    } on StorageException catch (error) {
      _feedback(error.message, erro: true);
    } catch (error) {
      debugPrint('Erro ao salvar configurações: $error');
      _feedback('Não foi possível salvar as configurações.', erro: true);
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
      _load();
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
      _load();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const _SectionTitle('Perfil'),
          _ConfigTextField(controller: _nome, label: 'Nome do Consultor'),
          _ConfigTextField(controller: _empresa, label: 'Nome da Empresa'),
          const _SectionTitle('Limites de Regulagem'),
          _ConfigTextField(
            controller: _desgaste,
            label: 'Limite Desgaste (%)',
            helper: 'Acima disso, o bico está desgastado.',
            keyboardType: TextInputType.number,
          ),
          _ConfigTextField(
            controller: _irregular,
            label: 'Limite Irregular (%)',
            helper: 'Abaixo disso, há risco de entupimento ou vazão baixa.',
            keyboardType: TextInputType.number,
          ),
          _ConfigTextField(
            controller: _tolMin,
            label: 'Tolerância Mínima (%)',
            helper: 'Início da zona aceitável.',
            keyboardType: TextInputType.number,
          ),
          _ConfigTextField(
            controller: _tolMax,
            label: 'Tolerância Máxima (%)',
            helper: 'Fim da zona aceitável.',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: 'Salvar', onPressed: _save),
          const _SectionTitle('Dados e Backup'),
          _ActionTile(
              icon: Icons.ios_share, title: 'Exportar Dados', onTap: _export),
          _ActionTile(
              icon: Icons.file_open, title: 'Importar Backup', onTap: _import),
          _ActionTile(
              icon: Icons.delete_forever,
              title: 'Apagar Todos os Dados',
              onTap: _clearAll),
          const _SectionTitle('Sobre'),
          const _AboutCard(),
        ],
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
    this.helper,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? helper;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, helperText: helper),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
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
