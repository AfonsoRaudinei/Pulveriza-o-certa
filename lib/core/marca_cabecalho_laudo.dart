import 'package:flutter/material.dart';

import '../models/configuracoes.dart';
import '../models/marca_pdf.dart';
import '../theme.dart';

/// Cor da faixa do cabeçalho do laudo (não altera cores de zona).
Color corMarcaCabecalhoLaudo(Configuracoes config) {
  if (config.corMarcaPdf == CorMarcaPdf.personalizada &&
      config.corMarcaPersonalizadaArgb != null) {
    return Color(config.corMarcaPersonalizadaArgb!);
  }
  return config.corMarcaPdf.color;
}

/// Texto legível sobre a cor da marca (C4).
Color textoSobreCorMarcaLaudo(Color fundo) {
  final lum = fundo.computeLuminance();
  return lum > 0.55 ? AppColors.textPrimary : Colors.white;
}
