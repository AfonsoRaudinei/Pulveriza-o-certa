import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/regulagem.dart';
import '../../providers/regulagens_provider.dart';
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

  @override
  void dispose() {
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

  Future<void> _delete(Regulagem regulagem) async {
    final provider = context.read<RegulagensProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.delete(regulagem.id);
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
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
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Não foi possível restaurar a regulagem.'),
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
      // Recarrega para o item excluído visualmente reaparecer na lista.
      await provider.load();
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
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
      body: regulagens.isEmpty
          ? const _HistoricoEmptyState()
          : RefreshIndicator(
              onRefresh: context.read<RegulagensProvider>().load,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: regulagens.length,
                itemBuilder: (context, index) {
                  final regulagem = regulagens[index];
                  return _DismissibleRegulagemCard(
                    regulagem: regulagem,
                    onDelete: () => _delete(regulagem),
                  );
                },
              ),
            ),
    );
  }
}

class _DismissibleRegulagemCard extends StatelessWidget {
  const _DismissibleRegulagemCard({
    required this.regulagem,
    required this.onDelete,
  });

  final Regulagem regulagem;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(regulagem.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        color: AppColors.danger,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: _RegulagemCard(regulagem: regulagem),
    );
  }
}

class _RegulagemCard extends StatelessWidget {
  const _RegulagemCard({required this.regulagem});

  final Regulagem regulagem;

  @override
  Widget build(BuildContext context) {
    final data = DateFormat("dd MMM yyyy 'às' HH:mm", 'pt_BR')
        .format(regulagem.dataRegulagem);
    final resumo = _resumoTecnico(regulagem);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) =>
                  RegulagemScreen(regulagem: regulagem, readonly: true),
            ),
          );
        },
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
              'Nenhuma regulagem ainda. Crie a primeira!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
