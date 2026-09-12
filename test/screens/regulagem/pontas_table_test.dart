import 'package:agrocalc/models/configuracoes.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:agrocalc/screens/regulagem/widgets/pontas_table.dart';
import 'package:agrocalc/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final medicoes = [
    const PontaMedicao(id: 1, valorMedido: 0.825, status: StatusPonta.ideal),
    const PontaMedicao(id: 2, valorMedido: null, status: StatusPonta.pendente),
    const PontaMedicao(id: 3, valorMedido: 0.92, status: StatusPonta.irregular),
  ];

  Future<void> pumpTable(
    WidgetTester tester, {
    VoidCallback? onMoved,
    ValueChanged<PontaInput>? onChanged,
  }) {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PontasTable(
              medicoes: medicoes,
              ideal: 0.825,
              configuracoes: const Configuracoes(),
              manejo: 0,
              precoBico: 0,
              area: 0,
              readonly: false,
              onMedicaoChanged: onChanged ?? (_) {},
              onMovedToNextPonta: onMoved,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('lista de pontas usa ExpansionPanelList.radio', (tester) async {
    await pumpTable(tester);

    expect(find.byType(ExpansionPanelList), findsOneWidget);
    expect(find.text('Ponta 1'), findsOneWidget);
    expect(find.text('Ponta 2'), findsOneWidget);
    expect(find.text('Ponta 3'), findsOneWidget);
    expect(find.text('0.825 L/min'), findsWidgets);
    expect(find.text('Sem medição'), findsOneWidget);
  });

  testWidgets('abre a primeira ponta pendente com o campo L/min',
      (tester) async {
    await pumpTable(tester);
    await tester.pumpAndSettle();

    expect(find.text('L/min medido'), findsWidgets);
    expect(find.text('Ideal: 0.825 L/min'), findsWidgets);
  });

  testWidgets('passar para a ponta de baixo dispara auto-save', (tester) async {
    var moved = 0;
    await pumpTable(tester, onMoved: () => moved++);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Ponta 3'));
    await tester.tap(find.text('Ponta 3'));
    await tester.pumpAndSettle();

    expect(moved, greaterThan(0));
  });
}
