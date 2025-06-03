import 'package:flutter/material.dart';
import 'package:tj_tms_mobile/presentation/pages/login/login_page.dart';
import 'package:tj_tms_mobile/presentation/pages/home/home.dart';
import 'package:tj_tms_mobile/presentation/pages/outlets/box-scanning/box_scan_page.dart';
import 'package:tj_tms_mobile/presentation/pages/outlets/box-handover/box_handover_page.dart';
import 'package:tj_tms_mobile/presentation/pages/plugins/plugin_test_page.dart';
// import '../pages/settings_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String boxScan = '/outlets/box-scan';
  static const String boxHandover = '/outlets/box-handover';
  static const String settings = '/settings';
  static const String pluginTest = '/plugin-test';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginPage(),
      home: (context) => const HomePage(),
      boxScan: (context) => const BoxScanPage(),
      boxHandover: (context) => const BoxHandoverPage(),
      pluginTest: (context) => const PluginTestPage(),
      // settings: (context) => const SettingsPage(),
    };
  }
} 