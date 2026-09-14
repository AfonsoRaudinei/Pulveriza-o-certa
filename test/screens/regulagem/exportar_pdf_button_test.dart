import 'package:agrocalc/models/configuracoes.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:agrocalc/screens/regulagem/widgets/exportar_pdf_button.dart';
import 'package:agrocalc/services/regulagem_pdf_service.dart';
import 'package:agrocalc/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

RegulagemPdfData _minimalPdfData() {
  return RegulagemPdfData(
    produtor: 'Teste',
    fazenda: 'Fazenda',
    maquina: 'Máquina',
    dataRegulagem: DateTime(2025, 1, 1),
    vazaoLha: 100,
    velocidade: 10,
    espacamentoCm: 50,
    numeroPontas: 2,
    litroMinIdeal: 0.825,
    medicoes: const [
      PontaMedicao(id: 1, valorMedido: 0.825, status: StatusPonta.ideal),
    ],
    configuracoes: const Configuracoes(),
    manejo: 0,
    precoBico: 0,
    area: 0,
  );
}

void main() {
  testWidgets('buildData não é chamado no pumpWidget', (tester) async {
    var buildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ExportarPdfButton(
            buildData: () {
              buildCount++;
              return _minimalPdfData();
            },
          ),
        ),
      ),
    );

    expect(buildCount, 0);
    expect(find.text('Exportar PDF'), findsOneWidget);
  });

  testWidgets('buildData é chamado 1× ao tocar Exportar PDF', (tester) async {
    var buildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ExportarPdfButton(
            buildData: () {
              buildCount++;
              return _minimalPdfData();
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Exportar PDF'));
    await tester.pump();

    expect(buildCount, 1);

    // Share/PDF podem falhar no ambiente de teste — buildData não deve repetir.
    await tester.pump(const Duration(seconds: 2));
    expect(buildCount, 1);
  });
}
