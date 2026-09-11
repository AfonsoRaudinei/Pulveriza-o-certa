import 'package:flutter/material.dart';

import '../../../domain/ordem_aplicacao/calc_totais_unidade.dart';
import '../../../theme.dart';

class TotaisChips extends StatelessWidget {
  const TotaisChips({super.key, required this.totais});

  final List<TotalUnidade> totais;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    if (totais.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < totais.length; i++) ...[
            if (i > 0) Container(width: 1, height: 36, color: colors.border),
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.science_outlined, size: 16, color: colors.info),
                  Text(
                    _format(totais[i].quantidade),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.info,
                    ),
                  ),
                  Text(
                    totais[i].unidade.quantidadeLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _format(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}
