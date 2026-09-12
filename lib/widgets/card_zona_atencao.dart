import 'package:flutter/material.dart';

import '../core/extensions/double_extension.dart';
import '../theme.dart';

class CardZonaAtencao extends StatelessWidget {
  const CardZonaAtencao({
    super.key,
    required this.qtdPontas,
    required this.perdaEstimada,
    this.limiteDesgaste = 105,
  });

  final int qtdPontas;
  final double perdaEstimada;
  final double limiteDesgaste;

  @override
  Widget build(BuildContext context) {
    if (qtdPontas == 0) return const SizedBox.shrink();

    final limite = limiteDesgaste.toStringAsFixed(0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.orangeBackground,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.orangeBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSpacing.xxxl,
            height: AppSpacing.xxxl,
            decoration: const BoxDecoration(
              color: AppColors.orangeIconBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zona de Atenção',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.orangeText,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$qtdPontas ponta(s) entre 100% e $limite% — ainda não pedem troca, já desperdiçam insumo.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  perdaEstimada.toMoeda(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.orangeText,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
