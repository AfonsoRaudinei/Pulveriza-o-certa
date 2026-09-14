import 'package:agrocalc/models/configuracoes.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:agrocalc/screens/regulagem/widgets/grafico_vazao_pontas.dart';
import 'package:agrocalc/screens/regulagem/widgets/medicoes_resumo_card.dart';
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
              ladoConferencia: LadoConferenciaPontas.direita,
              readonly: false,
              onMedicaoChanged: onChanged ?? (_) {},
              onMovedToNextPonta: onMoved,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('lista de pontas sem ExpansionPanelList nem chevron de painel',
      (tester) async {
    await pumpTable(tester);
    await tester.pumpAndSettle();

    expect(find.byType(ExpansionPanelList), findsNothing);
    expect(find.text('Ponta 1'), findsNothing);
    expect(find.textContaining('1D · 0.825 L/min'), findsOneWidget);
    expect(find.textContaining('2D · Sem medição'), findsOneWidget);
  });

  testWidgets('lista começa fechada; toque na linha abre o campo L/min',
      (tester) async {
    await pumpTable(tester);
    await tester.pumpAndSettle();

    expect(find.text('L/min medido'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('ponta-row-2')));
    await tester.pumpAndSettle();

    expect(find.text('2D · L/min medido'), findsOneWidget);
    expect(find.text('Ideal: 0.825 L/min'), findsOneWidget);
  });

  testWidgets('toggle Esquerda renomeia pontas para 1E, 2E…', (tester) async {
    LadoConferenciaPontas? lado;
    await tester.pumpWidget(
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
              ladoConferencia: LadoConferenciaPontas.esquerda,
              readonly: false,
              onMedicaoChanged: (_) {},
              onLadoConferenciaChanged: (value) => lado = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('1E · 0.825 L/min'), findsOneWidget);
    expect(find.textContaining('2E · Sem medição'), findsOneWidget);

    await tester.tap(find.text('Direita'));
    await tester.pumpAndSettle();
    expect(lado, LadoConferenciaPontas.direita);

    lado = LadoConferenciaPontas.esquerda;
    await tester.pumpWidget(
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
              ladoConferencia: LadoConferenciaPontas.esquerda,
              readonly: false,
              exigirConfirmacaoTrocaLado: true,
              onMedicaoChanged: (_) {},
              onLadoConferenciaChanged: (value) => lado = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Direita'));
    await tester.pumpAndSettle();
    expect(find.text('Alterar lado da conferência?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(lado, LadoConferenciaPontas.esquerda);

    await tester.tap(find.text('Direita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(lado, LadoConferenciaPontas.direita);
  });

  testWidgets('passar para a ponta de baixo dispara auto-save', (tester) async {
    var moved = 0;
    await pumpTable(tester, onMoved: () => moved++);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ponta-row-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ponta-row-3')));
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
              ladoConferencia: LadoConferenciaPontas.direita,
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
    expect(
      find.descendant(
        of: find.byType(MedicoesResumoCard),
        matching: find.text('Desgaste'),
      ),
      findsOneWidget,
    );
    expect(find.text('Perda por Desgaste'), findsNothing);
  });

  testWidgets('gráfico não fica dentro da tabela de pontas', (tester) async {
    await pumpTable(tester);
    await tester.pumpAndSettle();

    expect(find.byType(GraficoVazaoPontas), findsNothing);
    expect(find.text('Vazão por ponta'), findsNothing);
  });

  testWidgets('PontasAnaliseSection mostra gráfico e análise fora da lista',
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
            child: PontasAnaliseSection(
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
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GraficoVazaoPontas), findsOneWidget);
    expect(find.text('Vazão por ponta'), findsOneWidget);
    expect(find.text('Perda por Desgaste'), findsOneWidget);
    expect(find.text('Perda Total Estimada'), findsOneWidget);
    expect(find.text('Análise econômica'), findsOneWidget);
    expect(find.text('Orientações'), findsOneWidget);
  });

  testWidgets('toque fora do painel fecha a edição e dispara auto-save',
      (tester) async {
    var moved = 0;
    await pumpTable(tester, onMoved: () => moved++);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ponta-row-2')));
    await tester.pumpAndSettle();
    expect(find.text('2D · L/min medido'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.text('L/min medido'), findsNothing);
    expect(moved, greaterThan(0));
  });

  testWidgets('ponta com 0 L/min não vira Sem medição', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
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
                  id: 1,
                  valorMedido: 0,
                  status: StatusPonta.irregular,
                ),
              ],
              ideal: 0.825,
              configuracoes: const Configuracoes(),
              manejo: 0,
              precoBico: 0,
              area: 0,
              ladoConferencia: LadoConferenciaPontas.direita,
              readonly: true,
              onMedicaoChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('1D · 0.000 L/min'), findsOneWidget);
    expect(find.textContaining('0.0%'), findsOneWidget);
    expect(find.text('Sem medição'), findsNothing);
  });
}
