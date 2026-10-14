import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/double_extension.dart';
import '../../domain/calculos/calc_custo_manejo.dart';
import '../../providers/custos_manejo_provider.dart';
import '../../theme.dart';

/// Folha para escolher um custo salvo e copiar o total para Manejo (R\$).
Future<double?> mostrarSelecaoCustoManejo(BuildContext context) {
  return showModalBottomSheet<double>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (sheetContext) {
      final custos = sheetContext.watch<CustosManejoProvider>().custos;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                'Usar custo de manejo salvo',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            if (custos.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Nenhum custo salvo. Abra a Calculadora de Manejo no menu +.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.45,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: custos.length,
                  itemBuilder: (context, index) {
                    final custo = custos[index];
                    final total = calcularTotalManejo(custo);
                    return ListTile(
                      title: Text(custo.nome),
                      subtitle: Text(total.toMoeda()),
                      onTap: () => Navigator.pop(sheetContext, total),
                    );
                  },
                ),
              ),
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
      );
    },
  );
}
