import 'package:flutter/material.dart';

import '../../../theme.dart';

enum AlertaSeveridade { ok, atencao, urgente }

class AlertaOrientacao extends StatelessWidget {
  const AlertaOrientacao({
    super.key,
    required this.texto,
    this.titulo,
    this.severidade = AlertaSeveridade.urgente,
  });

  final String texto;
  final String? titulo;
  final AlertaSeveridade severidade;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final fundo = switch (severidade) {
      AlertaSeveridade.ok => colors.successLight,
      AlertaSeveridade.atencao => colors.warningLight,
      AlertaSeveridade.urgente => colors.dangerLight,
    };
    final acento = switch (severidade) {
      AlertaSeveridade.ok => colors.success,
      AlertaSeveridade.atencao => colors.warning,
      AlertaSeveridade.urgente => colors.danger,
    };
    final icone = switch (severidade) {
      AlertaSeveridade.ok => Icons.check_circle_outline,
      AlertaSeveridade.atencao => Icons.warning_amber_outlined,
      AlertaSeveridade.urgente => Icons.error_outline,
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: acento),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (titulo != null)
                  Text(
                    titulo!,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: acento),
                  ),
                Text(
                  texto,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
