import 'package:flutter/material.dart';
import '../models/menu_model.dart';
import '../pages/home_page.dart';
import '../pages/workbench_page.dart';
import '../pages/statistics_page.dart';
import '../pages/user_management_page.dart';
import '../pages/role_management_page.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // 获取路由参数
    final args = settings.arguments;
    
    // 根据路由名称返回对应的页面
    switch (settings.name) {
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomePage());
      case '/home/workbench':
        return MaterialPageRoute(builder: (_) => const WorkbenchPage());
      case '/home/statistics':
        return MaterialPageRoute(builder: (_) => const StatisticsPage());
      case '/system/users':
        return MaterialPageRoute(builder: (_) => const UserManagementPage());
      case '/system/roles':
        return MaterialPageRoute(builder: (_) => const RoleManagementPage());
      default:
        // 处理动态路由
        if (args is MenuItem) {
          return _buildRouteFromMenuItem(args);
        }
        return _errorRoute();
    }
  }

  static Route<dynamic> _buildRouteFromMenuItem(MenuItem menu) {
    // 这里可以根据菜单项的类型或其他属性来构建不同的页面
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: Text(menu.name),
        ),
        body: Center(
          child: Text('${menu.name} 页面正在开发中...'),
        ),
      ),
    );
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
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