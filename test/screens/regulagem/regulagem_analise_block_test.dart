import 'package:agrocalc/models/configuracoes.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:agrocalc/screens/regulagem/widgets/regulagem_analise_block.dart';
import 'package:agrocalc/services/regulagem_pdf_service.dart';
import 'package:agrocalc/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _medicoes = [
  PontaMedicao(id: 1, valorMedido: 0.825, status: StatusPonta.ideal),
];

RegulagemPdfData _minimalPdfData() {
  return RegulagemPdfData(
    produtor: 'Teste',
    fazenda: 'Fazenda',
    maquina: 'Máquina',
    dataRegulagem: DateTime(2025, 1, 1),
    vazaoLha: 100,
    velocidade: 10,
    espacamentoCm: 50,
    numeroPontas: 1,
    litroMinIdeal: 0.825,
    medicoes: _medicoes,
    configuracoes: const Configuracoes(),
    manejo: 0,
    precoBico: 0,
    area: 0,
  );
}

Future<void> _pumpBlock(
  WidgetTester tester, {
  required bool readonly,
}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: RegulagemAnaliseBlock(
            medicoes: _medicoes,
            ideal: 0.825,
            configuracoes: const Configuracoes(),
            manejo: 0,
            precoBico: 0,
            area: 0,
            ladoConferencia: LadoConferenciaPontas.direita,
            readonly: readonly,
            buildData: _minimalPdfData,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('contém RepaintBoundary', (tester) async {
    await _pumpBlock(tester, readonly: false);

    expect(find.byType(RepaintBoundary), findsWidgets);
  });

  testWidgets('readonly true oculta botão Exportar PDF', (tester) async {
    await _pumpBlock(tester, readonly: true);

    expect(find.text('Exportar PDF'), findsNothing);
  });

  testWidgets('readonly false mostra botão Exportar PDF', (tester) async {
    await _pumpBlock(tester, readonly: false);

    expect(find.text('Exportar PDF'), findsOneWidget);
  });
}
