import 'package:flutter/material.dart';

import '../models/configuracoes.dart';

/// Layout da faixa colorida do cabeçalho do laudo — única fonte para pré-visualização e PDF.
abstract final class LayoutFaixaCabecalhoLaudo {
  static const raioBorda = 6.0;

  static const paddingHorizontal = 10.0;
  static const paddingVertical = 8.0;

  static const alturaFaixaImagemSemLinhaContato = 44.0;
  static const alturaFaixaImagemComLinhaContato = 52.0;

  static EdgeInsets padding() => const EdgeInsets.symmetric(
        horizontal: paddingHorizontal,
        vertical: paddingVertical,
      );

  static BorderRadius borderRadius() =>
      BorderRadius.circular(raioBorda);

  /// Altura fixa da faixa no modo imagem (PDF e pré-visualização).
  static double alturaFaixaImagem(Configuracoes config) {
    return config.linhaContatoPerfilLaudo() != null
        ? alturaFaixaImagemComLinhaContato
        : alturaFaixaImagemSemLinhaContato;
  }
}
