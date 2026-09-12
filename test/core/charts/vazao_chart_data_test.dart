import 'package:agrocalc/core/charts/vazao_chart_data.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:flutter_test/flutter_test.dart';

VazaoChartData _chart(
  List<PontaMedicao> medicoes, {
  double ideal = 1.0,
  double limiteIrregular = 92,
  double limiteDesgaste = 105,
}) {
  return VazaoChartData.from(
    medicoes: medicoes,
    litroMinIdeal: ideal,
    limiteIrregular: limiteIrregular,
    limiteDesgaste: limiteDesgaste,
  );
}

void main() {
  test('ponta sem medição fica sem percentual', () {
    final chart = _chart(const [
      PontaMedicao(id: 1, valorMedido: 1.0, status: StatusPonta.ideal),
      PontaMedicao(id: 2, valorMedido: null, status: StatusPonta.pendente),
    ]);

    expect(chart.pontas[0].percentual, closeTo(100, 0.01));
    expect(chart.pontas[0].medida, isTrue);
    expect(chart.pontas[1].percentual, isNull);
    expect(chart.pontas[1].medida, isFalse);
    expect(chart.temPendente, isTrue);
  });

  test('janela do eixo contém a faixa inteira mesmo com tudo dentro dela', () {
    final chart = _chart(const [
      PontaMedicao(id: 1, valorMedido: 1.0, status: StatusPonta.ideal),
      PontaMedicao(id: 2, valorMedido: 1.01, status: StatusPonta.ideal),
    ]);

    expect(chart.minPercent, lessThan(92));
    expect(chart.maxPercent, greaterThan(105));
  });

  test('janela do eixo se abre para valores fora da faixa', () {
    final chart = _chart(const [
      PontaMedicao(id: 1, valorMedido: 1.2, status: StatusPonta.desgaste),
      PontaMedicao(id: 2, valorMedido: 0.85, status: StatusPonta.irregular),
    ]);

    expect(chart.minPercent, lessThan(85));
    expect(chart.maxPercent, greaterThan(120));
  });

  test('amplitude respeita o alcance máximo e corta a barra no piso', () {
    final chart = _chart(const [
      PontaMedicao(id: 1, valorMedido: 0.05, status: StatusPonta.irregular),
      PontaMedicao(id: 2, valorMedido: 1.1, status: StatusPonta.desgaste),
    ]);

    expect(chart.amplitude, closeTo(VazaoChartData.alcanceMaximo, 0.01));
    expect(chart.percentualNoEixo(5), chart.minPercent);
    expect(chart.percentualNoEixo(110), closeTo(110, 0.01));
  });

  test('vazio sem ideal ou sem nenhuma medição', () {
    expect(
      _chart(
        const [PontaMedicao(id: 1, valorMedido: 1, status: StatusPonta.ideal)],
        ideal: 0,
      ).vazio,
      isTrue,
    );
    expect(
      _chart(const [
        PontaMedicao(id: 1, valorMedido: null, status: StatusPonta.pendente),
      ]).vazio,
      isTrue,
    );
    expect(_chart(const []).vazio, isTrue);
  });

  test('statusMedidos segue ideal, entupido, desgaste e ignora pendente', () {
    final chart = _chart(const [
      PontaMedicao(id: 1, valorMedido: 1.2, status: StatusPonta.desgaste),
      PontaMedicao(id: 2, valorMedido: 0.85, status: StatusPonta.irregular),
      PontaMedicao(id: 3, valorMedido: 1.0, status: StatusPonta.ideal),
      PontaMedicao(id: 4, valorMedido: null, status: StatusPonta.pendente),
    ]);

    expect(chart.statusMedidos, [
      StatusPonta.ideal,
      StatusPonta.irregular,
      StatusPonta.desgaste,
    ]);
  });

  test('rotuloStatusPonta cobre os quatro status', () {
    expect(rotuloStatusPonta(StatusPonta.ideal), 'Ideal');
    expect(rotuloStatusPonta(StatusPonta.irregular), 'Entupido');
    expect(rotuloStatusPonta(StatusPonta.desgaste), 'Desgaste');
    expect(rotuloStatusPonta(StatusPonta.pendente), 'Sem medição');
  });

  test('subtituloGraficoVazao descreve ideal e faixa', () {
    final chart = _chart(const [
      PontaMedicao(id: 1, valorMedido: 1.0, status: StatusPonta.ideal),
    ]);
    expect(
      subtituloGraficoVazao(chart),
      'Cada barra parte do ideal (1.000 L/min). '
      'A faixa verde é o aceitável (92–105%).',
    );
  });

  test('canvas compacto com poucas pontas e cabe na página quando são muitas',
      () {
    expect(
      VazaoChartLayout.canvasWidthFor(4, maxAvailable: 500),
      VazaoChartLayout.leftPad +
          4 * VazaoChartLayout.maxSlot +
          VazaoChartLayout.rightPad,
    );
    expect(
      VazaoChartLayout.canvasWidthFor(32,
          maxAvailable: 400, podeEstourar: false),
      400,
    );
    expect(
      VazaoChartLayout.canvasWidthFor(32, maxAvailable: 400),
      greaterThan(400),
    );
  });
}
