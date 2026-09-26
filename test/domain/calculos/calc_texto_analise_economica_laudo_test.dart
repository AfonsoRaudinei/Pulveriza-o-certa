import 'package:agrocalc/domain/calculos/calc_texto_analise_economica_laudo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exemplo 1 — um parágrafo (10 pontas, troca completa)', () {
    final texto = analiseEconomicaLaudoComoTexto(
      montarAnaliseEconomicaLaudoDe(
        const EntradaAnaliseEconomicaLaudo(
          numeroPontas: 10,
          manejoHa: 600,
          manejoPonta: 60,
          qtdIdeal: 2,
          qtdEntupida: 3,
          qtdAtencao: 3,
          qtdDesgaste: 2,
          perdaAtencao: 199.13,
          perdaDesgaste: 247.50,
          perdaTotal: 446.62,
          custoTrocaTotal: 300,
          custoTrocaDesgaste: 60,
          recomendarTroca: true,
          dadosEconomicosCompletos: true,
        ),
      ),
    );

    expect(
      texto,
      'Trabalhamos com 10 pontas nesta barra. O manejo custa R\$ 600,00 por '
      'hectare, o que dá R\$ 60,00 por ponta a cada aplicação. Das 10 pontas, '
      '2 estão ideais, sem necessidade de ação, 3 estão entupidas e devem ser '
      'limpas e testadas novamente, 3 estão em atenção, gerando um desperdício '
      'de R\$ 199,13 por aplicação, e 2 estão em desgaste, gerando um prejuízo '
      'de R\$ 247,50 por aplicação. Somando atenção e desgaste, a perda é de '
      'R\$ 446,62 por aplicação — como isso já ultrapassa o custo de R\$ 300,00 '
      'para trocar as 10 pontas, compensa comprar um jogo novo de bicos.',
    );
    expect(texto, isNot(contains('\n\n')));
    expect(texto, isNot(contains('payback')));
  });

  test('exemplo 2 — 60 pontas, sem atenção no fechamento', () {
    final texto = analiseEconomicaLaudoComoTexto(
      montarAnaliseEconomicaLaudoDe(
        const EntradaAnaliseEconomicaLaudo(
          numeroPontas: 60,
          manejoHa: 600,
          manejoPonta: 10,
          qtdIdeal: 58,
          qtdEntupida: 1,
          qtdAtencao: 0,
          qtdDesgaste: 1,
          perdaAtencao: 0,
          perdaDesgaste: 45,
          perdaTotal: 45,
          custoTrocaTotal: 1800,
          custoTrocaDesgaste: 30,
          recomendarTroca: false,
          dadosEconomicosCompletos: true,
        ),
      ),
    );

    expect(
      texto,
      'Trabalhamos com 60 pontas nesta barra. O manejo custa R\$ 600,00 por '
      'hectare, o que dá R\$ 10,00 por ponta a cada aplicação. Das 60 pontas, '
      '58 estão ideais, sem necessidade de ação, 1 está entupida e deve ser '
      'limpa e testada novamente, e 1 está em desgaste, gerando um prejuízo de '
      'R\$ 45,00 por aplicação. Somando atenção e desgaste, a perda é de '
      'R\$ 45,00 por aplicação — como isso ainda é menor que o custo de '
      'R\$ 1.800,00 para trocar as 60 pontas, vale trocar só a ponta em '
      'desgaste (R\$ 30,00).',
    );
    expect(texto, isNot(contains('monitorando as em atenção')));
  });

  test('exemplo 3 — todas ideais', () {
    final texto = analiseEconomicaLaudoComoTexto(
      montarAnaliseEconomicaLaudoDe(
        const EntradaAnaliseEconomicaLaudo(
          numeroPontas: 10,
          manejoHa: 600,
          manejoPonta: 60,
          qtdIdeal: 10,
          qtdEntupida: 0,
          qtdAtencao: 0,
          qtdDesgaste: 0,
          perdaAtencao: 0,
          perdaDesgaste: 0,
          perdaTotal: 0,
          custoTrocaTotal: 300,
          custoTrocaDesgaste: 0,
          recomendarTroca: false,
          dadosEconomicosCompletos: true,
        ),
      ),
    );

    expect(
      texto,
      'Trabalhamos com 10 pontas nesta barra. O manejo custa R\$ 600,00 por '
      'hectare, o que dá R\$ 60,00 por ponta a cada aplicação. Todas as 10 '
      'pontas estão ideais, sem necessidade de ação.',
    );
  });

  test('ideal + entupida sem perda financeira — sem fechamento de troca', () {
    final texto = analiseEconomicaLaudoComoTexto(
      montarAnaliseEconomicaLaudoDe(
        const EntradaAnaliseEconomicaLaudo(
          numeroPontas: 5,
          manejoHa: 100,
          manejoPonta: 20,
          qtdIdeal: 4,
          qtdEntupida: 1,
          qtdAtencao: 0,
          qtdDesgaste: 0,
          perdaAtencao: 0,
          perdaDesgaste: 0,
          perdaTotal: 0,
          custoTrocaTotal: 150,
          custoTrocaDesgaste: 0,
          recomendarTroca: false,
          dadosEconomicosCompletos: true,
        ),
      ),
    );

    expect(texto, contains('Das 5 pontas,'));
    expect(texto, isNot(contains('Somando atenção e desgaste')));
  });
}
