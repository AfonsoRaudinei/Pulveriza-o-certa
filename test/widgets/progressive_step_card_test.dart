import 'package:agrocalc/theme.dart';
import 'package:agrocalc/widgets/progressive_step_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Finder cardIgnore() {
    return find.descendant(
      of: find.byType(ProgressiveStepCard),
      matching: find.byType(IgnorePointer),
    );
  }

  Finder cardOpacity() {
    return find.descendant(
      of: find.byType(ProgressiveStepCard),
      matching: find.byType(AnimatedOpacity),
    );
  }

  Future<void> pumpCard(WidgetTester tester, {required StepStatus status}) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProgressiveStepCard(
            stepNumber: 2,
            title: 'Produtos & Dose',
            description: 'Adicione ao menos um produto',
            status: status,
            child: const Text('corpo-etapa'),
          ),
        ),
      ),
    );
  }

  testWidgets('ativo mostra número e permite interação', (tester) async {
    await pumpCard(tester, status: StepStatus.active);

    expect(find.text('2'), findsOneWidget);
    expect(find.text('Produtos & Dose'), findsOneWidget);
    expect(find.text('corpo-etapa'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(tester.widget<IgnorePointer>(cardIgnore()).ignoring, isFalse);
  });

  testWidgets('bloqueado mostra cadeado e ignora ponteiro', (tester) async {
    await pumpCard(tester, status: StepStatus.locked);

    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.text('2'), findsNothing);
    expect(find.text('corpo-etapa'), findsOneWidget);
    expect(tester.widget<IgnorePointer>(cardIgnore()).ignoring, isTrue);
    expect(tester.widget<AnimatedOpacity>(cardOpacity()).opacity, 0.4);
  });

  testWidgets('completo mostra check e permanece expandido', (tester) async {
    await pumpCard(tester, status: StepStatus.completed);

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('corpo-etapa'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    expect(tester.widget<IgnorePointer>(cardIgnore()).ignoring, isFalse);
  });

  testWidgets('transição animada troca cadeado por número', (tester) async {
    await pumpCard(tester, status: StepStatus.locked);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);

    await pumpCard(tester, status: StepStatus.active);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(AnimatedSwitcher), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });
}
