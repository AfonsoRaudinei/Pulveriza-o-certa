import 'package:flutter/material.dart';

import '../../../theme.dart';

class MedicoesResumoCard extends StatelessWidget {
  const MedicoesResumoCard({
    super.key,
    required this.desgaste,
    required this.irregular,
    required this.tolerancia,
    required this.acimaMin,
    required this.ideal,
  });

  final int desgaste;
  final int irregular;
  final int tolerancia;
  final int acimaMin;
  final int ideal;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final cells = <Widget>[
      _StatCell(
        icon: Icons.trending_up,
        value: desgaste,
        label: 'Desgaste',
        activeColor: colors.danger,
      ),
      _StatCell(
        icon: Icons.trending_down,
        value: irregular,
        label: 'Entupido',
        activeColor: colors.warning,
      ),
      _StatCell(
        icon: Icons.check_circle,
        value: tolerancia,
        label: 'Tolerância',
        activeColor: colors.info,
      ),
      _StatCell(
        icon: Icons.trending_up,
        value: acimaMin,
        label: 'Acima Min',
        activeColor: AppColors.purple,
      ),
      _StatCell(
        icon: Icons.check_circle,
        value: ideal,
        label: 'Ideal',
        activeColor: colors.success,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0) Container(width: 1, height: 36, color: colors.border),
            Expanded(child: cells[i]),
          ],
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
    required this.activeColor,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final accent = value > 0 ? activeColor : colors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: accent),
        Text(
          '$value',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
