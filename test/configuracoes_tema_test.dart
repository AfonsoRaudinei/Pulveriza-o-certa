import 'package:agrocalc/app.dart';
import 'package:agrocalc/models/configuracoes.dart';
import 'package:agrocalc/providers/configuracoes_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR');
  });

  test('fromJson vazio assume tema system', () {
    final config = Configuracoes.fromJson({});
    expect(config.tema, TemaApp.system);
    expect(config.themeMode, ThemeMode.system);
  });

  test('fromJson dark mapeia ThemeMode.dark', () {
    final config = Configuracoes.fromJson({'tema': 'dark'});
    expect(config.tema, TemaApp.dark);
    expect(config.themeMode, ThemeMode.dark);
  });

  test('fromJson light mapeia ThemeMode.light', () {
    final config = Configuracoes.fromJson({'tema': 'light'});
    expect(config.tema, TemaApp.light);
    expect(config.themeMode, ThemeMode.light);
  });

  test('toJson/fromJson preserva tema', () {
    const original = Configuracoes(tema: TemaApp.dark);
    final roundtrip = Configuracoes.fromJson(original.toJson());
    expect(roundtrip.tema, TemaApp.dark);
  });

  testWidgets('app com tema dark inicia no Dashboard em Brightness.dark',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'agro_configuracoes': '{"tema":"dark"}',
    });

    await tester.pumpWidget(const PontaVerdeApp());
    await tester.pumpAndSettle();

    expect(find.text('Ponta Verde'), findsWidgets);
    expect(
      Theme.of(tester.element(find.text('Ponta Verde').first)).brightness,
      Brightness.dark,
    );
  });

  testWidgets('salvar na Config não reverte limites gravados pelo provider',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'agro_configuracoes': '{"tema":"dark"}',
    });

    await tester.pumpWidget(const PontaVerdeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Salvar'));
    final context = tester.element(find.text('Salvar'));
    final provider = context.read<ConfiguracoesProvider>();
    await provider.saveLimites(
      limiteDesgaste: 110,
      limiteIrregular: 95,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(provider.configuracoes.limiteDesgaste, 110);
    expect(provider.configuracoes.limiteIrregular, 95);
    expect(provider.configuracoes.tema, TemaApp.dark);
  });
}
