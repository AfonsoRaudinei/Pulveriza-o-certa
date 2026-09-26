import 'package:flutter/material.dart';

import '../../../core/iconografia/zona_icon.dart';
import '../../../core/marcadores_zona.dart';
import '../../../domain/calculos/calc_diagnostico_regulagem.dart';
import '../../../domain/calculos/texto_pontas.dart';
import '../../../theme.dart';

/// Resumo das zonas em uma linha horizontal, sem caixa.
class MedicoesResumoCard extends StatelessWidget {
  const MedicoesResumoCard({super.key, required this.zonas});

  final List<ZonaDiagnostico> zonas;

  static const _divisor = Color(0xFFE5E5E7);

  @override
  Widget build(BuildContext context) {
    if (zonas.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (var i = 0; i < zonas.length; i++) ...[
          if (i > 0)
            Container(
              width: 1,
              height: 48,
              color: _divisor,
            ),
          Expanded(child: _ZonaCell(zona: zonas[i])),
        ],
      ],
    );
  }
}

class _ZonaCell extends StatelessWidget {
  const _ZonaCell({required this.zona});

  final ZonaDiagnostico zona;

  @override
  Widget build(BuildContext context) {
    final accent = MarcadoresZona.cor(zona.status);
    final colors = AppThemeColors.of(context);
    const tituloCor = Color(0xFF1D1D1F);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ZonaIcon(status: zona.status, size: 11, color: accent),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${zona.quantidade}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: tituloCor,
          ),
        ),
        Text(
          rotuloZona(zona.status),
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: tituloCor,
          ),
        ),
        Text(
          zona.faixa,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
