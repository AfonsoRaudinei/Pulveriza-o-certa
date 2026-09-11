import 'package:flutter/material.dart';

import '../models/regulagem.dart';
import '../theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final StatusPonta status;

  @override
  Widget build(BuildContext context) {
    final style = _BadgeStyle.fromStatus(status, AppThemeColors.of(context));
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        style.label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: style.color),
      ),
    );
  }
}

class _BadgeStyle {
  const _BadgeStyle(this.label, this.background, this.color);

  final String label;
  final Color background;
  final Color color;

  factory _BadgeStyle.fromStatus(StatusPonta status, AppThemeColors colors) {
    return switch (status) {
      StatusPonta.ideal => _BadgeStyle(
          '● Ideal',
          colors.successLight,
          colors.success,
        ),
      StatusPonta.desgaste => _BadgeStyle(
          '▲ Desgaste',
          colors.dangerLight,
          colors.danger,
        ),
      StatusPonta.irregular => _BadgeStyle(
          '▼ Entupido',
          colors.warningLight,
          colors.warning,
        ),
      StatusPonta.pendente => _BadgeStyle(
          '○ Pendente',
          colors.surfaceAlt,
          colors.textTertiary,
        ),
    };
  }
}
