import 'package:agrocalc/screens/regulagem/widgets/etapa_resumo.dart';
import 'package:agrocalc/screens/regulagem/widgets/progressive_card.dart';
import 'package:agrocalc/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required bool locked,
    bool complete = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProgressiveCard(
            index: 1,
            title: 'Contexto da Operação',
            locked: locked,
            complete: complete,
            child: const Text('corpo-contexto'),
          ),
        ),
      ),
    );
  }

  testWidgets('etapa ativa usa ExpansionTile e começa aberta', (tester) async {
    await pumpCard(tester, locked: false);

    expect(find.byType(ExpansionTile), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('corpo-contexto'), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
  });

  testWidgets('editar regulagem começa recolhida com resumo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProgressiveCard(
            index: 1,
            title: 'Contexto da Operação',
            locked: false,
            complete: true,
            startExpanded: false,
            summary: EtapaResumo(
              linhas: const [EtapaResumoLinha('Produtor', 'João')],
            ),
            child: const Text('corpo-contexto'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('corpo-contexto'), findsNothing);
    expect(find.text('João'), findsOneWidget);
    expect(find.text('Produtor'), findsOneWidget);
  });

  testWidgets('etapa bloqueada começa recolhida e ignora toque',
      (tester) async {
    await pumpCard(tester, locked: true);

    expect(find.byType(ExpansionTile), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.text('corpo-contexto'), findsNothing);
  });

  testWidgets('completar e desbloquear abre a etapa sozinha', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: _UnlockHarness(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('corpo-parametros'), findsNothing);

    await tester.tap(find.text('desbloquear'));
    await tester.pumpAndSettle();

    expect(find.text('corpo-parametros'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });

  testWidgets('chevron recolhe o corpo da etapa completa', (tester) async {
    await pumpCard(tester, locked: false, complete: true);
    expect(find.text('corpo-contexto'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('Contexto da Operação'));
    await tester.pumpAndSettle();
    expect(find.text('corpo-contexto'), findsNothing);
  });

  testWidgets('recolher mostra ficha só com preenchidos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProgressiveCard(
            index: 1,
            title: 'Contexto da Operação',
            locked: false,
            complete: true,
            summary: EtapaResumo.ouNulo(const [
              EtapaResumoLinha('Fazenda', 'Boa Vista'),
              EtapaResumoLinha('Talhão', ''),
            ]),
            child: const Text('corpo-contexto'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('corpo-contexto'), findsOneWidget);
    expect(find.text('Boa Vista'), findsNothing);

    await tester.tap(find.text('Contexto da Operação'));
    await tester.pumpAndSettle();

    expect(find.text('corpo-contexto'), findsNothing);
    expect(find.text('Fazenda'), findsOneWidget);
    expect(find.text('Boa Vista'), findsOneWidget);
    expect(find.text('Talhão'), findsNothing);
  });

  testWidgets('Contexto pode ocultar o check verde quando completa',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProgressiveCard(
            index: 1,
            title: 'Contexto da Operação',
            locked: false,
            complete: true,
            showCompletedMarker: false,
            child: const Text('corpo-contexto'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.text('corpo-contexto'), findsOneWidget);
  });

  testWidgets('pode ocultar o check verde quando a etapa está completa',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProgressiveCard(
            index: 2,
            title: 'Parâmetros da Máquina',
            locked: false,
            complete: true,
            showCompletedMarker: false,
            child: const Text('corpo-parametros'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.text('corpo-parametros'), findsOneWidget);
  });

  testWidgets('corpo pequeno não estica ao expandir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ListView(
            children: [
              ProgressiveCard(
                index: 3,
                title: 'Vazão / ha',
                locked: false,
                complete: true,
                showCompletedMarker: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Lt/min Ideal'),
                    TextField(decoration: InputDecoration(labelText: 'Limite')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tileFinder = find.byType(ExpansionTile);
    final tileBox = tester.getSize(tileFinder);
    expect(tileBox.height, lessThan(400));
  });

  testWidgets('etapa bloqueada não mostra a ficha', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProgressiveCard(
            index: 2,
            title: 'Parâmetros da Máquina',
            locked: true,
            complete: false,
            summary: EtapaResumo.ouNulo(const [
              EtapaResumoLinha('Fazenda', 'Boa Vista'),
            ]),
            child: const Text('corpo-parametros'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Boa Vista'), findsNothing);
    expect(find.text('corpo-parametros'), findsNothing);
  });
}

class _UnlockHarness extends StatefulWidget {
  const _UnlockHarness();

  @override
  State<_UnlockHarness> createState() => _UnlockHarnessState();
}

class _UnlockHarnessState extends State<_UnlockHarness> {
  bool _locked = true;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        body: Column(
          children: [
            TextButton(
              onPressed: () => setState(() => _locked = false),
              child: const Text('desbloquear'),
            ),
            ProgressiveCard(
              index: 2,
              title: 'Parâmetros da Máquina',
              locked: _locked,
              complete: false,
              child: const Text('corpo-parametros'),
            ),
          ],
        ),
      ),
    );
  }
}
