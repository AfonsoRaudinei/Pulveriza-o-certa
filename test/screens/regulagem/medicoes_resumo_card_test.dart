import 'package:agrocalc/screens/regulagem/widgets/medicoes_resumo_card.dart';
import 'package:agrocalc/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    int desgaste = 0,
    int irregular = 0,
    int tolerancia = 0,
    int acimaMin = 0,
    int ideal = 0,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: MedicoesResumoCard(
            desgaste: desgaste,
            irregular: irregular,
            tolerancia: tolerancia,
            acimaMin: acimaMin,
            ideal: ideal,
          ),
        ),
      ),
    );
  }

  Text numberOf(WidgetTester tester, String label) {
    final cell = find.ancestor(
      of: find.text(label),
      matching: find.byType(Column),
    );
    return tester.widget<Text>(
      find.descendant(
        of: cell,
        matching: find.byWidgetPredicate(
          (widget) => widget is Text && widget.data != label,
        ),
      ),
    );
  }

  testWidgets('todos zerados: um card, labels e números inativos',
      (tester) async {
    await pumpCard(tester);

    expect(find.byType(MedicoesResumoCard), findsOneWidget);
    expect(find.text('Desgaste'), findsOneWidget);
    expect(find.text('Entupido'), findsOneWidget);
    expect(find.text('Tolerância'), findsOneWidget);
    expect(find.text('Acima Min'), findsOneWidget);
    expect(find.text('Ideal'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(5));
    expect(numberOf(tester, 'Desgaste').style?.color, AppColors.textSecondary);
  });

  testWidgets('valores positivos ativam a cor do número', (tester) async {
    await pumpCard(tester, desgaste: 4, acimaMin: 4);

    expect(find.text('4'), findsNWidgets(2));
    expect(find.text('0'), findsNWidgets(3));
    expect(numberOf(tester, 'Desgaste').style?.color, AppColors.danger);
  });
}
