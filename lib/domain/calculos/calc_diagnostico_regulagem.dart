import 'dart:math' as math;

import '../../models/regulagem.dart';
import 'calc_analise_economica.dart';
import 'calc_classificacao_status.dart';
import 'calc_recomendacao_laudo.dart';
import 'calc_texto_veredito_laudo.dart';
import 'calc_percentual_ponta.dart';
import 'limites_regulagem.dart';
import 'texto_pontas.dart';

enum TipoRecomendacao {
  trocaCompleta,
  trocarDesgasteMonitorarAtencao,
  monitorarAtencao,
  semAcao,
  dadosEconomicosIncompletos,
}

class PontaClassificada {
  const PontaClassificada({
    required this.id,
    required this.rotulo,
    required this.valorMedido,
    required this.percentual,
    required this.status,
  });

  final int id;
  final String rotulo;
  final double valorMedido;
  final double percentual;
  final StatusPonta status;
}

class ZonaDiagnostico {
  const ZonaDiagnostico({
    required this.status,
    required this.quantidade,
    required this.mediaPercentual,
    required this.rotulos,
    required this.faixa,
    required this.perdaRs,
  });

  final StatusPonta status;
  final int quantidade;
  final double mediaPercentual;
  final List<String> rotulos;
  final String faixa;
  final double perdaRs;
}

class RecomendacaoDiagnostico {
  const RecomendacaoDiagnostico({
    required this.tipo,
    required this.texto,
    this.paybackAplicacoes,
    this.vezesPerdaSuperaCusto,
  });

  final TipoRecomendacao tipo;
  final String texto;
  final double? paybackAplicacoes;
  final double? vezesPerdaSuperaCusto;
}

class UniformidadeDiagnostico {
  const UniformidadeDiagnostico({
    required this.media,
    required this.desvioPadrao,
    required this.cvPercentual,
  });

  final double media;
  final double desvioPadrao;
  final double cvPercentual;
}

class OrientacaoDiagnostico {
  const OrientacaoDiagnostico({
    required this.status,
    required this.quantidade,
    required this.rotulos,
    required this.perdaRs,
  });

  final StatusPonta status;
  final int quantidade;
  final List<String> rotulos;
  final double? perdaRs;
}

class DiagnosticoRegulagem {
  const DiagnosticoRegulagem({
    required this.limites,
    required this.totalPontas,
    required this.medidas,
    required this.analiseParcial,
    required this.pontas,
    required this.entupida,
    required this.ideal,
    required this.atencao,
    required this.desgaste,
    required this.manejoPorPonta,
    required this.perdaAtencao,
    required this.perdaDesgaste,
    required this.perdaTotal,
    required this.custoTrocaCompleta,
    required this.custoTrocarSoDesgaste,
    required this.manejoRS,
    required this.precoBicoRS,
    required this.areaHa,
    required this.dadosEconomicosCompletos,
    required this.recomendacao,
    required this.uniformidade,
    required this.acaoNecessaria,
    required this.piorZona,
    required this.orientacoes,
    required this.planoLaudo,
    required this.vereditoLaudo,
  });

  final LimitesRegulagem limites;
  final int totalPontas;
  final int medidas;
  final bool analiseParcial;
  final List<PontaClassificada> pontas;
  final ZonaDiagnostico? entupida;
  final ZonaDiagnostico? ideal;
  final ZonaDiagnostico? atencao;
  final ZonaDiagnostico? desgaste;
  final double manejoPorPonta;
  final double perdaAtencao;
  final double perdaDesgaste;
  final double perdaTotal;
  final double custoTrocaCompleta;
  final double custoTrocarSoDesgaste;
  final double manejoRS;
  final double precoBicoRS;
  final double areaHa;
  final bool dadosEconomicosCompletos;
  final RecomendacaoDiagnostico recomendacao;
  final UniformidadeDiagnostico? uniformidade;
  final String acaoNecessaria;
  final StatusPonta? piorZona;
  final List<OrientacaoDiagnostico> orientacoes;
  final ResultadoRecomendacaoLaudo planoLaudo;
  final String vereditoLaudo;

  String? get avisoMedicao => analiseParcial
      ? avisoMedicaoIncompleta(medidas: medidas, total: totalPontas)
      : null;

  List<ZonaDiagnostico> get zonasVisiveis => [
        if (entupida != null) entupida!,
        if (ideal != null) ideal!,
        if (atencao != null) atencao!,
        if (desgaste != null) desgaste!,
      ];

  factory DiagnosticoRegulagem.calcular({
    required List<PontaMedicao> medicoes,
    required double litroMinIdeal,
    required LimitesRegulagem limites,
    required LadoConferenciaPontas lado,
    required double manejoRS,
    required double precoBicoRS,
    required double areaHa,
  }) {
    final totalPontas = medicoes.length;
    final classificadas = <PontaClassificada>[];
    for (final item in medicoes) {
      if (item.valorMedido == null) continue;
      final percentual = calcularPercentualPonta(
        valorMedido: item.valorMedido,
        litroMinIdeal: litroMinIdeal,
      );
      final status = classificarPonta(
        valorMedido: item.valorMedido,
        litroMinIdeal: litroMinIdeal,
        limites: limites,
      );
      classificadas.add(
        PontaClassificada(
          id: item.id,
          rotulo: rotuloPonta(item.id, lado),
          valorMedido: item.valorMedido!,
          percentual: percentual,
          status: status,
        ),
      );
    }

    ZonaDiagnostico? zonaDe(StatusPonta status) {
      final itens = [
        for (final ponta in classificadas)
          if (ponta.status == status) ponta,
      ];
      final omitir = (status == StatusPonta.ideal && !limites.temZonaIdeal) ||
          (status == StatusPonta.atencao && !limites.temZonaAtencao);
      if (itens.isEmpty || omitir) return null;
      final media =
          itens.fold<double>(0, (s, p) => s + p.percentual) / itens.length;
      var perda = 0.0;
      if (status == StatusPonta.atencao || status == StatusPonta.desgaste) {
        for (final ponta in itens) {
          perda += calcularPerdaPorPonta(
            percentual: ponta.percentual,
            manejoRS: manejoRS,
            numeroPontas: totalPontas,
            areaHa: areaHa,
          );
        }
      }
      return ZonaDiagnostico(
        status: status,
        quantidade: itens.length,
        mediaPercentual: media,
        rotulos: [for (final p in itens) p.rotulo],
        faixa: switch (status) {
          StatusPonta.irregular => limites.faixaEntupida,
          StatusPonta.ideal => limites.faixaIdeal,
          StatusPonta.atencao => limites.faixaAtencao,
          StatusPonta.desgaste => limites.faixaDesgaste,
          StatusPonta.pendente => '',
        },
        perdaRs: perda,
      );
    }

    final entupida = zonaDe(StatusPonta.irregular);
    final ideal = zonaDe(StatusPonta.ideal);
    final atencao = zonaDe(StatusPonta.atencao);
    final desgaste = zonaDe(StatusPonta.desgaste);

    final perdaAtencao = atencao?.perdaRs ?? 0;
    final perdaDesgaste = desgaste?.perdaRs ?? 0;
    final perdaTotal = perdaAtencao + perdaDesgaste;
    final custoCompleta = calcularCustoTrocaTotal(
      precoBicoRS: precoBicoRS,
      numeroPontas: totalPontas,
    );
    final custoSoDesgaste = calcularCustoTrocaTotal(
      precoBicoRS: precoBicoRS,
      numeroPontas: desgaste?.quantidade ?? 0,
    );
    final pontaRS = calcularPontaRS(
      manejoRS: manejoRS,
      numeroPontas: totalPontas,
    );
    final dadosCompletos =
        precoBicoRS > 0 && areaHa > 0 && manejoRS > 0 && totalPontas > 0;

    final planoLaudo = calcularRecomendacaoLaudo(
      rotulosDesgaste: desgaste?.rotulos ?? const [],
      rotulosEntupida: entupida?.rotulos ?? const [],
      rotulosAtencao: atencao?.rotulos ?? const [],
      prejuizoDesgaste: perdaDesgaste,
      prejuizoAtencao: perdaAtencao,
      precoBicoRS: precoBicoRS,
      numeroPontas: totalPontas,
      manejoRS: manejoRS,
      areaHa: areaHa,
    );

    final vereditoLaudo = montarVereditoLaudo(
      plano: planoLaudo,
      areaHa: areaHa,
      quantidadeDesgaste: desgaste?.quantidade ?? 0,
      quantidadeAtencao: atencao?.quantidade ?? 0,
      rotulosDesgaste: desgaste?.rotulos ?? const [],
      mediaPercentualAtencao: atencao?.mediaPercentual,
    );

    final recomendacao = _recomendarLegado(
      plano: planoLaudo,
      desgaste: desgaste,
      atencao: atencao,
    );

    final acaoNecessaria = textoAcaoNecessaria(
      desgaste: desgaste?.rotulos ?? const [],
      entupida: entupida?.rotulos ?? const [],
      atencao: atencao?.rotulos ?? const [],
    );

    final piorZona = desgaste != null
        ? StatusPonta.desgaste
        : entupida != null
            ? StatusPonta.irregular
            : atencao != null
                ? StatusPonta.atencao
                : ideal != null
                    ? StatusPonta.ideal
                    : null;

    final orientacoes = <OrientacaoDiagnostico>[
      if (desgaste != null)
        OrientacaoDiagnostico(
          status: StatusPonta.desgaste,
          quantidade: desgaste.quantidade,
          rotulos: desgaste.rotulos,
          perdaRs: desgaste.perdaRs,
        ),
      if (entupida != null)
        OrientacaoDiagnostico(
          status: StatusPonta.irregular,
          quantidade: entupida.quantidade,
          rotulos: entupida.rotulos,
          perdaRs: null,
        ),
      if (atencao != null)
        OrientacaoDiagnostico(
          status: StatusPonta.atencao,
          quantidade: atencao.quantidade,
          rotulos: atencao.rotulos,
          perdaRs: atencao.perdaRs,
        ),
      if (ideal != null)
        OrientacaoDiagnostico(
          status: StatusPonta.ideal,
          quantidade: ideal.quantidade,
          rotulos: ideal.rotulos,
          perdaRs: null,
        ),
    ];

    return DiagnosticoRegulagem(
      limites: limites,
      totalPontas: totalPontas,
      medidas: classificadas.length,
      analiseParcial: classificadas.length < totalPontas,
      pontas: classificadas,
      entupida: entupida,
      ideal: ideal,
      atencao: atencao,
      desgaste: desgaste,
      manejoPorPonta: pontaRS,
      perdaAtencao: perdaAtencao,
      perdaDesgaste: perdaDesgaste,
      perdaTotal: perdaTotal,
      custoTrocaCompleta: custoCompleta,
      custoTrocarSoDesgaste: custoSoDesgaste,
      manejoRS: manejoRS,
      precoBicoRS: precoBicoRS,
      areaHa: areaHa,
      dadosEconomicosCompletos: dadosCompletos,
      recomendacao: recomendacao,
      uniformidade: _uniformidade(classificadas),
      acaoNecessaria: acaoNecessaria,
      piorZona: piorZona,
      orientacoes: orientacoes,
      planoLaudo: planoLaudo,
      vereditoLaudo: vereditoLaudo,
    );
  }
}

RecomendacaoDiagnostico _recomendarLegado({
  required ResultadoRecomendacaoLaudo plano,
  required ZonaDiagnostico? desgaste,
  required ZonaDiagnostico? atencao,
}) {
  switch (plano.tipo) {
    case TipoRecomendacaoLaudo.dadosIncompletos:
      return const RecomendacaoDiagnostico(
        tipo: TipoRecomendacao.dadosEconomicosIncompletos,
        texto: 'Informe preço do bico, área e manejo para a análise econômica',
      );
    case TipoRecomendacaoLaudo.completa:
      final payback = plano.aplicacoesParaSePagar ?? 0;
      final vezes = plano.prejuizoTotal / plano.custoTrocaRecomendada;
      return RecomendacaoDiagnostico(
        tipo: TipoRecomendacao.trocaCompleta,
        texto:
            'Troca completa recomendada. Custo se paga em ${_formatarNumero(payback)} aplicações. '
            'A perda supera o custo ${_formatarNumero(vezes)} vezes.',
        paybackAplicacoes: payback,
        vezesPerdaSuperaCusto: vezes,
      );
    case TipoRecomendacaoLaudo.unitaria:
      final lista = juntarRotulosPontas(plano.acoes.trocar);
      final monitorar = atencao != null ? ' e monitorar as em atenção' : '';
      return RecomendacaoDiagnostico(
        tipo: TipoRecomendacao.trocarDesgasteMonitorarAtencao,
        texto: 'Trocar as pontas em desgaste ($lista)$monitorar.',
      );
    case TipoRecomendacaoLaudo.nenhuma:
      if (atencao != null) {
        return const RecomendacaoDiagnostico(
          tipo: TipoRecomendacao.monitorarAtencao,
          texto: 'Monitorar as pontas em atenção.',
        );
      }
      return const RecomendacaoDiagnostico(
        tipo: TipoRecomendacao.semAcao,
        texto: 'Sem ação de troca.',
      );
  }
}

UniformidadeDiagnostico? _uniformidade(List<PontaClassificada> pontas) {
  if (pontas.isEmpty) return null;
  final n = pontas.length;
  final media = pontas.fold<double>(0, (s, p) => s + p.percentual) / n;
  if (n == 1) {
    return UniformidadeDiagnostico(
      media: media,
      desvioPadrao: 0,
      cvPercentual: 0,
    );
  }
  var somaSq = 0.0;
  for (final ponta in pontas) {
    final d = ponta.percentual - media;
    somaSq += d * d;
  }
  final desvio = math.sqrt(somaSq / n);
  final cv = media == 0 ? 0.0 : (desvio / media) * 100;
  return UniformidadeDiagnostico(
    media: media,
    desvioPadrao: desvio,
    cvPercentual: cv,
  );
}

String _formatarNumero(double valor) {
  if (valor >= 10) return valor.round().toString();
  final umaCasa = (valor * 10).round() / 10;
  if ((valor - umaCasa).abs() < 0.05) {
    return umaCasa.toStringAsFixed(1).replaceAll('.', ',');
  }
  return valor.toStringAsFixed(2).replaceAll('.', ',');
}
