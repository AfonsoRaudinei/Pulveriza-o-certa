import 'package:flutter/material.dart';

import '../core/zona_visual.dart';
import '../domain/calculos/limites_regulagem.dart';
import '../models/regulagem.dart';
import '../theme.dart';

/// Barra horizontal das 4 zonas (A2), reativa aos limites digitados.
class BarraPreviewZonas extends StatelessWidget {
  const BarraPreviewZonas({
    super.key,
    required this.limites,
  });

  final LimitesRegulagem limites;

  @override
  Widget build(BuildContext context) {
    final ent = limites.limiteEntupido.clamp(1.0, 100.0);
    final des = limites.limiteDesgaste.clamp(100.0, 200.0);
    final flexEnt = ent.round().clamp(1, 100);
    final flexIdeal = (100 - ent).round().clamp(1, 100);
    final flexAtencao = (des - 100).round().clamp(1, 100);
    const flexDesgaste = 12;

    Widget faixa(StatusPonta status, int flex) {
      return Expanded(
        flex: flex,
        child: Container(
          height: 10,
          color: corZona(status),
        ),
      );
    }

    final labels = <String>[
      '< ${formatarLimitePercentual(ent)}%',
      '${formatarLimitePercentual(ent)}–100%',
      if (limites.temZonaAtencao) '100–${formatarLimitePercentual(des)}%',
      '> ${formatarLimitePercentual(des)}%',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Row(
            children: [
              faixa(StatusPonta.irregular, flexEnt),
              if (limites.temZonaIdeal) faixa(StatusPonta.ideal, flexIdeal),
              if (limites.temZonaAtencao) faixa(StatusPonta.atencao, flexAtencao),
              faixa(StatusPonta.desgaste, flexDesgaste),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          labels.join(' · '),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppThemeColors.of(context).textSecondary,
              ),
        ),
      ],
    );
  }
}
