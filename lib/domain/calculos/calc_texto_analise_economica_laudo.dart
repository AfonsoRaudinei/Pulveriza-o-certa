import 'calc_analise_economica.dart';
import 'calc_diagnostico_regulagem.dart';
import 'calc_texto_veredito_laudo.dart';

/// Um trecho do parágrafo único (negrito = contagens e valores em R$).
class TrechoAnaliseEconomicaLaudo {
  const TrechoAnaliseEconomicaLaudo({
    required this.texto,
    this.negrito = false,
  });

  final String texto;
  final bool negrito;
}

/// Parágrafo único = sequência de trechos (sem quebras).
typedef ParagrafoAnaliseEconomicaLaudo = List<TrechoAnaliseEconomicaLaudo>;

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

ParagrafoAnaliseEconomicaLaudo montarAnaliseEconomicaLaudo(
  DiagnosticoRegulagem d,
) {
  final ex = d.planoLaudo.exibicao;
  final recomendar = d.dadosEconomicosCompletos &&
      recomendarTrocaCompleta(
        perdaEstimadaTotal: ex.total,
        custoTrocaTotal: d.custoTrocaCompleta,
      );

  return montarAnaliseEconomicaLaudoDe(
    EntradaAnaliseEconomicaLaudo(
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
    ),
  );
}

ParagrafoAnaliseEconomicaLaudo montarAnaliseEconomicaLaudoDe(
  EntradaAnaliseEconomicaLaudo e,
) {
  if (!e.dadosEconomicosCompletos && e.manejoHa <= 0) {
    return const [
      TrechoAnaliseEconomicaLaudo(
        texto:
            'Informe manejo, preço do bico e área para gerar a análise '
            'econômica deste laudo.',
      ),
    ];
  }

  final out = <TrechoAnaliseEconomicaLaudo>[];
  _appendAbertura(out, e.numeroPontas, e.manejoHa, e.manejoPonta);

  if (e.qtdIdeal == e.numeroPontas) {
    _appendTodasIdeais(out, e.numeroPontas);
    return out;
  }

  _appendReparticao(out, e);
  _appendFechamentoSeNecessario(out, e);
  return out;
}

void _appendAbertura(
  List<TrechoAnaliseEconomicaLaudo> out,
  int numeroPontas,
  double manejoHa,
  double manejoPonta,
) {
  out.addAll([
    const TrechoAnaliseEconomicaLaudo(texto: 'Trabalhamos com '),
    TrechoAnaliseEconomicaLaudo(texto: '$numeroPontas', negrito: true),
    const TrechoAnaliseEconomicaLaudo(
      texto: ' pontas nesta barra. O manejo custa ',
    ),
    TrechoAnaliseEconomicaLaudo(texto: formatarMoedaLaudo(manejoHa), negrito: true),
    const TrechoAnaliseEconomicaLaudo(texto: ' por hectare, o que dá '),
    TrechoAnaliseEconomicaLaudo(
      texto: formatarMoedaLaudo(manejoPonta),
      negrito: true,
    ),
    const TrechoAnaliseEconomicaLaudo(texto: ' por ponta a cada aplicação.'),
  ]);
}

void _appendTodasIdeais(List<TrechoAnaliseEconomicaLaudo> out, int n) {
  out.addAll([
    const TrechoAnaliseEconomicaLaudo(texto: ' Todas as '),
    TrechoAnaliseEconomicaLaudo(texto: '$n', negrito: true),
    const TrechoAnaliseEconomicaLaudo(
      texto: ' pontas estão ideais, sem necessidade de ação.',
    ),
  ]);
}

void _appendReparticao(List<TrechoAnaliseEconomicaLaudo> out, EntradaAnaliseEconomicaLaudo e) {
  final clausulas = <List<TrechoAnaliseEconomicaLaudo>>[];
  if (e.qtdIdeal > 0) clausulas.add(_clausulaIdeal(e.qtdIdeal));
  if (e.qtdEntupida > 0) clausulas.add(_clausulaEntupida(e.qtdEntupida));
  if (e.qtdAtencao > 0) {
    clausulas.add(_clausulaAtencao(e.qtdAtencao, e.perdaAtencao));
  }
  if (e.qtdDesgaste > 0) {
    clausulas.add(_clausulaDesgaste(e.qtdDesgaste, e.perdaDesgaste));
  }
  if (clausulas.isEmpty) return;

  out.add(const TrechoAnaliseEconomicaLaudo(texto: ' Das '));
  out.add(TrechoAnaliseEconomicaLaudo(texto: '${e.numeroPontas}'));
  out.add(const TrechoAnaliseEconomicaLaudo(texto: ' pontas, '));

  for (var i = 0; i < clausulas.length; i++) {
    if (i > 0) {
      out.add(
        TrechoAnaliseEconomicaLaudo(
          texto: i == clausulas.length - 1 ? ', e ' : ', ',
        ),
      );
    }
    out.addAll(clausulas[i]);
  }
  out.add(const TrechoAnaliseEconomicaLaudo(texto: '.'));
}

List<TrechoAnaliseEconomicaLaudo> _clausulaIdeal(int qtd) {
  if (qtd == 1) {
    return [
      const TrechoAnaliseEconomicaLaudo(texto: '1', negrito: true),
      const TrechoAnaliseEconomicaLaudo(
        texto: ' está ideal, sem necessidade de ação',
      ),
    ];
  }
  return [
    TrechoAnaliseEconomicaLaudo(texto: '$qtd', negrito: true),
    const TrechoAnaliseEconomicaLaudo(
      texto: ' estão ideais, sem necessidade de ação',
    ),
  ];
}

List<TrechoAnaliseEconomicaLaudo> _clausulaEntupida(int qtd) {
  if (qtd == 1) {
    return [
      const TrechoAnaliseEconomicaLaudo(texto: '1', negrito: true),
      const TrechoAnaliseEconomicaLaudo(
        texto: ' está entupida e deve ser limpa e testada novamente',
      ),
    ];
  }
  return [
    TrechoAnaliseEconomicaLaudo(texto: '$qtd', negrito: true),
    const TrechoAnaliseEconomicaLaudo(
      texto: ' estão entupidas e devem ser limpas e testadas novamente',
    ),
  ];
}

List<TrechoAnaliseEconomicaLaudo> _clausulaAtencao(int qtd, double perda) {
  final moeda = formatarMoedaLaudo(perda);
  if (qtd == 1) {
    return [
      const TrechoAnaliseEconomicaLaudo(texto: '1', negrito: true),
      const TrechoAnaliseEconomicaLaudo(texto: ' está em atenção, gerando um desperdício de '),
      TrechoAnaliseEconomicaLaudo(texto: moeda, negrito: true),
      const TrechoAnaliseEconomicaLaudo(texto: ' por aplicação'),
    ];
  }
  return [
    TrechoAnaliseEconomicaLaudo(texto: '$qtd', negrito: true),
    const TrechoAnaliseEconomicaLaudo(
      texto: ' estão em atenção, gerando um desperdício de ',
    ),
    TrechoAnaliseEconomicaLaudo(texto: moeda, negrito: true),
    const TrechoAnaliseEconomicaLaudo(texto: ' por aplicação'),
  ];
}

List<TrechoAnaliseEconomicaLaudo> _clausulaDesgaste(int qtd, double perda) {
  final moeda = formatarMoedaLaudo(perda);
  if (qtd == 1) {
    return [
      const TrechoAnaliseEconomicaLaudo(texto: '1', negrito: true),
      const TrechoAnaliseEconomicaLaudo(
        texto: ' está em desgaste, gerando um prejuízo de ',
      ),
      TrechoAnaliseEconomicaLaudo(texto: moeda, negrito: true),
      const TrechoAnaliseEconomicaLaudo(texto: ' por aplicação'),
    ];
  }
  return [
    TrechoAnaliseEconomicaLaudo(texto: '$qtd', negrito: true),
    const TrechoAnaliseEconomicaLaudo(
      texto: ' estão em desgaste, gerando um prejuízo de ',
    ),
    TrechoAnaliseEconomicaLaudo(texto: moeda, negrito: true),
    const TrechoAnaliseEconomicaLaudo(texto: ' por aplicação'),
  ];
}

void _appendFechamentoSeNecessario(
  List<TrechoAnaliseEconomicaLaudo> out,
  EntradaAnaliseEconomicaLaudo e,
) {
  if (e.qtdAtencao + e.qtdDesgaste <= 0 || !e.dadosEconomicosCompletos) {
    return;
  }

  final perda = formatarMoedaLaudo(e.perdaTotal);
  final custoTotal = formatarMoedaLaudo(e.custoTrocaTotal);
  final custoParcial = formatarMoedaLaudo(e.custoTrocaDesgaste);

  out.addAll([
    const TrechoAnaliseEconomicaLaudo(
      texto: ' Somando atenção e desgaste, a perda é de ',
    ),
    TrechoAnaliseEconomicaLaudo(texto: perda, negrito: true),
    const TrechoAnaliseEconomicaLaudo(texto: ' por aplicação — '),
  ]);

  if (e.recomendarTroca) {
    out.addAll([
      const TrechoAnaliseEconomicaLaudo(
        texto: 'como isso já ultrapassa o custo de ',
      ),
      TrechoAnaliseEconomicaLaudo(texto: custoTotal, negrito: true),
      const TrechoAnaliseEconomicaLaudo(texto: ' para trocar as '),
      TrechoAnaliseEconomicaLaudo(texto: '${e.numeroPontas}', negrito: true),
      const TrechoAnaliseEconomicaLaudo(
        texto: ' pontas, compensa comprar um jogo novo de bicos.',
      ),
    ]);
    return;
  }

  out.addAll([
    const TrechoAnaliseEconomicaLaudo(
      texto: 'como isso ainda é menor que o custo de ',
    ),
    TrechoAnaliseEconomicaLaudo(texto: custoTotal, negrito: true),
    const TrechoAnaliseEconomicaLaudo(texto: ' para trocar as '),
    TrechoAnaliseEconomicaLaudo(texto: '${e.numeroPontas}', negrito: true),
    const TrechoAnaliseEconomicaLaudo(texto: ' pontas, vale trocar só '),
  ]);

  if (e.qtdDesgaste == 1) {
    out.add(const TrechoAnaliseEconomicaLaudo(texto: 'a ponta em desgaste ('));
  } else {
    out.add(const TrechoAnaliseEconomicaLaudo(texto: 'as pontas em desgaste ('));
  }
  out.add(TrechoAnaliseEconomicaLaudo(texto: custoParcial, negrito: true));
  out.add(const TrechoAnaliseEconomicaLaudo(texto: ')'));

  if (e.qtdAtencao > 0) {
    out.add(const TrechoAnaliseEconomicaLaudo(
      texto: ' e continuar monitorando as em atenção.',
    ));
  } else {
    out.add(const TrechoAnaliseEconomicaLaudo(texto: '.'));
  }
}

/// Texto corrido para testes (sem marcação de negrito).
String analiseEconomicaLaudoComoTexto(ParagrafoAnaliseEconomicaLaudo trechos) {
  return trechos.map((t) => t.texto).join();
}
