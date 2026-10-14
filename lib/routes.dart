import 'package:flutter/material.dart';

import 'screens/configuracoes/configuracoes_screen.dart';
import 'screens/custo_manejo/custos_manejo_list_screen.dart';
import 'screens/historico/historico_screen.dart';
import 'screens/regulagem/regulagem_screen.dart';

class Routes {
  static const home = '/home';
  static const regulagem = '/regulagem';
  static const configuracoes = '/configuracoes';
  static const custosManejo = '/custos-manejo';
}

class AppRoutes {
  static Map<String, WidgetBuilder> get map => {
        Routes.home: (_) => const HistoricoScreen(),
        Routes.regulagem: (_) => const RegulagemScreen(),
        Routes.configuracoes: (_) => const ConfiguracoesScreen(),
        Routes.custosManejo: (_) => const CustosManejoListScreen(),
      };
}
