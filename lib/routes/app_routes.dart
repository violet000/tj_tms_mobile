import 'package:flutter/material.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/settings_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginPage(),
      home: (context) => const HomePage(),
      settings: (context) => const SettingsPage(),
    };
  }
} 