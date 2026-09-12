/// Resultado da perda na faixa intermediária (Zona de Atenção).
///
/// Pontas com `100 < percentual <= limiteDesgaste` ainda não pedem troca
/// (não são Desgaste), mas já geram desperdício de insumo mensurável.
class ResultadoZonaAtencao {
  const ResultadoZonaAtencao({
    required this.perdaEstimada,
    required this.qtdPontasNaZona,
  });

  final double perdaEstimada;
  final int qtdPontasNaZona;
}

/// Soma a perda em R$ só das pontas na Zona de Atenção.
///
/// Faixa: `100 < percentual <= limiteDesgaste` (padrão 105). O extremo
/// 100% não entra (sem excesso); 105% exato entra; acima de 105% é
/// Desgaste e fica de fora — os dois totais não se sobrepõem.
///
/// Fórmula (por ponta na faixa):
/// ```
/// excessoFracao = (percentual - 100) / 100     // adimensional
/// custoPorPonta = manejoRS / numeroPontas      // R$/ponta
/// perdaPonta    = excessoFracao × custoPorPonta × areaHa  // R$
/// ```
///
/// Derivação: o excesso percentual vira fração de calda a mais; essa
/// fração incide sobre o custo de manejo alocado à ponta, na área
/// aplicada.
///
/// Exemplo: 24 pontas, manejo R$ 2.400, área 500 ha, limite 105.
/// Ponta 103% → 0,03 × 100 × 500 = R$ 1.500.
/// Ponta 105% → 0,05 × 100 × 500 = R$ 2.500.
/// Ponta 108% → fora da zona (Desgaste).
/// Total da zona = R$ 4.000 (2 pontas).
///
/// Entradas inválidas (`numeroPontas`, `manejoRS` ou `areaHa` ≤ 0)
/// devolvem `(perdaEstimada: 0, qtdPontasNaZona: 0)` sem lançar.
ResultadoZonaAtencao calcularPerdaZonaAtencao({
  required List<double> percentuais,
  required double manejoRS,
  required int numeroPontas,
  required double areaHa,
  double limiteDesgaste = 105,
}) {
  if (numeroPontas <= 0 || manejoRS <= 0 || areaHa <= 0) {
    return const ResultadoZonaAtencao(perdaEstimada: 0, qtdPontasNaZona: 0);
  }

  var perdaEstimada = 0.0;
  var qtdPontasNaZona = 0;
  final custoPorPonta = manejoRS / numeroPontas;

  for (final percentual in percentuais) {
    if (percentual <= 100 || percentual > limiteDesgaste) continue;
    qtdPontasNaZona++;
    final excessoFracao = (percentual - 100) / 100;
    perdaEstimada += excessoFracao * custoPorPonta * areaHa;
  }

  return ResultadoZonaAtencao(
    perdaEstimada: perdaEstimada,
    qtdPontasNaZona: qtdPontasNaZona,
  );
}
