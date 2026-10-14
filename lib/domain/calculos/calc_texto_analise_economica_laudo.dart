import 'calc_analise_economica.dart';
import 'calc_diagnostico_regulagem.dart';
import 'calc_texto_veredito_laudo.dart';
import '../../models/regulagem.dart';

/// Um trecho com negrito opcional (fechamento da análise econômica).
class TrechoAnaliseEconomicaLaudo {
  const TrechoAnaliseEconomicaLaudo({
    required this.texto,
    this.negrito = false,
  });

  final String texto;
  final bool negrito;
}

/// Layout em blocos para o laudo PDF (e testes).
class BlocosAnaliseEconomicaLaudo {
  const BlocosAnaliseEconomicaLaudo({
    required this.perdaTotal,
    required this.destaquePerda,
    required this.bullets,
    required this.fechamento,
    this.mensagemIncompleta,
  });

  final String? mensagemIncompleta;
  final double perdaTotal;
  final String destaquePerda;
  final List<String> bullets;
  final List<TrechoAnaliseEconomicaLaudo> fechamento;
}

class EntradaAnaliseEconomicaLaudo {
  const EntradaAnaliseEconomicaLaudo({
    required this.numeroPontas,
    required this.manejoHa,
    required this.manejoPonta,
    required this.qtdIdeal,
    required this.qtdEntupida,
    required this.qtdAtencao,
    required this.qtdDesgaste,
    required this.perdaAtencao,
    required this.perdaDesgaste,
    required this.perdaPorAplicacao,
    required this.numeroAplicacoes,
    this.tipoPonta,
    required this.custoTrocaTotal,
    required this.custoTrocaDesgaste,
    required this.recomendarTroca,
    required this.dadosEconomicosCompletos,
  });

  final int numeroPontas;
  final double manejoHa;
  final double manejoPonta;
  final int qtdIdeal;
  final int qtdEntupida;
  final int qtdAtencao;
  final int qtdDesgaste;
  final double perdaAtencao;
  final double perdaDesgaste;
  final double perdaPorAplicacao;
  final int numeroAplicacoes;
  final String? tipoPonta;
  final double custoTrocaTotal;
  final double custoTrocaDesgaste;
  final bool recomendarTroca;
  final bool dadosEconomicosCompletos;
}

EntradaAnaliseEconomicaLaudo entradaAnaliseEconomicaLaudoDe(
  DiagnosticoRegulagem d,
) {
  final ex = d.planoLaudo.exibicao;
  final perdaSafra = calcularPerdaSafra(
    perdaPorAplicacao: ex.total,
    numeroAplicacoes: d.numeroAplicacoes,
  );
  final recomendar = d.dadosEconomicosCompletos &&
      recomendarTrocaCompleta(
        perdaEstimadaTotal: perdaSafra,
        custoTrocaTotal: d.custoTrocaCompleta,
      );

  return EntradaAnaliseEconomicaLaudo(
    numeroPontas: d.totalPontas,
    manejoHa: d.manejoRS,
    manejoPonta: d.manejoPorPonta,
    qtdIdeal: d.ideal?.quantidade ?? 0,
    qtdEntupida: d.entupida?.quantidade ?? 0,
    qtdAtencao: d.atencao?.quantidade ?? 0,
    qtdDesgaste: d.desgaste?.quantidade ?? 0,
    perdaAtencao: ex.atencao,
    perdaDesgaste: ex.desgaste,
    perdaPorAplicacao: ex.total,
    numeroAplicacoes: d.numeroAplicacoes,
    tipoPonta: d.tipoPonta?.label,
    custoTrocaTotal: d.custoTrocaCompleta,
    custoTrocaDesgaste: d.custoTrocarSoDesgaste,
    recomendarTroca: recomendar,
    dadosEconomicosCompletos: d.dadosEconomicosCompletos,
  );
}

BlocosAnaliseEconomicaLaudo montarBlocosAnaliseEconomicaLaudo(
  DiagnosticoRegulagem d,
) {
  return montarBlocosAnaliseEconomicaLaudoDe(entradaAnaliseEconomicaLaudoDe(d));
}

BlocosAnaliseEconomicaLaudo montarBlocosAnaliseEconomicaLaudoDe(
  EntradaAnaliseEconomicaLaudo e,
) {
  if (!e.dadosEconomicosCompletos && e.manejoHa <= 0) {
    return BlocosAnaliseEconomicaLaudo(
      perdaTotal: 0,
      destaquePerda: '',
      bullets: const [],
      fechamento: const [],
      mensagemIncompleta:
          'Informe manejo, preço do bico e área para gerar a análise '
          'econômica deste laudo.',
    );
  }

  final perdaSafra = calcularPerdaSafra(
    perdaPorAplicacao: e.perdaPorAplicacao,
    numeroAplicacoes: e.numeroAplicacoes,
  );
  final perdaFmt = formatarMoedaLaudo(perdaSafra);
  final destaque = 'Perda estimada na safra: $perdaFmt';

  final bullets = <String>[
    'Barra com ${e.numeroPontas} pontas. Cada ponta custa '
        '${formatarMoedaLaudo(e.manejoPonta)} em produto por aplicação.',
    _linhaReparticaoZonas(e),
  ];

  final contextoSafra = _linhaContextoSafra(e);
  if (contextoSafra.isNotEmpty) {
    bullets.add(contextoSafra);
  }

  final fechamento = _fechamentoAnalise(e);

  return BlocosAnaliseEconomicaLaudo(
    perdaTotal: perdaSafra,
    destaquePerda: destaque,
    bullets: bullets,
    fechamento: fechamento,
  );
}

String _linhaReparticaoZonas(EntradaAnaliseEconomicaLaudo e) {
  final entupida = e.qtdEntupida == 1
      ? '1 entupida'
      : '${e.qtdEntupida} entupidas';
  final ideal = e.qtdIdeal == 1 ? '1 no ideal' : '${e.qtdIdeal} no ideal';
  final perdaDesgasteSafra = calcularPerdaSafra(
    perdaPorAplicacao: e.perdaDesgaste,
    numeroAplicacoes: e.numeroAplicacoes,
  );
  final perdaAtencaoSafra = calcularPerdaSafra(
    perdaPorAplicacao: e.perdaAtencao,
    numeroAplicacoes: e.numeroAplicacoes,
  );

  return '${e.qtdDesgaste} em desgaste (${formatarMoedaLaudo(perdaDesgasteSafra)}), '
      '${e.qtdAtencao} em atenção (${formatarMoedaLaudo(perdaAtencaoSafra)}), '
      '$entupida e $ideal.';
}

String _linhaContextoSafra(EntradaAnaliseEconomicaLaudo e) {
  if (e.numeroAplicacoes <= 1 &&
      (e.tipoPonta == null || e.tipoPonta!.isEmpty)) {
    return '';
  }
  final porApp = formatarMoedaLaudo(e.perdaPorAplicacao);
  final buffer = StringBuffer(
    '$porApp por aplicação × ${e.numeroAplicacoes} aplicações na safra',
  );
  if (e.tipoPonta != null && e.tipoPonta!.isNotEmpty) {
    buffer.write(' · ponta ${e.tipoPonta}');
  }
  buffer.write('.');
  return buffer.toString();
}

List<TrechoAnaliseEconomicaLaudo> _fechamentoAnalise(
  EntradaAnaliseEconomicaLaudo e,
) {
  if (e.qtdAtencao + e.qtdDesgaste <= 0 || !e.dadosEconomicosCompletos) {
    return const [];
  }

  final custo = formatarMoedaLaudo(e.custoTrocaTotal);

  if (e.recomendarTroca) {
    return [
      const TrechoAnaliseEconomicaLaudo(
        texto: 'Essa perda já passa o custo de trocar todos os bicos (',
      ),
      TrechoAnaliseEconomicaLaudo(texto: custo, negrito: true),
      const TrechoAnaliseEconomicaLaudo(
        texto: '). Compensa trocar o jogo.',
      ),
    ];
  }

  return const [
    TrechoAnaliseEconomicaLaudo(
      texto:
          'Essa perda ainda é menor que trocar todos os bicos. '
          'Vale trocar só as pontas em desgaste.',
    ),
  ];
}

/// Corpo em parágrafo corrido (laudo PDF), sem o destaque inicial.
String corpoParagrafoAnaliseEconomicaLaudo(BlocosAnaliseEconomicaLaudo blocos) {
  if (blocos.mensagemIncompleta != null || blocos.bullets.isEmpty) {
    return '';
  }
  return blocos.bullets.join(' ');
}

/// Texto corrido para testes (sem marcação de negrito).
String analiseEconomicaLaudoComoTexto(BlocosAnaliseEconomicaLaudo blocos) {
  if (blocos.mensagemIncompleta != null) {
    return blocos.mensagemIncompleta!;
  }
  final parts = <String>[
    blocos.destaquePerda,
    ...blocos.bullets,
    ...blocos.fechamento.map((t) => t.texto),
  ];
  return parts.join(' ');
}
