import 'package:flutter/material.dart';
import 'package:tj_tms_mobile/presentation/pages/login/login_page.dart';
import 'package:tj_tms_mobile/presentation/pages/home/home.dart';
import 'package:tj_tms_mobile/presentation/pages/outlets/box-scanning/box_scan_page.dart';
import 'package:tj_tms_mobile/presentation/pages/outlets/box-handover/box_handover_page.dart';
import 'package:tj_tms_mobile/presentation/pages/personal/personal_center_page.dart';
import 'package:tj_tms_mobile/presentation/pages/outlets/box-scanning/box_scan_verify_page.dart';
import 'package:tj_tms_mobile/presentation/pages/outlets/box-scanning/box-scan-verify-success.dart';
import 'package:tj_tms_mobile/presentation/pages/outlets/box-handover/box_handover_detail_page.dart';
import 'package:tj_tms_mobile/presentation/pages/outlets/box-handover/box_handover_verify_page.dart';
import 'package:tj_tms_mobile/presentation/pages/outlets/box-handover/box-handover-verify-success.dart';
import 'package:tj_tms_mobile/presentation/pages/setting/network_settings_page.dart';
import 'package:tj_tms_mobile/presentation/pages/personal/personal_detail_page.dart';
import 'package:tj_tms_mobile/presentation/pages/setting/plugin_test_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String boxScan = '/outlets/box-scan';
  static const String boxHandover = '/outlets/box-handover';
  static const String personal = '/personal_center_page';
  static const String boxScanVerify = '/outlets/box_scan_verify_page';
  static const String boxScanVerifySuccess = '/outlets/box-scan-verify-success';
  static const String boxHandoverDetail = '/outlets/box-handover-detail';
  static const String boxHandoverVerify = '/outlets/box-handover-verify';
  static const String boxHandoverVerifySuccess = '/outlets/box-handover-verify-success';
  static const String networkSettings = '/network-settings';
  static const String personalDetail = '/personal/detail';
  static const String pluginTest = '/plugin-test';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginPage(),
      home: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map<String, dynamic>) {
          return HomePage(arguments: args);
        }
        return const HomePage();
      },
      boxScan: (context) => const BoxScanPage(),
      boxHandover: (context) => const BoxHandoverPage(),
      boxScanVerify: (context) => const BoxScanVerifyPage(),
      boxScanVerifySuccess: (context) => const BoxScanVerifySuccessPage(),
      boxHandoverDetail: (context) => const BoxHandoverDetailPage(),
      boxHandoverVerify: (context) => const BoxHandoverVerifyPage(),
      boxHandoverVerifySuccess: (context) => const BoxHandoverVerifySuccessPage(),
      personalDetail: (context) => const PersonalDetailPage(),
      networkSettings: (context) => const NetworkSettingsPage(),
      personal: (context) => const PersonalCenterPage(),
      pluginTest: (context) => const PluginTestPage(),
    };
  }
} 