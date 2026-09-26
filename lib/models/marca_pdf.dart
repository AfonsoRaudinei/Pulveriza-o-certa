import 'package:flutter/material.dart';

import '../theme.dart';

/// Cor de destaque do cabeçalho do laudo (nome + faixa). Não altera cores de status.
enum CorMarcaPdf { azul, verde, grafite, vinho, personalizada }

extension CorMarcaPdfColors on CorMarcaPdf {
  Color get color => switch (this) {
        CorMarcaPdf.azul => AppColors.primary,
        CorMarcaPdf.verde => const Color(0xFF047857),
        CorMarcaPdf.grafite => const Color(0xFF374151),
        CorMarcaPdf.vinho => const Color(0xFF7F1D1D),
        CorMarcaPdf.personalizada => AppColors.primary,
      };

  String get label => switch (this) {
        CorMarcaPdf.azul => 'Azul',
        CorMarcaPdf.verde => 'Verde',
        CorMarcaPdf.grafite => 'Grafite',
        CorMarcaPdf.vinho => 'Vinho',
        CorMarcaPdf.personalizada => 'Personalizada',
      };
}

CorMarcaPdf corMarcaPdfFromJson(Object? value) {
  return switch (value) {
    'verde' => CorMarcaPdf.verde,
    'grafite' => CorMarcaPdf.grafite,
    'vinho' => CorMarcaPdf.vinho,
    'personalizada' => CorMarcaPdf.personalizada,
    _ => CorMarcaPdf.azul,
  };
}
