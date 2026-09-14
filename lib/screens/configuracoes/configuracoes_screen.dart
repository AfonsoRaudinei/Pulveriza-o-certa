import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/legal_content.dart';
import '../../models/configuracoes.dart';
import '../../models/lembretes_config.dart';
import '../../models/perfil_relatorio.dart';
import '../../providers/configuracoes_provider.dart';
import '../../providers/regulagens_provider.dart';
import '../../services/perfil_imagem_service.dart';
import '../../services/storage_service.dart';
import '../../theme.dart';
import 'legal_text_screen.dart';
import 'widgets/imagem_perfil_picker.dart';
import 'widgets/relatorio_header_preview.dart';
import 'widgets/settings_accordion.dart';
import 'widgets/settings_card.dart';
import 'widgets/settings_section_title.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final _nome = TextEditingController();
  final _empresa = TextEditingController();
  final _intervaloCustom = TextEditingController();
  final _nomeFocus = FocusNode();
  final _empresaFocus = FocusNode();
  final _intervaloFocus = FocusNode();
  final _storage = StorageService();
  final _imagemService = PerfilImagemService();
  final _picker = ImagePicker();
  Timer? _perfilDebounce;
  ConfiguracoesProvider? _configProvider;
  PerfilRelatorio _perfilLocal = const PerfilRelatorio();

  static const _faqItems = [
    FaqItem(
      pergunta: 'Como faço uma nova regulagem?',
      resposta:
          'Na tela inicial, toque no botão + e preencha os dados do pulverizador. '
          'Meça cada bico e o app calcula automaticamente o status e a economia.',
    ),
    FaqItem(
      pergunta: 'Onde ficam meus dados?',
      resposta:
          'Tudo fica salvo localmente no seu iPhone. Nenhuma informação é enviada '
          'para servidores externos.',
    ),
    FaqItem(
      pergunta: 'Como exportar um backup?',
      resposta:
          'Em Configurações → Dados e Backup → Exportar Dados. Escolha onde salvar '
          '(iCloud Drive, Arquivos, AirDrop etc.).',
    ),
    FaqItem(
      pergunta: 'O que significam Entupido, Ideal e Desgaste?',
      resposta:
          'São classificações baseadas no percentual de vazão de cada bico em relação '
          'ao ideal. Os limites podem ser ajustados na tela Nova Regulagem.',
    ),
    FaqItem(
      pergunta: 'Posso personalizar o PDF?',
      resposta:
          'Sim. Em Perfil & Relatório, adicione logo, assinatura e dados da empresa '
          'que aparecerão no laudo gerado.',
    ),
    FaqItem(
      pergunta: 'Como funcionam os lembretes?',
      resposta:
          'Você pode ser lembrado por tempo (a cada X dias) ou por uso (a cada X '
          'regulagens salvas). Ative em Notificações e Lembretes.',
    ),
  ];

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
    _perfilDebounce?.cancel();
    _configProvider?.removeListener(_onConfigChanged);
    _nomeFocus.dispose();
    _empresaFocus.dispose();
    _intervaloFocus.dispose();
    _nome.dispose();
    _empresa.dispose();
    _intervaloCustom.dispose();
    super.dispose();
  }

  void _onConfigChanged() {
    if (!mounted) return;
    _syncFromProvider();
  }

  void _syncFromProvider() {
    final config = _configProvider?.configuracoes ??
        context.read<ConfiguracoesProvider>().configuracoes;
    _syncField(_nome, _nomeFocus, config.perfilRelatorio.nomeConsultor);
    _syncField(_empresa, _empresaFocus, config.perfilRelatorio.empresaNome);
    _perfilLocal = config.perfilRelatorio;

    final lembretes = config.lembretes;
    if (lembretes.intervaloPersonalizado) {
      final valor = lembretes.criterio == CriterioLembrete.tempo
          ? lembretes.intervaloDias.toString()
          : lembretes.intervaloRegulagens.toString();
      _syncField(_intervaloCustom, _intervaloFocus, valor);
    }
    setState(() {});
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

  void _onPerfilChanged() {
    _perfilDebounce?.cancel();
    _perfilDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_persistPerfil());
    });
  }

  Future<void> _persistPerfil() async {
    if (!mounted) return;
    try {
      await context.read<ConfiguracoesProvider>().savePerfilRelatorio(
            _perfilLocal.copyWith(
              nomeConsultor: _nome.text.trim(),
              empresaNome: _empresa.text.trim(),
            ),
          );
    } on StorageException catch (error) {
      _feedback(error.message, erro: true);
    } catch (error) {
      debugPrint('Erro ao salvar perfil: $error');
    }
  }

  Future<void> _pickImagem(TipoImagemPerfil tipo, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      final path = await _imagemService.salvarImagem(File(picked.path), tipo);
      if (!mounted) return;
      final provider = context.read<ConfiguracoesProvider>();
      final atual = provider.configuracoes.perfilRelatorio;

      if (tipo == TipoImagemPerfil.logo) {
        await _imagemService.removerImagem(atual.logoPath);
        _perfilLocal = atual.copyWith(logoPath: path);
      } else {
        await _imagemService.removerImagem(atual.assinaturaPath);
        _perfilLocal = atual.copyWith(assinaturaPath: path);
      }

      await provider.savePerfilRelatorio(_perfilLocal);
      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('Erro ao selecionar imagem: $error');
      _feedback('Não foi possível adicionar a imagem.', erro: true);
    }
  }

  Future<void> _removerImagem(TipoImagemPerfil tipo) async {
    final provider = context.read<ConfiguracoesProvider>();
    final atual = provider.configuracoes.perfilRelatorio;
    if (tipo == TipoImagemPerfil.logo) {
      await _imagemService.removerImagem(atual.logoPath);
      _perfilLocal = atual.copyWith(removerLogo: true);
    } else {
      await _imagemService.removerImagem(atual.assinaturaPath);
      _perfilLocal = atual.copyWith(removerAssinatura: true);
    }
    await provider.savePerfilRelatorio(_perfilLocal);
    if (mounted) setState(() {});
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

  Rect? _origemCompartilhar() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
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
      if (!mounted) return;
      await context.read<ConfiguracoesProvider>().registrarUltimoBackup();
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

  Future<void> _toggleRevisao(bool value) async {
    final granted = await context
        .read<ConfiguracoesProvider>()
        .ativarLembretesRevisao(value);
    if (!value || granted) return;
    if (!mounted) return;
    await _mostrarAvisoPermissao();
  }

  Future<void> _toggleBackupLembrete(bool value) async {
    final granted =
        await context.read<ConfiguracoesProvider>().ativarLembreteBackup(value);
    if (!value || granted) return;
    if (!mounted) return;
    await _mostrarAvisoPermissao();
  }

  Future<void> _mostrarAvisoPermissao() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notificações desativadas'),
        content: const Text(
          'Ative notificações nos Ajustes do iPhone para receber lembretes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.parse('app-settings:');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            child: const Text('Abrir Ajustes'),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirWhatsApp() async {
    final mensagem = Uri.encodeComponent(
      'Olá, preciso de ajuda com o app ${AppConstants.appName}',
    );
    final uri = Uri.parse(
      '${AppConstants.feedbackWhatsAppUrl}?text=$mensagem',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _feedback('Não foi possível abrir o WhatsApp.', erro: true);
    }
  }

  Future<void> _atualizarLembretes(LembretesConfig lembretes) async {
    try {
      await context.read<ConfiguracoesProvider>().saveLembretes(lembretes);
    } on StorageException catch (error) {
      _feedback(error.message, erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfiguracoesProvider>().configuracoes;
    final lembretes = config.lembretes;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 360;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const SettingsSectionTitle('Aparência'),
              SettingsCard(
                  child: _TemaSelector(
                value: config.tema,
                onChanged: _saveTema,
              )),
              const SettingsSectionTitle('Perfil & Relatório'),
              SettingsCard(child: _perfilSection(wide)),
              const SettingsSectionTitle('Notificações e Lembretes'),
              SettingsCard(child: _notificacoesSection(lembretes)),
              const SettingsSectionTitle('Dados e Backup'),
              SettingsCard(child: _backupSection(config, wide)),
              const SettingsSectionTitle('Ajuda e Suporte'),
              const SettingsAccordion(items: _faqItems),
              const SizedBox(height: AppSpacing.md),
              SettingsCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.chat, color: AppColors.success),
                  title: const Text('Falar no WhatsApp'),
                  subtitle: const Text(AppConstants.feedbackWhatsAppDisplay),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: _abrirWhatsApp,
                ),
              ),
              const SettingsSectionTitle('Privacidade e Termos'),
              SettingsCard(child: _privacidadeSection()),
              const SettingsSectionTitle('Sobre'),
              const _AboutCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _perfilSection(bool wide) {
    final perfil = _perfilLocal;
    final nome = _ConfigTextField(
      controller: _nome,
      focusNode: _nomeFocus,
      label: 'Nome do Consultor',
      expand: !wide,
      onChanged: _onPerfilChanged,
    );
    final empresa = _ConfigTextField(
      controller: _empresa,
      focusNode: _empresaFocus,
      label: 'Nome da Empresa',
      expand: !wide,
      onChanged: _onPerfilChanged,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!wide) ...[nome, empresa] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: nome),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: empresa),
            ],
          ),
        ImagemPerfilPicker(
          label: 'Logo da Empresa',
          imagePath: perfil.logoPath,
          placeholder: 'Adicionar logo',
          onPick: (s) => _pickImagem(TipoImagemPerfil.logo, s),
          onRemove: () => _removerImagem(TipoImagemPerfil.logo),
        ),
        const SizedBox(height: AppSpacing.md),
        ImagemPerfilPicker(
          label: 'Assinatura do Consultor',
          imagePath: perfil.assinaturaPath,
          placeholder: 'Adicionar assinatura',
          onPick: (s) => _pickImagem(TipoImagemPerfil.assinatura, s),
          onRemove: () => _removerImagem(TipoImagemPerfil.assinatura),
        ),
        const SizedBox(height: AppSpacing.lg),
        RelatorioHeaderPreview(
          perfil: perfil.copyWith(
            nomeConsultor: _nome.text.trim(),
            empresaNome: _empresa.text.trim(),
          ),
        ),
      ],
    );
  }

  Widget _notificacoesSection(LembretesConfig lembretes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Ativar lembretes de revisão'),
          value: lembretes.revisaoAtivo,
          onChanged: _toggleRevisao,
        ),
        if (lembretes.revisaoAtivo) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<CriterioLembrete>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: CriterioLembrete.tempo,
                  label: Text('Por tempo'),
                ),
                ButtonSegment(
                  value: CriterioLembrete.uso,
                  label: Text('Por uso'),
                ),
              ],
              selected: {lembretes.criterio},
              onSelectionChanged: (selected) {
                _atualizarLembretes(
                  lembretes.copyWith(criterio: selected.first),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (lembretes.criterio == CriterioLembrete.tempo)
            _intervaloSelector(
              label: 'A cada',
              sufixo: 'dias',
              opcoes: LembretesConfig.opcoesDias,
              valorAtual: lembretes.intervaloDias,
              personalizado: lembretes.intervaloPersonalizado,
              onChanged: (dias, personalizado) {
                _atualizarLembretes(
                  lembretes.copyWith(
                    intervaloDias: dias,
                    intervaloPersonalizado: personalizado,
                  ),
                );
              },
            )
          else
            _intervaloSelector(
              label: 'A cada',
              sufixo: 'regulagens salvas',
              opcoes: LembretesConfig.opcoesRegulagens,
              valorAtual: lembretes.intervaloRegulagens,
              personalizado: lembretes.intervaloPersonalizado,
              onChanged: (qtd, personalizado) {
                _atualizarLembretes(
                  lembretes.copyWith(
                    intervaloRegulagens: qtd,
                    intervaloPersonalizado: personalizado,
                  ),
                );
              },
            ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Você será notificado para revisar o estado dos bicos.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _intervaloSelector({
    required String label,
    required String sufixo,
    required List<int> opcoes,
    required int valorAtual,
    required bool personalizado,
    required void Function(int valor, bool personalizado) onChanged,
  }) {
    final itens = [
      ...opcoes.map((v) => DropdownMenuItem(value: v, child: Text('$v'))),
      const DropdownMenuItem(value: -1, child: Text('Personalizado')),
    ];
    final dropdownValue = personalizado ? -1 : valorAtual;

    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(width: AppSpacing.sm),
        DropdownButton<int>(
          value: opcoes.contains(valorAtual) && !personalizado
              ? valorAtual
              : dropdownValue,
          items: itens,
          onChanged: (value) {
            if (value == null) return;
            if (value == -1) {
              onChanged(valorAtual, true);
            } else {
              onChanged(value, false);
            }
          },
        ),
        if (personalizado) ...[
          SizedBox(
            width: 64,
            child: TextField(
              controller: _intervaloCustom,
              focusNode: _intervaloFocus,
              keyboardType: TextInputType.number,
              maxLength: 3,
              decoration: const InputDecoration(
                counterText: '',
                isDense: true,
              ),
              onChanged: (text) {
                final parsed = int.tryParse(text);
                if (parsed != null && parsed > 0) {
                  onChanged(parsed, true);
                }
              },
            ),
          ),
        ] else
          Text('$valorAtual', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(sufixo, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _backupSection(Configuracoes config, bool wide) {
    final ultimo = config.ultimoBackup;
    final ultimoTexto = ultimo == null
        ? 'Nenhum backup realizado ainda'
        : 'Último backup: ${DateFormat('dd/MM/yyyy \'às\' HH:mm', 'pt_BR').format(ultimo)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ultimoTexto, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.md),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Lembrar de fazer backup periodicamente'),
          subtitle: const Text('A cada 30 dias'),
          value: config.lembretes.lembreteBackupAtivo,
          onChanged: _toggleBackupLembrete,
        ),
        const SizedBox(height: AppSpacing.md),
        _backupTiles(wide),
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
        for (final tile in tiles) SizedBox(width: 160, child: tile),
      ],
    );
  }

  Widget _privacidadeSection() {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.shield_outlined,
              color: AppThemeColors.of(context).primary),
          title: const Text('Seus dados nunca saem do seu iPhone'),
          subtitle: const Text('App 100% offline e local'),
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Política de Privacidade'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LegalTextScreen(
                titulo: 'Política de Privacidade',
                paragrafos: LegalContent.privacidadeParagrafos,
              ),
            ),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Termos de Uso'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LegalTextScreen(
                titulo: 'Termos de Uso',
                paragrafos: LegalContent.termosParagrafos,
              ),
            ),
          ),
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

class _ConfigTextField extends StatelessWidget {
  const _ConfigTextField({
    required this.controller,
    required this.label,
    this.focusNode,
    this.expand = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final bool expand;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(labelText: label),
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
    return InkWell(
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
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
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
    );
  }
}
