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

  testWidgets('app com tema dark inicia na lista em Brightness.dark',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'agro_configuracoes': '{"tema":"dark"}',
    });

    await tester.pumpWidget(const PontaVerdeApp());
    await tester.pumpAndSettle();

    expect(find.text('Regulagens'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('Regulagens'))).brightness,
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

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configuração'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Salvar perfil'));
    final context = tester.element(find.text('Salvar perfil'));
    final provider = context.read<ConfiguracoesProvider>();
    await provider.saveLimites(
      limiteDesgaste: 110,
      limiteIrregular: 95,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar perfil'));
    await tester.pumpAndSettle();

    expect(provider.configuracoes.limiteDesgaste, 110);
    expect(provider.configuracoes.limiteIrregular, 95);
    expect(provider.configuracoes.tema, TemaApp.dark);
  });

  testWidgets('trocar tema não apaga texto de perfil não salvo', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const PontaVerdeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configuração'));
    await tester.pumpAndSettle();

    final nomeField = find.byType(TextField).first;
    await tester.enterText(nomeField, 'Maria Silva');
    await tester.pump();

    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(nomeField).controller?.text, 'Maria Silva');
  });
}
