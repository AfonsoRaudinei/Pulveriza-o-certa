import 'package:flutter/material.dart';

import '../theme.dart';

/// Título de seção do laudo: negrito 15 pt + subtítulo cinza (sem ícone).
class SecaoLaudoTitulo extends StatelessWidget {
  const SecaoLaudoTitulo({
    super.key,
    required this.titulo,
    this.subtitulo,
  });

  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
        ),
        if (subtitulo != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitulo!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        ],
      ],
    );
  }
}
