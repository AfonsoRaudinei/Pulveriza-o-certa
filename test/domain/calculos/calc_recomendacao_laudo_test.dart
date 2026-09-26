import 'package:agrocalc/domain/calculos/calc_diagnostico_regulagem.dart';
import 'package:agrocalc/domain/calculos/calc_litro_min_ideal.dart';
import 'package:agrocalc/domain/calculos/calc_recomendacao_laudo.dart';
import 'package:agrocalc/domain/calculos/limites_regulagem.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:flutter_test/flutter_test.dart';

const _medidasNova4 = [
  0.550,
  0.530,
  0.490,
  0.530,
  0.570,
  0.570,
  0.559,
  0.550,
  0.500,
  0.510,
];

DiagnosticoRegulagem _diagnosticoNova4({double precoBico = 30}) {
  final ideal = calcularLitroMinIdeal(
    vazaoLha: 80,
    velocidade: 8,
    espacamentoCm: 50,
  );
  return DiagnosticoRegulagem.calcular(
    medicoes: [
      for (var i = 0; i < _medidasNova4.length; i++)
        PontaMedicao(
          id: i + 1,
          valorMedido: _medidasNova4[i],
          status: StatusPonta.pendente,
        ),
    ],
    litroMinIdeal: ideal,
    limites: LimitesRegulagem.padrao,
    lado: LadoConferenciaPontas.direita,
    manejoRS: 600,
    precoBicoRS: precoBico,
    areaHa: 30,
  );
}

void main() {
  group('prejuizoLaudoParaExibicao', () {
    test('soma exibida bate com total (Nova4)', () {
      final ex = prejuizoLaudoParaExibicao(
        prejuizoDesgaste: 247.5,
        prejuizoAtencao: 199.13,
      );
      expect(ex.desgaste, closeTo(247.50, 0.001));
      expect(ex.atencao, closeTo(199.13, 0.001));
      expect(ex.total, closeTo(446.63, 0.001));
      expect(ex.desgaste + ex.atencao, closeTo(ex.total, 0.001));
    });
  });

  test('(a) laudo Nova4 → troca completa', () {
    final d = _diagnosticoNova4(precoBico: 30);
    expect(d.planoLaudo.tipo, TipoRecomendacaoLaudo.completa);
    expect(d.planoLaudo.trocaTodosOsBicos, isTrue);
    expect(d.planoLaudo.custoTrocaRecomendada, closeTo(300, 0.01));
    expect(d.planoLaudo.prejuizoResidual, 0);
    expect(d.planoLaudo.exibicao.total, closeTo(446.63, 0.01));
    expect(d.recomendacao.tipo, TipoRecomendacao.trocaCompleta);
    expect(aplicacoesParaSePagarArredondadas(d.planoLaudo.aplicacoesParaSePagar), 1);
  });

  test('(b) Nova4 com bico R\$ 50 → troca unitária 5D e 6D', () {
    final d = _diagnosticoNova4(precoBico: 50);
    expect(d.planoLaudo.tipo, TipoRecomendacaoLaudo.unitaria);
    expect(d.planoLaudo.acoes.trocar, ['5D', '6D']);
    expect(d.planoLaudo.custoTrocaRecomendada, closeTo(100, 0.01));
    expect(d.planoLaudo.prejuizoResidual, closeTo(d.perdaAtencao, 0.01));
    expect(d.planoLaudo.custoTrocaCompleta, closeTo(500, 0.01));
    expect(d.recomendacao.tipo, TipoRecomendacao.trocarDesgasteMonitorarAtencao);
  });

  test('(c) sem desgaste → nenhuma troca', () {
    final ideal = calcularLitroMinIdeal(
      vazaoLha: 80,
      velocidade: 8,
      espacamentoCm: 50,
    );
    final d = DiagnosticoRegulagem.calcular(
      medicoes: const [
        PontaMedicao(id: 1, valorMedido: 0.55, status: StatusPonta.pendente),
        PontaMedicao(id: 2, valorMedido: 0.54, status: StatusPonta.pendente),
      ],
      litroMinIdeal: ideal,
      limites: LimitesRegulagem.padrao,
      lado: LadoConferenciaPontas.direita,
      manejoRS: 600,
      precoBicoRS: 30,
      areaHa: 30,
    );
    expect(d.desgaste, isNull);
    expect(d.planoLaudo.tipo, TipoRecomendacaoLaudo.nenhuma);
    expect(d.planoLaudo.custoTrocaRecomendada, 0);
    expect(d.planoLaudo.acoes.trocar, isEmpty);
  });

  test('(d) custo igual ao prejuízo → unitária', () {
    final d = _diagnosticoNova4();
    final precoIgual = d.perdaTotal / d.totalPontas;
    final d2 = _diagnosticoNova4(precoBico: precoIgual);
    expect(d2.planoLaudo.tipo, TipoRecomendacaoLaudo.unitaria);
    expect(
      d2.planoLaudo.custoTrocaCompleta,
      closeTo(d2.perdaTotal, 0.02),
    );
  });

  test('(e) dados incompletos e pontas pendentes', () {
    final plano = calcularRecomendacaoLaudo(
      rotulosDesgaste: const ['5D'],
      rotulosEntupida: const [],
      rotulosAtencao: const [],
      prejuizoDesgaste: 100,
      prejuizoAtencao: 0,
      precoBicoRS: 0,
      numeroPontas: 10,
      manejoRS: 600,
      areaHa: 30,
    );
    expect(plano.tipo, TipoRecomendacaoLaudo.dadosIncompletos);
    expect(plano.aplicacoesParaSePagar, isNull);

    final ideal = 0.5333;
    final parcial = DiagnosticoRegulagem.calcular(
      medicoes: const [
        PontaMedicao(id: 1, valorMedido: 0.57, status: StatusPonta.pendente),
        PontaMedicao(id: 2, valorMedido: null, status: StatusPonta.pendente),
      ],
      litroMinIdeal: ideal,
      limites: LimitesRegulagem.padrao,
      lado: LadoConferenciaPontas.direita,
      manejoRS: 600,
      precoBicoRS: 30,
      areaHa: 30,
    );
    expect(parcial.analiseParcial, isTrue);
    expect(parcial.planoLaudo.quantidadeDesgaste, 1);
  });
}
