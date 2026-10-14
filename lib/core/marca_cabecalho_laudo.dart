import 'package:flutter/material.dart';

import '../models/configuracoes.dart';
import '../models/marca_pdf.dart';
import '../models/tipo_cabecalho_laudo.dart';
import 'layout_faixa_cabecalho_laudo.dart';
import '../theme.dart';

/// Cor da faixa do cabeçalho do laudo (modo sólido; não altera cores de zona).
Color corMarcaCabecalhoLaudo(Configuracoes config) {
  return _corPorPreset(
    config.corMarcaPdf,
    config.corMarcaPersonalizadaArgb,
  );
}

Color corMarcaGradienteInicioLaudo(Configuracoes config) {
  return _corPorPreset(
    config.corMarcaGradienteInicioPdf,
    config.corMarcaGradienteInicioArgb,
  );
}

Color corMarcaGradienteFimLaudo(Configuracoes config) {
  return _corPorPreset(
    config.corMarcaGradienteFimPdf,
    config.corMarcaGradienteFimArgb,
  );
}

Color _corPorPreset(CorMarcaPdf preset, int? personalizadaArgb) {
  if (preset == CorMarcaPdf.personalizada && personalizadaArgb != null) {
    return Color(personalizadaArgb);
  }
  return preset.color;
}

/// Texto legível sobre a cor da marca (C4).
Color textoSobreCorMarcaLaudo(Color fundo) {
  final lum = fundo.computeLuminance();
  return lum > 0.55 ? AppColors.textPrimary : Colors.white;
}

/// Texto de apoio (contato/e-mail) no cabeçalho: cinza iOS em fundo claro; suavizado em fundo escuro.
Color textoSecundarioSobreCabecalhoLaudo(Configuracoes config) {
  final primario = textoSobreCabecalhoLaudo(config);
  if (primario.computeLuminance() > 0.55) {
    return const Color(0xFF86868B);
  }
  return primario.withValues(alpha: 0.72);
}

Color textoSobreCabecalhoLaudo(Configuracoes config) {
  return switch (config.tipoCabecalhoLaudo) {
    TipoCabecalhoLaudo.solida => textoSobreCorMarcaLaudo(
        corMarcaCabecalhoLaudo(config),
      ),
    TipoCabecalhoLaudo.gradiente => textoSobreCorMarcaLaudo(
        Color.lerp(
          corMarcaGradienteInicioLaudo(config),
          corMarcaGradienteFimLaudo(config),
          0.5,
        )!,
      ),
    TipoCabecalhoLaudo.imagem => Colors.white,
  };
}

/// Overlay escuro sobre imagem de fundo (tela e PDF alinhados).
const overlayImagemCabecalhoLaudo = Color(0x8A000000);

BoxDecoration decoracaoFaixaCabecalhoLaudo(
  Configuracoes config, {
  ImageProvider? fundoImagem,
}) {
  switch (config.tipoCabecalhoLaudo) {
    case TipoCabecalhoLaudo.solida:
      return BoxDecoration(
        color: corMarcaCabecalhoLaudo(config),
        borderRadius: LayoutFaixaCabecalhoLaudo.borderRadius(),
      );
    case TipoCabecalhoLaudo.gradiente:
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            corMarcaGradienteInicioLaudo(config),
            corMarcaGradienteFimLaudo(config),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: LayoutFaixaCabecalhoLaudo.borderRadius(),
      );
    case TipoCabecalhoLaudo.imagem:
      if (fundoImagem != null) {
        return BoxDecoration(
          borderRadius: LayoutFaixaCabecalhoLaudo.borderRadius(),
          image: DecorationImage(
            image: fundoImagem,
            fit: BoxFit.cover,
          ),
        );
      }
      return BoxDecoration(
        color: corMarcaCabecalhoLaudo(config),
        borderRadius: LayoutFaixaCabecalhoLaudo.borderRadius(),
      );
  }
}
