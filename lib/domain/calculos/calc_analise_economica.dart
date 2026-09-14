class ResultadoEconomico {
  const ResultadoEconomico({
    required this.perdaTotal,
    required this.perdaTolerancia,
    required this.perdaDesgaste,
    required this.custoTrocaTotal,
    required this.pontaRS,
    required this.recomendarTroca,
  });

  final double perdaTotal;
  final double perdaTolerancia;
  final double perdaDesgaste;
  final double custoTrocaTotal;
  final double pontaRS;
  final bool recomendarTroca;
}

double calcularPerdaPorPonta({
  required double percentual,
  required double manejoRS,
  required int numeroPontas,
  required double areaHa,
}) {
  if (percentual <= 100 || manejoRS <= 0 || numeroPontas <= 0 || areaHa <= 0) {
    return 0;
  }
  return ((percentual - 100) / 100) * (manejoRS / numeroPontas) * areaHa;
}

({double tolerancia, double desgaste}) segmentarPerdaPorPonta({
  required double percentual,
  required double manejoRS,
  required int numeroPontas,
  required double areaHa,
  required double limiteDesgaste,
}) {
  final perda = calcularPerdaPorPonta(
    percentual: percentual,
    manejoRS: manejoRS,
    numeroPontas: numeroPontas,
    areaHa: areaHa,
  );
  if (perda <= 0) {
    return (tolerancia: 0, desgaste: 0);
  }
  if (percentual <= limiteDesgaste) {
    return (tolerancia: perda, desgaste: 0);
  }
  return (tolerancia: 0, desgaste: perda);
}

double calcularPontaRS({
  required double manejoRS,
  required int numeroPontas,
}) {
  if (manejoRS <= 0 || numeroPontas <= 0) return 0;
  return manejoRS / numeroPontas;
}

double calcularCustoTrocaTotal({
  required double precoBicoRS,
  required int numeroPontas,
}) {
  if (precoBicoRS <= 0 || numeroPontas <= 0) return 0;
  return precoBicoRS * numeroPontas;
}

bool recomendarTrocaCompleta({
  required double perdaEstimadaTotal,
  required double custoTrocaTotal,
}) {
  if (custoTrocaTotal <= 0) return false;
  return perdaEstimadaTotal >= custoTrocaTotal;
}

ResultadoEconomico analisarEconomia({
  required Iterable<double> percentuais,
  required double manejoRS,
  required int numeroPontas,
  required double areaHa,
  required double precoBicoRS,
  double limiteDesgaste = 105,
}) {
  var perdaTolerancia = 0.0;
  var perdaDesgaste = 0.0;
  for (final percentual in percentuais) {
    final segmento = segmentarPerdaPorPonta(
      percentual: percentual,
      manejoRS: manejoRS,
      numeroPontas: numeroPontas,
      areaHa: areaHa,
      limiteDesgaste: limiteDesgaste,
    );
    perdaTolerancia += segmento.tolerancia;
    perdaDesgaste += segmento.desgaste;
  }
  final perdaTotal = perdaTolerancia + perdaDesgaste;
  final custoTrocaTotal = calcularCustoTrocaTotal(
    precoBicoRS: precoBicoRS,
    numeroPontas: numeroPontas,
  );

  return ResultadoEconomico(
    perdaTotal: perdaTotal,
    perdaTolerancia: perdaTolerancia,
    perdaDesgaste: perdaDesgaste,
    custoTrocaTotal: custoTrocaTotal,
    pontaRS: calcularPontaRS(manejoRS: manejoRS, numeroPontas: numeroPontas),
    recomendarTroca: recomendarTrocaCompleta(
      perdaEstimadaTotal: perdaTotal,
      custoTrocaTotal: custoTrocaTotal,
    ),
  );
}
