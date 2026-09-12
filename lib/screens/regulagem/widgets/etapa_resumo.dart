import 'package:flutter/material.dart';

import '../../../theme.dart';

/// Uma linha da ficha recolhida: rótulo à esquerda, valor à direita.
class EtapaResumoLinha {
  const EtapaResumoLinha(this.label, this.value);

  final String label;
  final String value;
}

/// Resumo tipo ficha, só com o que já foi preenchido.
class EtapaResumo extends StatelessWidget {
  const EtapaResumo({super.key, required this.linhas});

  final List<EtapaResumoLinha> linhas;

  /// `null` quando nenhuma linha tem valor — o card fechado fica só com o título.
  static Widget? ouNulo(Iterable<EtapaResumoLinha> candidatas) {
    final linhas = [
      for (final linha in candidatas)
        if (linha.value.trim().isNotEmpty) linha,
    ];
    if (linhas.isEmpty) return null;
    return EtapaResumo(linhas: linhas);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final linha in linhas)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    linha.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 3,
                  child: Text(
                    linha.value,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
