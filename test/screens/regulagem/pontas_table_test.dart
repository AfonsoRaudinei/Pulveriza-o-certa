import 'package:agrocalc/models/configuracoes.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:agrocalc/screens/regulagem/widgets/pontas_table.dart';
import 'package:agrocalc/theme.dart';
import 'package:agrocalc/widgets/card_zona_atencao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });
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

  testWidgets('Zona de Atenção aparece abaixo do resumo só na faixa 100–105',
      (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PontasTable(
              medicoes: const [
                PontaMedicao(
                    id: 1, valorMedido: 0.84975, status: StatusPonta.ideal),
                PontaMedicao(
                    id: 2, valorMedido: 0.891, status: StatusPonta.desgaste),
              ],
              ideal: 0.825,
              configuracoes: const Configuracoes(),
              manejo: 2400,
              precoBico: 35,
              area: 500,
              readonly: true,
              onMedicaoChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CardZonaAtencao), findsOneWidget);
    expect(find.text('Zona de Atenção'), findsOneWidget);
    expect(find.text('Desgaste'), findsOneWidget);
    expect(find.text('Perda por desgaste'), findsOneWidget);
  });
}
