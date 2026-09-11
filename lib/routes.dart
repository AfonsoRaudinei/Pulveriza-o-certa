import 'package:flutter/material.dart';

import 'screens/home/home_screen.dart';
import 'screens/ordem_aplicacao/nova_ordem_aplicacao_page.dart';
import 'screens/ordem_aplicacao/ordens_aplicacao_list_page.dart';
import 'screens/regulagem/regulagem_screen.dart';

class Routes {
  static const home = '/home';
  static const regulagem = '/regulagem';
  static const ordens = '/ordens';
  static const ordemAplicacao = '/ordem-aplicacao';
}

class AppRoutes {
  static Map<String, WidgetBuilder> get map => {
        Routes.home: (_) => const HomeScreen(),
        Routes.regulagem: (_) => const RegulagemScreen(),
        Routes.ordens: (_) => const OrdensAplicacaoListPage(),
        Routes.ordemAplicacao: (_) => const NovaOrdemAplicacaoPage(),
      };
}
