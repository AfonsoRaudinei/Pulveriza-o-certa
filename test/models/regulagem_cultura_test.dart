import 'dart:convert';

import 'package:agrocalc/core/constants/app_constants.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:agrocalc/providers/configuracoes_provider.dart';
import 'package:agrocalc/providers/regulagens_provider.dart';
import 'package:agrocalc/screens/regulagem/regulagem_screen.dart';
import 'package:agrocalc/services/storage_service.dart';
import 'package:agrocalc/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _jsonLegadoSemCultura() => {
      'id': '1',
      'produtor': 'P',
      'fazenda': 'F',
      'maquina': 'M',
      'tipoOperacao': 'pulverizador',
      'dataRegulagem': '2026-09-26T00:00:00.000',
      'vazaoLha': 80,
      'velocidade': 8,
      'espacamentoCm': 50,
      'numeroPontas': 10,
      'litroMinIdeal': 0.5,
      'medicoes': [],
      'criadoEm': '2026-09-26T00:00:00.000',
      'atualizadoEm': '2026-09-26T00:00:00.000',
    };

void main() {
  test('cultura serializa e restaura do JSON', () {
    final json = {
      'id': '1',
      'produtor': 'P',
      'fazenda': 'F',
      'maquina': 'M',
      'tipoOperacao': 'pulverizador',
      'dataRegulagem': '2026-09-26T00:00:00.000',
      'vazaoLha': 80,
      'velocidade': 8,
      'espacamentoCm': 50,
      'numeroPontas': 10,
      'litroMinIdeal': 0.5,
      'medicoes': [],
      'cultura': 'milho',
      'criadoEm': '2026-09-26T00:00:00.000',
      'atualizadoEm': '2026-09-26T00:00:00.000',
    };
    final r = Regulagem.fromJson(json);
    expect(r.cultura, CulturaCultivo.milho);
    expect(r.toJson()['cultura'], 'milho');
  });

  test('regulagem antiga sem cultura carrega Milho por padrão', () {
    final json = _jsonLegadoSemCultura();
    expect(Regulagem.fromJson(json).cultura, CulturaCultivo.milho);
  });

  test('regulagem antiga com cultura null no JSON carrega Milho', () {
    final json = _jsonLegadoSemCultura();
    json['cultura'] = null;
    expect(Regulagem.fromJson(json).cultura, CulturaCultivo.milho);
  });

  test('StorageService carrega legado sem cultura com Milho', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.regulagensKey: jsonEncode([_jsonLegadoSemCultura()]),
    });
    final list = await StorageService().getRegulagens();
    expect(list.single.cultura, CulturaCultivo.milho);
  });

  test('regulagem com Soja salva não é sobrescrita ao carregar', () {
    final json = _jsonLegadoSemCultura();
    json['cultura'] = 'soja';
    expect(Regulagem.fromJson(json).cultura, CulturaCultivo.soja);
  });

  test('tipoPonta e numeroAplicacoes serializam do JSON', () {
    final json = {
      'id': '1',
      'produtor': 'P',
      'fazenda': 'F',
      'maquina': 'M',
      'tipoOperacao': 'pulverizador',
      'dataRegulagem': '2026-09-26T00:00:00.000',
      'vazaoLha': 80,
      'velocidade': 8,
      'espacamentoCm': 50,
      'numeroPontas': 10,
      'litroMinIdeal': 0.5,
      'medicoes': [],
      'tipoPonta': 'conica',
      'numeroAplicacoes': 4,
      'criadoEm': '2026-09-26T00:00:00.000',
      'atualizadoEm': '2026-09-26T00:00:00.000',
    };
    final r = Regulagem.fromJson(json);
    expect(r.tipoPonta, TipoPontaBico.conica);
    expect(r.numeroAplicacoes, 4);
    expect(r.toJson()['tipoPonta'], 'conica');
    expect(r.toJson()['numeroAplicacoes'], 4);
  });

  test('regulagem antiga sem tipoPonta e aplicações', () {
    final json = {
      'id': '1',
      'produtor': 'P',
      'fazenda': 'F',
      'maquina': 'M',
      'tipoOperacao': 'pulverizador',
      'dataRegulagem': '2026-09-26T00:00:00.000',
      'vazaoLha': 80,
      'velocidade': 8,
      'espacamentoCm': 50,
      'numeroPontas': 10,
      'litroMinIdeal': 0.5,
      'medicoes': [],
      'criadoEm': '2026-09-26T00:00:00.000',
      'atualizadoEm': '2026-09-26T00:00:00.000',
    };
    final r = Regulagem.fromJson(json);
    expect(r.tipoPonta, isNull);
    expect(r.numeroAplicacoes, isNull);
  });

  testWidgets(
    'legado sem cultura permite salvar sem interagir com o dropdown de Cultura',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await initializeDateFormatting('pt_BR');

      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final legado = Regulagem.fromJson(_jsonLegadoSemCultura());
      expect(legado.cultura, CulturaCultivo.milho);

      SharedPreferences.setMockInitialValues({
        AppConstants.regulagensKey: jsonEncode([_jsonLegadoSemCultura()]),
      });

      late RegulagensProvider regulagensProvider;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => ConfiguracoesProvider()..load(),
            ),
            ChangeNotifierProvider(create: (_) {
              regulagensProvider = RegulagensProvider()..load();
              return regulagensProvider;
            }),
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
            home: RegulagemScreen(regulagem: legado),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final salvar = find.widgetWithText(TextButton, 'Salvar');
      expect(tester.widget<TextButton>(salvar).onPressed, isNotNull);

      await tester.tap(salvar);
      await tester.pumpAndSettle();

      expect(find.text('Editar Regulagem'), findsNothing);
      expect(regulagensProvider.regulagens.single.cultura, CulturaCultivo.milho);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.regulagensKey);
      expect(raw, isNotNull);
      final saved = (jsonDecode(raw!) as List).first as Map<String, dynamic>;
      expect(saved['cultura'], 'milho');
    },
  );
}
