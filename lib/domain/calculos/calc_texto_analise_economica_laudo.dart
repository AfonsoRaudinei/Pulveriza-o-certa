import 'calc_analise_economica.dart';
import 'calc_diagnostico_regulagem.dart';
import 'calc_texto_veredito_laudo.dart';

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
    required this.perdaTotal,
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
  final double perdaTotal;
  final double custoTrocaTotal;
  final double custoTrocaDesgaste;
  final bool recomendarTroca;
  final bool dadosEconomicosCompletos;
}

EntradaAnaliseEconomicaLaudo entradaAnaliseEconomicaLaudoDe(
  DiagnosticoRegulagem d,
) {
  final ex = d.planoLaudo.exibicao;
  final recomendar = d.dadosEconomicosCompletos &&
      recomendarTrocaCompleta(
        perdaEstimadaTotal: ex.total,
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
    perdaTotal: ex.total,
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

  final perdaFmt = formatarMoedaLaudo(e.perdaTotal);
  final destaque = 'Perda estimada por aplicação: $perdaFmt';

  final bullets = <String>[
    'Barra com ${e.numeroPontas} pontas · '
        '${formatarMoedaLaudo(e.manejoPonta)} por ponta a cada aplicação',
    _linhaReparticaoZonas(e),
  ];

  final fechamento = _fechamentoAnalise(e);

  return BlocosAnaliseEconomicaLaudo(
    perdaTotal: e.perdaTotal,
    destaquePerda: destaque,
    bullets: bullets,
    fechamento: fechamento,
  );
}

String _linhaReparticaoZonas(EntradaAnaliseEconomicaLaudo e) {
  final entupida = e.qtdEntupida == 1
      ? '1 entupida'
      : '${e.qtdEntupida} entupidas';
  final ideal = e.qtdIdeal == 1
      ? '1 dentro do ideal'
      : '${e.qtdIdeal} dentro do ideal';

  return '${e.qtdDesgaste} em desgaste (${formatarMoedaLaudo(e.perdaDesgaste)}) · '
      '${e.qtdAtencao} em atenção (${formatarMoedaLaudo(e.perdaAtencao)}) · '
      '$entupida · $ideal';
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
        texto: 'Ultrapassa o custo de troca completa dos bicos (',
      ),
      TrechoAnaliseEconomicaLaudo(texto: custo, negrito: true),
      const TrechoAnaliseEconomicaLaudo(
        texto: ') — substituição total é mais vantajosa.',
      ),
    ];
  }

  return const [
    TrechoAnaliseEconomicaLaudo(
      texto:
          'Fica abaixo do custo de troca completa dos bicos — '
          'substituição ponta a ponta é mais vantajosa.',
    ),
  ];
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
