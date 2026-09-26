/// Legado de relatórios antigos (tolerância mín/máx). Não usado na classificação do laudo.
const double toleranciaMinLegado = 100.5;
const double toleranciaMaxLegado = 104.99;

({bool entreTolerancias, bool acimaToleranciaMin}) verificarTolerancia({
  required double percentual,
  double toleranciaMin = toleranciaMinLegado,
  double toleranciaMax = toleranciaMaxLegado,
}) {
  final acima = percentual >= toleranciaMin;
  return (
    entreTolerancias: acima && percentual <= toleranciaMax,
    acimaToleranciaMin: acima,
  );
}

({int entreTolerancias, int acimaToleranciaMin}) agregarTolerancia({
  required Iterable<double> percentuais,
  double toleranciaMin = toleranciaMinLegado,
  double toleranciaMax = toleranciaMaxLegado,
}) {
  var entre = 0;
  var acima = 0;

  for (final percentual in percentuais) {
    final tolerancia = verificarTolerancia(
      percentual: percentual,
      toleranciaMin: toleranciaMin,
      toleranciaMax: toleranciaMax,
    );
    if (tolerancia.entreTolerancias) entre++;
    if (tolerancia.acimaToleranciaMin) acima++;
  }

  return (entreTolerancias: entre, acimaToleranciaMin: acima);
}
