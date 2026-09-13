import 'package:agrocalc/app.dart';
import 'package:agrocalc/services/feedback_whatsapp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR');
  });

  testWidgets('FAB abre folha e Nova Regulagem navega para formulário',
      (tester) async {
    await tester.pumpWidget(const PontaVerdeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova Regulagem'));
    await tester.pumpAndSettle();

    expect(find.text('Nova Regulagem'), findsOneWidget);
    expect(find.text('Regulagens'), findsNothing);
  });

  testWidgets('Feedback chama launcher de WhatsApp', (tester) async {
    Uri? launchedUri;
    LaunchMode? launchedMode;

    await tester.pumpWidget(const PontaVerdeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Feedback'));
    await tester.pumpAndSettle();

    final ok = await abrirFeedbackWhatsApp(
      launchUrlFn: (uri, {mode = LaunchMode.platformDefault}) async {
        launchedUri = uri;
        launchedMode = mode;
        return true;
      },
    );

    expect(ok, isTrue);
    expect(launchedUri?.scheme, 'https');
    expect(launchedUri?.host, 'wa.me');
    expect(launchedUri?.path, contains('5563984376572'));
    expect(launchedUri?.queryParameters['text'], isNotEmpty);
    expect(launchedMode, LaunchMode.externalApplication);
  });
}
