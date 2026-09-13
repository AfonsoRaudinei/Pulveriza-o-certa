import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/regulagem.dart';
import '../../providers/regulagens_provider.dart';
import '../../routes.dart';
import '../../services/feedback_whatsapp.dart';
import '../../theme.dart';
import '../regulagem/regulagem_screen.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  bool _searching = false;
  final _query = TextEditingController();
  ScaffoldMessengerState? _messenger;

  static const _fabBottomPadding = 80.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _messenger?.clearSnackBars();
    _query.dispose();
    super.dispose();
  }

  List<Regulagem> _filtrar(List<Regulagem> regulagens) {
    final text = _query.text.trim().toLowerCase();
    if (text.isEmpty) return regulagens;
    return regulagens.where((item) {
      return item.produtor.toLowerCase().contains(text) ||
          item.fazenda.toLowerCase().contains(text);
    }).toList();
  }

  void _abrirEdicao(Regulagem regulagem) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => RegulagemScreen(regulagem: regulagem),
      ),
    );
  }

  void _mostrarFolhaAcoes() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Nova Regulagem'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushNamed(context, Routes.regulagem);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configuração'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushNamed(context, Routes.configuracoes);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('Feedback'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final ok = await abrirFeedbackWhatsApp();
                if (!ok && mounted) {
                  mostrarFeedbackFalhouSnackBar(context);
                }
              },
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text(
                'Cancelar',
                textAlign: TextAlign.center,
              ),
              onTap: () => Navigator.pop(sheetContext),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmarExclusao() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Excluir regulagem?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _delete(Regulagem regulagem) async {
    final confirmed = await _confirmarExclusao();
    if (!confirmed || !mounted) return;

    final provider = context.read<RegulagensProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.delete(regulagem.id);
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Text('Regulagem excluída'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () async {
                try {
                  await provider.save(regulagem);
                } catch (error) {
                  debugPrint('Erro ao desfazer exclusão: $error');
                  messenger
                    ..clearSnackBars()
                    ..showSnackBar(
                      const SnackBar(
                        content:
                            Text('Não foi possível restaurar a regulagem.'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                }
              },
            ),
          ),
        );
    } catch (error) {
      debugPrint('Erro ao deletar no histórico: $error');
      await provider.load();
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não foi possível excluir a regulagem.'),
            backgroundColor: AppColors.danger,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final regulagens = _filtrar(context.watch<RegulagensProvider>().regulagens);
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _query,
                autofocus: true,
                decoration: const InputDecoration(
                    hintText: 'Buscar produtor ou fazenda'),
                onChanged: (_) => setState(() {}),
              )
            : const Text('Regulagens'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _searching = !_searching),
            icon: Icon(_searching ? Icons.close : Icons.search),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Ações',
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        onPressed: _mostrarFolhaAcoes,
        child: const Icon(Icons.add),
      ),
      body: regulagens.isEmpty
          ? const _HistoricoEmptyState()
          : RefreshIndicator(
              onRefresh: context.read<RegulagensProvider>().load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg + _fabBottomPadding,
                ),
                itemCount: regulagens.length,
                itemBuilder: (context, index) {
                  final regulagem = regulagens[index];
                  return _SlidableRegulagemCard(
                    regulagem: regulagem,
                    onEdit: () => _abrirEdicao(regulagem),
                    onDelete: () => _delete(regulagem),
                  );
                },
              ),
            ),
    );
  }
}

class _SlidableRegulagemCard extends StatelessWidget {
  const _SlidableRegulagemCard({
    required this.regulagem,
    required this.onEdit,
    required this.onDelete,
  });

  final Regulagem regulagem;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(regulagem.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: AppColors.info,
            foregroundColor: AppColors.surface,
            icon: Icons.edit,
            label: 'Editar',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.surface,
            icon: Icons.delete,
            label: 'Excluir',
          ),
        ],
      ),
      child: _RegulagemCard(
        regulagem: regulagem,
        onTap: onEdit,
      ),
    );
  }
}

class _RegulagemCard extends StatelessWidget {
  const _RegulagemCard({
    required this.regulagem,
    required this.onTap,
  });

  final Regulagem regulagem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = DateFormat("dd MMM yyyy 'às' HH:mm", 'pt_BR')
        .format(regulagem.dataRegulagem);
    final resumo = _resumoTecnico(regulagem);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(regulagem.produtor,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${regulagem.fazenda}${regulagem.talhao?.isNotEmpty == true ? ' • ${regulagem.talhao}' : ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  Chip(label: Text(_tipoLabel(regulagem.tipoOperacao))),
                  Chip(label: Text(data)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                resumo,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _tipoLabel(TipoOperacao tipo) {
    return tipo == TipoOperacao.pulverizador ? 'Pulverizador' : 'Plantadeira';
  }

  String _resumoTecnico(Regulagem regulagem) {
    if (regulagem.tipoOperacao == TipoOperacao.plantadeira) {
      final largura = regulagem.larguraUtil ?? 0;
      final rendimento = regulagem.rendimento ?? 0;
      return 'Largura útil ${largura.toStringAsFixed(2)} m — rendimento ${rendimento.toStringAsFixed(2)} ha/h';
    }

    final desgaste = regulagem.medicoes
        .where((item) => item.status == StatusPonta.desgaste)
        .length;
    final irregular = regulagem.medicoes
        .where((item) => item.status == StatusPonta.irregular)
        .length;
    return '${regulagem.numeroPontas} pontas — $desgaste com desgaste, $irregular irregulares';
  }
}

class _HistoricoEmptyState extends StatelessWidget {
  const _HistoricoEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.huge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt_outlined,
                size: 56, color: AppThemeColors.of(context).textTertiary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nenhuma regulagem ainda. Toque no + para criar a primeira.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
