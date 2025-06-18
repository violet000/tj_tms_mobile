import 'package:flutter/material.dart';
import 'package:tj_tms_mobile/presentation/pages/login/login_page.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {

    final args = settings.arguments;
    
    // 根据路由名称返回对应的页面
    switch (settings.name) {
      case '/':
      case '/login':
        return MaterialPageRoute<dynamic>(builder: (_) => const LoginPage());
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute<dynamic>(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('错误'),
        ),
        body: const Center(
          child: Text('页面不存在'),
        ),
      );
    });
  }
} 