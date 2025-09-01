import 'package:flutter/material.dart';

class GlobalNavigator {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void showSnackBar(String message) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static void navigateToLogin() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    
    // 清除所有路由并跳转到登录页面
    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
  }
}

