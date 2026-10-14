import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/double_extension.dart';
import '../../domain/calculos/calc_custo_manejo.dart';
import '../../models/custo_manejo.dart';
import '../../providers/custos_manejo_provider.dart';
import '../../theme.dart';
import 'custo_manejo_editor_screen.dart';

class CustosManejoListScreen extends StatelessWidget {
  const CustosManejoListScreen({super.key});

  Future<void> _abrirEditor(BuildContext context, {CustoManejo? custo}) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CustoManejoEditorScreen(custo: custo),
      ),
    );
  }

  Future<void> _confirmarExclusao(
    BuildContext context,
    CustoManejo custo,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir custo de manejo?'),
        content: Text('“${custo.nome}” será removido deste aparelho.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await context.read<CustosManejoProvider>().delete(custo.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível excluir.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final custos = context.watch<CustosManejoProvider>().custos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de Manejo'),
        actions: [
          IconButton(
            tooltip: 'Novo custo',
            onPressed: () => _abrirEditor(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: custos.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.huge),
                child: Text(
                  'Nenhum custo de manejo salvo. Toque em + para montar '
                  'produtos por aplicação.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: custos.length,
              itemBuilder: (context, index) {
                final custo = custos[index];
                final total = calcularTotalManejo(custo);
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ListTile(
                    title: Text(custo.nome),
                    subtitle: Text(
                      '${custo.aplicacoes.length} aplicações · '
                      '${total.toMoeda()}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: AppColors.danger,
                      onPressed: () => _confirmarExclusao(context, custo),
                    ),
                    onTap: () => _abrirEditor(context, custo: custo),
                  ),
                );
              },
            ),
    );
  }
}
