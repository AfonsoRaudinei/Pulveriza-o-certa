import 'package:agrocalc/app.dart';
import 'package:agrocalc/models/configuracoes.dart';
import 'package:agrocalc/models/perfil_relatorio.dart';
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

  test('fromJson migra nomeConsultor legado para perfilRelatorio', () {
    final config = Configuracoes.fromJson({
      'nomeConsultor': 'João',
      'empresaNome': 'Agro Ltda',
    });
    expect(config.perfilRelatorio.nomeConsultor, 'João');
    expect(config.perfilRelatorio.empresaNome, 'Agro Ltda');
  });

  test('PerfilRelatorio roundtrip json', () {
    const perfil = PerfilRelatorio(
      nomeConsultor: 'Ana',
      empresaNome: 'Campo Verde',
      logoPath: '/tmp/logo.jpg',
    );
    final roundtrip = PerfilRelatorio.fromJson(perfil.toJson());
    expect(roundtrip.nomeConsultor, 'Ana');
    expect(roundtrip.logoPath, '/tmp/logo.jpg');
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

  testWidgets('Configurações não exibe Limites de Regulagem', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PontaVerdeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configuração'));
    await tester.pumpAndSettle();

    expect(find.text('PERFIL & RELATÓRIO'), findsOneWidget);
    expect(find.text('NOTIFICAÇÕES E LEMBRETES'), findsOneWidget);
    expect(find.text('Limites de Regulagem'), findsNothing);
    expect(find.text('Limite desgaste (%)'), findsNothing);
  });

  testWidgets('saveLimites via provider preserva limites fora da UI Config',
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

    final context = tester.element(find.text('Regulagens'));
    final provider = context.read<ConfiguracoesProvider>();
    await provider.saveLimites(
      limiteDesgaste: 110,
      limiteIrregular: 95,
    );

    expect(provider.configuracoes.limiteDesgaste, 110);
    expect(provider.configuracoes.limiteIrregular, 95);
    expect(provider.configuracoes.tema, TemaApp.dark);
  });
}
