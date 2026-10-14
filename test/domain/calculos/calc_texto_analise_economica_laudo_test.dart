import 'package:agrocalc/domain/calculos/calc_texto_analise_economica_laudo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exemplo 1 — blocos (10 pontas, troca completa)', () {
    final blocos = montarBlocosAnaliseEconomicaLaudoDe(
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
        perdaPorAplicacao: 446.62,
        numeroAplicacoes: 1,
        custoTrocaTotal: 300,
        custoTrocaDesgaste: 60,
        recomendarTroca: true,
        dadosEconomicosCompletos: true,
      ),
    );

    expect(blocos.destaquePerda, 'Perda estimada na safra: R\$ 446,62');
    expect(blocos.bullets.length, 2);
    expect(
      blocos.bullets.first,
      'Barra com 10 pontas. Cada ponta custa R\$ 60,00 em produto por aplicação.',
    );
    expect(
      blocos.bullets[1],
      '2 em desgaste (R\$ 247,50), 3 em atenção (R\$ 199,13), '
      '3 entupidas e 2 no ideal.',
    );
    expect(
      analiseEconomicaLaudoComoTexto(blocos),
      contains('Essa perda já passa o custo de trocar todos os bicos'),
    );
    expect(analiseEconomicaLaudoComoTexto(blocos), contains('R\$ 300,00'));
    expect(analiseEconomicaLaudoComoTexto(blocos), isNot(contains('payback')));
  });

  test('multiplica perda por número de aplicações na safra', () {
    final blocos = montarBlocosAnaliseEconomicaLaudoDe(
      const EntradaAnaliseEconomicaLaudo(
        numeroPontas: 10,
        manejoHa: 600,
        manejoPonta: 60,
        qtdIdeal: 2,
        qtdEntupida: 0,
        qtdAtencao: 3,
        qtdDesgaste: 2,
        perdaAtencao: 199.13,
        perdaDesgaste: 247.50,
        perdaPorAplicacao: 446.62,
        numeroAplicacoes: 5,
        tipoPonta: 'Cônica',
        custoTrocaTotal: 300,
        custoTrocaDesgaste: 60,
        recomendarTroca: true,
        dadosEconomicosCompletos: true,
      ),
    );

    expect(blocos.perdaTotal, closeTo(446.62 * 5, 0.01));
    expect(blocos.destaquePerda, 'Perda estimada na safra: R\$ 2.233,10');
    expect(blocos.bullets.length, 3);
    expect(
      blocos.bullets[1],
      '2 em desgaste (R\$ 1.237,50), 3 em atenção (R\$ 995,65), '
      '0 entupidas e 2 no ideal.',
    );
    expect(
      blocos.bullets.last,
      'R\$ 446,62 por aplicação × 5 aplicações na safra · ponta Cônica.',
    );
  });

  test('exemplo 2 — 60 pontas, troca ponta a ponta', () {
    final blocos = montarBlocosAnaliseEconomicaLaudoDe(
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
        perdaPorAplicacao: 45,
        numeroAplicacoes: 1,
        custoTrocaTotal: 1800,
        custoTrocaDesgaste: 30,
        recomendarTroca: false,
        dadosEconomicosCompletos: true,
      ),
    );

    expect(blocos.bullets[1], contains('1 entupida'));
    expect(
      analiseEconomicaLaudoComoTexto(blocos),
      contains('Vale trocar só as pontas em desgaste'),
    );
    expect(
      analiseEconomicaLaudoComoTexto(blocos),
      isNot(contains('Essa perda já passa')),
    );
  });

  test('exemplo 3 — todas ideais', () {
    final blocos = montarBlocosAnaliseEconomicaLaudoDe(
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
        perdaPorAplicacao: 0,
        numeroAplicacoes: 1,
        custoTrocaTotal: 300,
        custoTrocaDesgaste: 0,
        recomendarTroca: false,
        dadosEconomicosCompletos: true,
      ),
    );

    expect(blocos.perdaTotal, 0);
    expect(blocos.destaquePerda, 'Perda estimada na safra: R\$ 0,00');
    expect(blocos.fechamento, isEmpty);
    expect(blocos.bullets[1], endsWith('10 no ideal.'));
  });

  test('dados econômicos incompletos sem manejo', () {
    final blocos = montarBlocosAnaliseEconomicaLaudoDe(
      const EntradaAnaliseEconomicaLaudo(
        numeroPontas: 10,
        manejoHa: 0,
        manejoPonta: 0,
        qtdIdeal: 10,
        qtdEntupida: 0,
        qtdAtencao: 0,
        qtdDesgaste: 0,
        perdaAtencao: 0,
        perdaDesgaste: 0,
        perdaPorAplicacao: 0,
        numeroAplicacoes: 1,
        custoTrocaTotal: 0,
        custoTrocaDesgaste: 0,
        recomendarTroca: false,
        dadosEconomicosCompletos: false,
      ),
    );

    expect(blocos.mensagemIncompleta, isNotNull);
    expect(
      analiseEconomicaLaudoComoTexto(blocos),
      contains('Informe manejo'),
    );
  });
}
