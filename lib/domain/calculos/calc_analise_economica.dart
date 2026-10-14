class ResultadoEconomico {
  const ResultadoEconomico({
    required this.perdaTotal,
    required this.custoTrocaTotal,
    required this.pontaRS,
    required this.recomendarTroca,
  });

  final double perdaTotal;
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

/// Registros antigos ou valor inválido → 1 aplicação (comportamento anterior).
int numeroAplicacoesEfetivo(int? numeroAplicacoes) {
  if (numeroAplicacoes == null || numeroAplicacoes <= 0) return 1;
  return numeroAplicacoes;
}

/// Perda estimada da safra = perda por aplicação × nº de aplicações.
double calcularPerdaSafra({
  required double perdaPorAplicacao,
  int? numeroAplicacoes,
}) {
  return perdaPorAplicacao *
      numeroAplicacoesEfetivo(numeroAplicacoes);
}

ResultadoEconomico analisarEconomia({
  required Iterable<double> percentuais,
  required double manejoRS,
  required int numeroPontas,
  required double areaHa,
  required double precoBicoRS,
}) {
  final perdaTotal = percentuais.fold<double>(
    0,
    (total, percentual) =>
        total +
        calcularPerdaPorPonta(
          percentual: percentual,
          manejoRS: manejoRS,
          numeroPontas: numeroPontas,
          areaHa: areaHa,
        ),
  );
  final custoTrocaTotal = calcularCustoTrocaTotal(
    precoBicoRS: precoBicoRS,
    numeroPontas: numeroPontas,
  );

  return ResultadoEconomico(
    perdaTotal: perdaTotal,
    custoTrocaTotal: custoTrocaTotal,
    pontaRS: calcularPontaRS(manejoRS: manejoRS, numeroPontas: numeroPontas),
    recomendarTroca: recomendarTrocaCompleta(
      perdaEstimadaTotal: perdaTotal,
      custoTrocaTotal: custoTrocaTotal,
    ),
  );
}
