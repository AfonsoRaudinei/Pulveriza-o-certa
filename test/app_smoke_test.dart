import 'package:agrocalc/app.dart';
import 'package:agrocalc/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR');
  });

  testWidgets('app inicia na lista de Regulagens sem rota de login', (tester) async {
    await tester.pumpWidget(const PontaVerdeApp());
    await tester.pumpAndSettle();

    expect(find.text('Regulagens'), findsOneWidget);
    expect(find.text('Ponta Verde'), findsNothing);
    expect(find.text('Nova Regulagem'), findsNothing);
    expect(find.text('Início'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Nova Regulagem'), findsOneWidget);
    expect(find.text('Configuração'), findsOneWidget);
    expect(find.text('Feedback'), findsOneWidget);

    expect(Routes.home, '/home');
    expect(AppRoutes.map.containsKey('/login'), isFalse);
    expect(AppRoutes.map.containsKey(Routes.regulagem), isTrue);
    expect(AppRoutes.map.containsKey(Routes.configuracoes), isTrue);
  });

  testWidgets(
    'histórico corrompido não quebra o app nem apaga no próximo save',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'agro_regulagens': '{isto não é json válido',
      });

      await tester.pumpWidget(const PontaVerdeApp());
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      // O blob inválido foi preservado numa chave de quarentena.
      final quarentena = prefs.getKeys().where(
            (k) => k.startsWith('agro_regulagens_corrompido_'),
          );
      expect(quarentena, isNotEmpty);
      expect(prefs.getString('agro_regulagens'), isNull);
    },
  );
}
