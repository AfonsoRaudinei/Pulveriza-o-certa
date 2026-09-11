import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/cadastros_provider.dart';
import 'providers/configuracoes_provider.dart';
import 'providers/ordens_aplicacao_provider.dart';
import 'providers/regulagens_provider.dart';
import 'routes.dart';
import 'theme.dart';

class PontaVerdeApp extends StatelessWidget {
  const PontaVerdeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConfiguracoesProvider()..load()),
        ChangeNotifierProvider(create: (_) => RegulagensProvider()..load()),
        ChangeNotifierProvider(
          create: (_) => OrdensAplicacaoProvider()..load(),
        ),
        ChangeNotifierProvider(create: (_) => CadastrosProvider()..load()),
      ],
      child: Consumer<ConfiguracoesProvider>(
        builder: (context, configuracoes, _) {
          return MaterialApp(
            title: 'Ponta Verde',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: configuracoes.configuracoes.themeMode,
            initialRoute: Routes.home,
            routes: AppRoutes.map,
            locale: const Locale('pt', 'BR'),
            supportedLocales: const [Locale('pt', 'BR')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}
