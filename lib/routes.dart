import 'package:flutter/material.dart';

import 'screens/home/home_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/regulagem/regulagem_screen.dart';

class Routes {
  static const home = '/home';
  static const login = '/login';
  static const regulagem = '/regulagem';
}

class AppRoutes {
  static Map<String, WidgetBuilder> get map => {
        Routes.home: (_) => const HomeScreen(),
        Routes.login: (_) => const LoginScreen(),
        Routes.regulagem: (_) => const RegulagemScreen(),
      };
}
