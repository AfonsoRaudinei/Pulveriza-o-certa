import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/configuracoes_provider.dart';
import 'providers/regulagens_provider.dart';
import 'routes.dart';
import 'theme.dart';

class AgroCalcApp extends StatelessWidget {
  const AgroCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConfiguracoesProvider()..load()),
        ChangeNotifierProvider(create: (_) => RegulagensProvider()..load()),
      ],
      child: MaterialApp(
        title: 'AgroCalc',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: Routes.home,
        routes: AppRoutes.map,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
