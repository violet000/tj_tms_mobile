import 'package:flutter/material.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/page_scaffold.dart';

// 菜单项接口定义
class MenuItem {
  final String name;
  final int index;
  final String? imagePath;
  final String? iconPath;
  final String? unselectedIcon;
  final String? selectedIcon;
  final IconData? icon;
  final List<MenuItem>? children;
  final String? route;
  final Color? color;
  final Map<String, dynamic>? params;
  final int? mode;

  MenuItem({
    required this.name,
    required this.index,
    this.imagePath,
    this.iconPath,
    this.unselectedIcon,
    this.selectedIcon,
    this.icon,
    this.children,
    this.route,
    this.color,
    this.params,
    this.mode,
  });
}

// 占位页面
Widget buildPlaceholderPage(MenuItem menu) {
  return PageScaffold(
    title: menu.name,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            menu.icon ?? Icons.home,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            menu.name,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击底部导航栏的"${menu.name}"进入对应功能',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

// 空页面
Widget buildEmptyPage(MenuItem menu) {
  return PageScaffold(
    title: menu.name,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            menu.icon ?? Icons.home,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            menu.name,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '暂未开发...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    ),
  );
}

// 错误页面
Widget buildErrorPage(BuildContext context) {
  return PageScaffold(
    title: '错误',
    showBackButton: true,
    onBackPressed: () {
      // 跳转到主页并清空页面栈
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    },
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Text(
            '页面未找到...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    ),
  );
}
