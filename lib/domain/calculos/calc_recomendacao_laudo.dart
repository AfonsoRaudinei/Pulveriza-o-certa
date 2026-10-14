import 'calc_analise_economica.dart';

/// Tipo de troca sugerida no laudo (fonte única para veredito e comparativo).
enum TipoRecomendacaoLaudo {
  nenhuma,
  unitaria,
  completa,
  dadosIncompletos,
}

/// Valores em R$ para exibição: total = desgaste + atenção (centavos consistentes).
class PrejuizoLaudoExibicao {
  const PrejuizoLaudoExibicao({
    required this.desgaste,
    required this.atencao,
    required this.total,
  });

  final double desgaste;
  final double atencao;
  final double total;
}

/// Pontas agrupadas por ação operacional.
class AcoesLaudo {
  const AcoesLaudo({
    required this.trocar,
    required this.limparRepetirTeste,
    required this.acompanhar,
  });

  final List<String> trocar;
  final List<String> limparRepetirTeste;
  final List<String> acompanhar;
}

class ResultadoRecomendacaoLaudo {
  const ResultadoRecomendacaoLaudo({
    required this.tipo,
    required this.acoes,
    required this.prejuizoDesgaste,
    required this.prejuizoAtencao,
    required this.prejuizoTotal,
    required this.exibicao,
    required this.custoTrocaRecomendada,
    required this.custoTrocaCompleta,
    required this.prejuizoResidual,
    required this.aplicacoesParaSePagar,
    required this.quantidadeDesgaste,
    required this.trocaTodosOsBicos,
  });

  final TipoRecomendacaoLaudo tipo;
  final AcoesLaudo acoes;
  final double prejuizoDesgaste;
  final double prejuizoAtencao;
  final double prejuizoTotal;
  final PrejuizoLaudoExibicao exibicao;
  final double custoTrocaRecomendada;
  final double custoTrocaCompleta;
  final double prejuizoResidual;
  final double? aplicacoesParaSePagar;
  final int quantidadeDesgaste;
  final bool trocaTodosOsBicos;
}

double _roundCentavos(double valor) => (valor * 100).roundToDouble() / 100;

/// Arredonda para exibição mantendo total = desgaste + atenção.
PrejuizoLaudoExibicao prejuizoLaudoParaExibicao({
  required double prejuizoDesgaste,
  required double prejuizoAtencao,
}) {
  final desgaste = _roundCentavos(prejuizoDesgaste);
  final atencao = _roundCentavos(prejuizoAtencao);
  final total = _roundCentavos(desgaste + atencao);
  return PrejuizoLaudoExibicao(
    desgaste: desgaste,
    atencao: atencao,
    total: total,
  );
}

ResultadoRecomendacaoLaudo calcularRecomendacaoLaudo({
  required List<String> rotulosDesgaste,
  required List<String> rotulosEntupida,
  required List<String> rotulosAtencao,
  required double prejuizoDesgaste,
  required double prejuizoAtencao,
  required double precoBicoRS,
  required int numeroPontas,
  required double manejoRS,
  required double areaHa,
  int numeroAplicacoes = 1,
}) {
  final prejuizoTotal = prejuizoDesgaste + prejuizoAtencao;
  final prejuizoSafra =
      calcularPerdaSafra(
        perdaPorAplicacao: prejuizoTotal,
        numeroAplicacoes: numeroAplicacoes,
      );
  final exibicao = prejuizoLaudoParaExibicao(
    prejuizoDesgaste: prejuizoDesgaste,
    prejuizoAtencao: prejuizoAtencao,
  );
  final custoCompleta = calcularCustoTrocaTotal(
    precoBicoRS: precoBicoRS,
    numeroPontas: numeroPontas,
  );
  final qDesgaste = rotulosDesgaste.length;
  final custoUnitaria = calcularCustoTrocaTotal(
    precoBicoRS: precoBicoRS,
    numeroPontas: qDesgaste,
  );

  final dadosCompletos = precoBicoRS > 0 &&
      areaHa > 0 &&
      manejoRS > 0 &&
      numeroPontas > 0;

  if (!dadosCompletos) {
    return ResultadoRecomendacaoLaudo(
      tipo: TipoRecomendacaoLaudo.dadosIncompletos,
      acoes: AcoesLaudo(
        trocar: const [],
        limparRepetirTeste: rotulosEntupida,
        acompanhar: rotulosAtencao,
      ),
      prejuizoDesgaste: prejuizoDesgaste,
      prejuizoAtencao: prejuizoAtencao,
      prejuizoTotal: prejuizoTotal,
      exibicao: exibicao,
      custoTrocaRecomendada: 0,
      custoTrocaCompleta: custoCompleta,
      prejuizoResidual: prejuizoTotal,
      aplicacoesParaSePagar: null,
      quantidadeDesgaste: qDesgaste,
      trocaTodosOsBicos: false,
    );
  }

  TipoRecomendacaoLaudo tipo;
  double custoRecomendado;
  double residual;
  double? aplicacoes;

  if (qDesgaste == 0) {
    tipo = TipoRecomendacaoLaudo.nenhuma;
    custoRecomendado = 0;
    residual = prejuizoTotal;
    aplicacoes = null;
  } else if (recomendarTrocaCompleta(
    perdaEstimadaTotal: prejuizoSafra,
    custoTrocaTotal: custoCompleta,
  )) {
    tipo = TipoRecomendacaoLaudo.completa;
    custoRecomendado = custoCompleta;
    residual = 0;
    aplicacoes = prejuizoTotal > 0 ? custoCompleta / prejuizoTotal : null;
  } else {
    tipo = TipoRecomendacaoLaudo.unitaria;
    custoRecomendado = custoUnitaria;
    residual = prejuizoAtencao;
    aplicacoes = prejuizoDesgaste > 0 && custoUnitaria > 0
        ? custoUnitaria / prejuizoDesgaste
        : null;
  }

  final trocaTodos = tipo == TipoRecomendacaoLaudo.completa;
  final trocar = tipo == TipoRecomendacaoLaudo.unitaria
      ? List<String>.from(rotulosDesgaste)
      : const <String>[];

  return ResultadoRecomendacaoLaudo(
    tipo: tipo,
    acoes: AcoesLaudo(
      trocar: trocar,
      limparRepetirTeste: List<String>.from(rotulosEntupida),
      acompanhar: List<String>.from(rotulosAtencao),
    ),
    prejuizoDesgaste: prejuizoDesgaste,
    prejuizoAtencao: prejuizoAtencao,
    prejuizoTotal: prejuizoTotal,
    exibicao: exibicao,
    custoTrocaRecomendada: custoRecomendado,
    custoTrocaCompleta: custoCompleta,
    prejuizoResidual: residual,
    aplicacoesParaSePagar: aplicacoes,
    quantidadeDesgaste: qDesgaste,
    trocaTodosOsBicos: trocaTodos,
  );
}

int? aplicacoesParaSePagarArredondadas(double? aplicacoes) {
  if (aplicacoes == null || !aplicacoes.isFinite || aplicacoes <= 0) {
    return null;
  }
  if (aplicacoes <= 1) return 1;
  return aplicacoes.ceil();
}
