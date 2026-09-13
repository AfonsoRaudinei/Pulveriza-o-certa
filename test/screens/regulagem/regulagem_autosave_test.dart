import 'dart:convert';

import 'package:agrocalc/core/constants/app_constants.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:agrocalc/providers/configuracoes_provider.dart';
import 'package:agrocalc/providers/regulagens_provider.dart';
import 'package:agrocalc/screens/regulagem/regulagem_screen.dart';
import 'package:agrocalc/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Regulagem _sample({required String id}) {
  final now = DateTime(2026, 9, 11);
  return Regulagem(
    id: id,
    produtor: 'RAUDINEI',
    fazenda: 'harmonia',
    talhao: 'estrela',
    maquina: 'case',
    tipoOperacao: TipoOperacao.pulverizador,
    dataRegulagem: now,
    consultor: 'RAUDINEI',
    vazaoLha: 90,
    velocidade: 11,
    espacamentoCm: 50,
    numeroPontas: 3,
    pressaoBar: 3,
    litroMinIdeal: 0.825,
    medicoes: const [
      PontaMedicao(id: 1, valorMedido: 0.825, status: StatusPonta.ideal),
      PontaMedicao(id: 2, valorMedido: null, status: StatusPonta.pendente),
      PontaMedicao(id: 3, valorMedido: null, status: StatusPonta.pendente),
    ],
    criadoEm: now,
    atualizadoEm: now,
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR');
  });

  testWidgets('auto-grava ao abrir a ponta de baixo sem sair da tela',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const id = 'regulagem-autosave';
    final sample = _sample(id: id);
    SharedPreferences.setMockInitialValues({
      AppConstants.regulagensKey: jsonEncode([sample.toJson()]),
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => ConfiguracoesProvider()..load()),
          ChangeNotifierProvider(create: (_) => RegulagensProvider()..load()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: RegulagemScreen(regulagem: sample),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editar Regulagem'), findsOneWidget);

    await tester.ensureVisible(find.text('Medições das Pontas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medições das Pontas'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('ponta-row-3')));
    await tester.tap(find.byKey(const ValueKey('ponta-row-3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Editar Regulagem'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.regulagensKey);
    expect(raw, isNotNull);
    final list = jsonDecode(raw!) as List<dynamic>;
    expect(list, hasLength(1));
    expect((list.first as Map)['id'], id);
    expect((list.first as Map)['produtor'], 'RAUDINEI');
  });

  testWidgets('espaçamento e limites ficam empilhados, não lado a lado',
      (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => ConfiguracoesProvider()..load()),
          ChangeNotifierProvider(create: (_) => RegulagensProvider()..load()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const RegulagemScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, '').at(0),
      'Produtor',
    );
    // Campos visíveis na etapa 1 (aberta): preenche os obrigatórios via labels.
    final produtor = find.ancestor(
      of: find.text('Produtor'),
      matching: find.byType(Column),
    );
    expect(produtor, findsWidgets);

    final espacamento = find.text('Espaçamento entre bicos (cm)');
    expect(espacamento, findsNothing);

    await tester.enterText(find.byType(TextField).at(0), 'João');
    await tester.enterText(find.byType(TextField).at(1), 'Fazenda');
    await tester.enterText(find.byType(TextField).at(3), 'Máquina');
    await tester.pumpAndSettle();

    expect(find.text('Espaçamento entre bicos (cm)'), findsOneWidget);
    expect(find.text('Número de pontas'), findsOneWidget);

    final espacoField = tester.getTopLeft(
      find.text('Espaçamento entre bicos (cm)'),
    );
    final pontasField = tester.getTopLeft(find.text('Número de pontas'));
    expect(pontasField.dy, greaterThan(espacoField.dy));
    expect((pontasField.dx - espacoField.dx).abs(), lessThan(8));
  });
}
