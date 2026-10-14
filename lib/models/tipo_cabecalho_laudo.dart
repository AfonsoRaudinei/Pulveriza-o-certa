/// Fundo da faixa do cabeçalho do laudo PDF.
enum TipoCabecalhoLaudo { solida, gradiente, imagem }

extension TipoCabecalhoLaudoLabels on TipoCabecalhoLaudo {
  String get label => switch (this) {
        TipoCabecalhoLaudo.solida => 'Cor sólida',
        TipoCabecalhoLaudo.gradiente => 'Gradiente',
        TipoCabecalhoLaudo.imagem => 'Imagem',
      };
}

TipoCabecalhoLaudo tipoCabecalhoLaudoFromJson(Object? value) {
  return switch (value) {
    'gradiente' => TipoCabecalhoLaudo.gradiente,
    'imagem' => TipoCabecalhoLaudo.imagem,
    _ => TipoCabecalhoLaudo.solida,
  };
}
