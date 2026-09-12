import 'package:agrocalc/theme.dart';
import 'package:agrocalc/widgets/card_zona_atencao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  Future<void> pumpCard(
    WidgetTester tester, {
    required int qtd,
    double perda = 1500,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: CardZonaAtencao(
            qtdPontas: qtd,
            perdaEstimada: perda,
          ),
        ),
      ),
    );
  }

  testWidgets('qtd zero não ocupa espaço', (tester) async {
    await pumpCard(tester, qtd: 0);
    expect(find.text('Zona de Atenção'), findsNothing);
    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('mostra quantidade, faixa e valor em R\$', (tester) async {
    await pumpCard(tester, qtd: 2, perda: 4000);
    expect(find.text('Zona de Atenção'), findsOneWidget);
    expect(
      find.text(
        '2 ponta(s) entre 100% e 105% — ainda não pedem troca, já desperdiçam insumo.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('4.000'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });
}
