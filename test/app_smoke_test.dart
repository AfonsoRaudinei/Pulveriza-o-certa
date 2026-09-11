import 'package:agrocalc/app.dart';
import 'package:agrocalc/routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR');
  });

  testWidgets('app inicia no Dashboard sem rota de login', (tester) async {
    await tester.pumpWidget(const PontaVerdeApp());
    await tester.pumpAndSettle();

    // Marca do produto unificada.
    expect(find.text('Ponta Verde'), findsWidgets);
    // Ação principal do dashboard.
    expect(find.text('Nova Regulagem'), findsOneWidget);
    // A rota de login foi removida.
    expect(Routes.home, '/home');
    expect(AppRoutes.map.containsKey('/login'), isFalse);
  });

  testWidgets('histórico corrompido não quebra o app nem apaga no próximo save',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'agro_regulagens': '{isto não é json válido',
    });

    await tester.pumpWidget(const PontaVerdeApp());
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    // O blob inválido foi preservado numa chave de quarentena.
    final quarentena =
        prefs.getKeys().where((k) => k.startsWith('agro_regulagens_corrompido_'));
    expect(quarentena, isNotEmpty);
    expect(prefs.getString('agro_regulagens'), isNull);
  });
}
