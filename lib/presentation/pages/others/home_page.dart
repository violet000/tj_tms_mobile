import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/auth_provider.dart';
import '../models/menu_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    // 在 initState 中初始化页面
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePages();
    });
  }

  void _initializePages() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final menus = authProvider.getAuthorizedMenus();
    
    print('Debug: 获取到的菜单数量: ${menus.length}');
    for (var menu in menus) {
      print('Debug: 一级菜单: ${menu.name}');
      print('Debug: - 路由: ${menu.route}');
      print('Debug: - 图标: ${menu.icon}');
      if (menu.children != null) {
        print('Debug: - 子菜单数量: ${menu.children!.length}');
        for (var child in menu.children!) {
          print('Debug:   - 子菜单: ${child.name}');
          print('Debug:   - 子菜单路由: ${child.route}');
          print('Debug:   - 子菜单权限: ${child.permissions}');
        }
      }
    }
    
    if (_pages.isEmpty) {
      setState(() {
        for (var menu in menus) {
          if (menu.children != null && menu.children!.isNotEmpty) {
            print('Debug: 构建子菜单页面: ${menu.name}');
            _pages.add(_buildSubMenuPage(menu));
          } else {
            print('Debug: 构建默认页面: ${menu.name}');
            _pages.add(_buildDefaultPage(menu));
          }
        }
      });
    }
    
    print('Debug: 构建的页面数量: ${_pages.length}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 只在页面为空时重新初始化
    if (_pages.isEmpty) {
      _initializePages();
    }
  }

  Widget _buildSubMenuPage(MenuItem menu) {
    print('Debug: 构建子菜单页面 - ${menu.name}');
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
              child: Row(
                children: [
                  Text(
                    menu.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                itemCount: menu.children!.length,
                itemBuilder: (context, index) {
                  final subMenu = menu.children![index];
                  print('Debug: 构建子菜单项 - ${subMenu.name}');
                  return Card(
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16.0),
                      onTap: () {
                        print('Debug: 点击子菜单 - ${subMenu.name}, 路由: ${subMenu.route}');
                        Navigator.pushNamed(
                          context,
                          subMenu.route ?? '',
                          arguments: subMenu,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.0),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.08),
                              Theme.of(context).primaryColor.withOpacity(0.03),
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              _getMenuSvgPath(subMenu.icon ?? 'folder'),
                              width: 32.0,
                              height: 32.0,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 12.0),
                            Text(
                              subMenu.name,
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultPage(MenuItem menu) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(menu.name),
      ),
      body: Center(
        child: Text('${menu.name} 页面内容'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Consumer 来监听 AuthProvider 的变化
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('Debug: HomePage build - 开始构建');
        print('Debug: 用户信息: ${authProvider.userInfo?.toJson()}');
        print('Debug: 菜单数据: ${authProvider.menuItems?.length ?? 0}');
        final menus = authProvider.getAuthorizedMenus();
        print('Debug: build 方法中的菜单数量: ${menus.length}');

        // 如果没有菜单项，显示一个默认页面
        if (menus.isEmpty) {
          print('Debug: HomePage build - 没有菜单项，显示默认页面');
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text('首页'),
            ),
            body: const Center(
              child: Text('没有可用的菜单'),
            ),
          );
        }

        // 如果只有一个菜单项，添加一个占位菜单项
        final displayMenus = menus.length == 1 
            ? [...menus, MenuItem(id: 'placeholder', name: '占位')] 
            : menus;

        print('Debug: HomePage build - 显示菜单数量: ${displayMenus.length}');
        return Scaffold(
          body: _pages.isEmpty
              ? const Center(child: Text('没有可用的菜单'))
              : _pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              // 如果点击的是占位菜单项，不做任何操作
              if (menus.length == 1 && index == 1) return;
              
              setState(() {
                _selectedIndex = index;
              });
            },
            items: displayMenus.map((menu) {
              return BottomNavigationBarItem(
                icon: Icon(_getMenuIcon(menu.icon ?? 'folder')),
                label: menu.name,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  IconData _getMenuIcon(String iconName) {
    switch (iconName) {
      case 'home':
        return Icons.home;
      case 'settings':
        return Icons.settings;
      default:
        return Icons.folder;
    }
  }

  String _getMenuSvgPath(String iconName) {
    switch (iconName) {
      case 'home':
        return 'assets/icons/home.svg';
      case 'settings':
        return 'assets/icons/settings.svg';
      case 'workbench':
        return 'assets/icons/workbench.svg';
      case 'statistics':
        return 'assets/icons/statistics.svg';
      case 'user':
        return 'assets/icons/user.svg';
      case 'role':
        return 'assets/icons/role.svg';
      default:
        return 'assets/icons/folder.svg';
    }
  }
} 