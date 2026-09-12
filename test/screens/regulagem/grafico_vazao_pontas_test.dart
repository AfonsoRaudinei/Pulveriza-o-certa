import 'package:agrocalc/core/charts/vazao_chart_data.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:agrocalc/screens/regulagem/widgets/grafico_vazao_pontas.dart';
import 'package:agrocalc/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _medicoes = [
  PontaMedicao(id: 1, valorMedido: 0.82, status: StatusPonta.ideal),
  PontaMedicao(id: 2, valorMedido: 0.75, status: StatusPonta.irregular),
  PontaMedicao(id: 3, valorMedido: 0.92, status: StatusPonta.desgaste),
  PontaMedicao(id: 4, valorMedido: null, status: StatusPonta.pendente),
];

Future<void> _pump(
  WidgetTester tester, {
  required List<PontaMedicao> medicoes,
  double ideal = 0.825,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: GraficoVazaoPontas(
          data: VazaoChartData.from(
            medicoes: medicoes,
            litroMinIdeal: ideal,
            limiteIrregular: 92,
            limiteDesgaste: 105,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('mostra título, referência do ideal e legenda por status',
      (tester) async {
    await _pump(tester, medicoes: _medicoes);

    expect(find.text('Vazão por ponta'), findsOneWidget);
    expect(
      find.text(
        'Cada barra parte do ideal (0.825 L/min). '
        'A faixa verde é o aceitável (92–105%).',
      ),
      findsOneWidget,
    );
    expect(find.text('Ideal'), findsOneWidget);
    expect(find.text('Entupido'), findsOneWidget);
    expect(find.text('Desgaste'), findsOneWidget);
    expect(find.text('Sem medição'), findsOneWidget);
  });

  testWidgets('legenda esconde status ausentes e o item de pendente',
      (tester) async {
    await _pump(
      tester,
      medicoes: const [
        PontaMedicao(id: 1, valorMedido: 0.82, status: StatusPonta.ideal),
      ],
    );

    expect(find.text('Ideal'), findsOneWidget);
    expect(find.text('Entupido'), findsNothing);
    expect(find.text('Desgaste'), findsNothing);
    expect(find.text('Sem medição'), findsNothing);
  });

  testWidgets('sem ideal ou sem medições não desenha nada', (tester) async {
    await _pump(tester, medicoes: _medicoes, ideal: 0);
    expect(find.text('Vazão por ponta'), findsNothing);

    await _pump(
      tester,
      medicoes: const [
        PontaMedicao(id: 1, valorMedido: null, status: StatusPonta.pendente),
      ],
    );
    expect(find.text('Vazão por ponta'), findsNothing);
  });

  testWidgets('desenha sem estourar layout com barra cheia de pontas',
      (tester) async {
    await _pump(
      tester,
      medicoes: [
        for (var i = 1; i <= 32; i++)
          PontaMedicao(
            id: i,
            valorMedido: 0.7 + (i % 9) * 0.03,
            status: StatusPonta.ideal,
          ),
      ],
    );

    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
