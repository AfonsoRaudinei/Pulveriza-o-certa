import 'package:flutter/material.dart';

import '../core/iconografia/zona_icon.dart';
import '../core/zona_visual.dart';
import '../domain/calculos/texto_pontas.dart';
import '../models/regulagem.dart';
import '../theme.dart';

/// Status com ícone da zona e texto curto, sem selo de fundo.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final StatusPonta status;

  @override
  Widget build(BuildContext context) {
    final cor = corZona(status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ZonaIcon(status: status, size: 11, color: cor),
        const SizedBox(width: AppSpacing.xs),
        Text(
          rotuloZona(status),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cor,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
