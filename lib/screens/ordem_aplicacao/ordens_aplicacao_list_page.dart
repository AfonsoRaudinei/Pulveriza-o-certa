import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/ordem_aplicacao/ordens.dart';
import '../../providers/ordens_aplicacao_provider.dart';
import '../../theme.dart';
import 'nova_ordem_aplicacao_page.dart';

class OrdensAplicacaoListPage extends StatefulWidget {
  const OrdensAplicacaoListPage({super.key});

  @override
  State<OrdensAplicacaoListPage> createState() =>
      _OrdensAplicacaoListPageState();
}

class _OrdensAplicacaoListPageState extends State<OrdensAplicacaoListPage> {
  @override
  Widget build(BuildContext context) {
    final ordens = context.watch<OrdensAplicacaoProvider>().ordens;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordens de Aplicação'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _abrir(null),
          ),
        ],
      ),
      body: ordens.isEmpty
          ? const _Empty()
          : RefreshIndicator(
              onRefresh: context.read<OrdensAplicacaoProvider>().load,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: ordens.length,
                itemBuilder: (context, index) {
                  final ordem = ordens[index];
                  return _OrdemCard(
                    ordem: ordem,
                    onTap: () => _abrir(ordem),
                    onDelete: () => _delete(ordem),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrir(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _abrir(OrdemAplicacao? ordem) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => NovaOrdemAplicacaoPage(ordem: ordem)),
    );
  }

  Future<void> _delete(OrdemAplicacao ordem) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Excluir ordem?'),
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
    if (confirmed != true || !mounted) return;
    final provider = context.read<OrdensAplicacaoProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await provider.delete(ordem.id);
    if (!mounted) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('Ordem excluída'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => provider.save(ordem),
          ),
        ),
      );
  }
}

class _OrdemCard extends StatelessWidget {
  const _OrdemCard({
    required this.ordem,
    required this.onTap,
    required this.onDelete,
  });

  final OrdemAplicacao ordem;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final data = DateFormat("dd MMM yyyy", 'pt_BR').format(ordem.atualizadoEm);
    return Slidable(
      key: ValueKey(ordem.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            onPressed: (_) => onTap(),
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
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ordem.clienteNome.isEmpty ? 'Sem cliente' : ordem.clienteNome,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${ordem.fazendaNome}${ordem.talhaoNome.isNotEmpty ? ' • ${ordem.talhaoNome}' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    Chip(label: Text(ordem.execucao.status.label)),
                    Chip(label: Text(data)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${ordem.produtos.length} produtos — ${ordem.areaAplicar.toStringAsFixed(2)} ha • ${ordem.alvo?.label ?? 'sem alvo'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.huge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.agriculture_outlined,
              size: 56,
              color: AppThemeColors.of(context).textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nenhuma ordem ainda. Crie a primeira!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
