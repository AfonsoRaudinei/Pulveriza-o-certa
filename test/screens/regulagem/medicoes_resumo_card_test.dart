import 'package:agrocalc/domain/calculos/calc_diagnostico_regulagem.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:agrocalc/screens/regulagem/widgets/medicoes_resumo_card.dart';
import 'package:agrocalc/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    List<ZonaDiagnostico> zonas = const [],
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: MedicoesResumoCard(zonas: zonas),
        ),
      ),
    );
  }

  ZonaDiagnostico zona(StatusPonta status, int qtd, String faixa) {
    return ZonaDiagnostico(
      status: status,
      quantidade: qtd,
      mediaPercentual: 100,
      rotulos: const [],
      faixa: faixa,
      perdaRs: 0,
    );
  }

  testWidgets('sem zonas não ocupa espaço', (tester) async {
    await pumpCard(tester);
    expect(find.byType(MedicoesResumoCard), findsOneWidget);
    expect(find.text('Ideal'), findsNothing);
  });

  testWidgets('mostra só as zonas existentes na ordem do laudo',
      (tester) async {
    await pumpCard(
      tester,
      zonas: [
        zona(StatusPonta.irregular, 3, '< 97%'),
        zona(StatusPonta.ideal, 2, '97–100%'),
        zona(StatusPonta.atencao, 3, '100–105%'),
        zona(StatusPonta.desgaste, 2, '> 105%'),
      ],
    );

    expect(find.text('Entupida'), findsOneWidget);
    expect(find.text('Ideal'), findsOneWidget);
    expect(find.text('Atenção'), findsOneWidget);
    expect(find.text('Desgaste'), findsOneWidget);
    expect(find.text('Tolerância'), findsNothing);
    expect(find.text('Acima Min'), findsNothing);
    expect(find.text('< 97%'), findsOneWidget);
    expect(find.text('> 105%'), findsOneWidget);
  });
}
