import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';

// 菜单项模型
class MenuItem {
  final String name;
  final String? imagePath;
  final String? iconPath;
  final IconData? icon;
  final List<MenuItem>? children;
  final String? route;
  final Color? color;

  MenuItem({
    required this.name,
    this.imagePath,
    this.iconPath,
    this.icon,
    this.children,
    this.route,
    this.color,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final List<Widget> _pages = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<MenuItem> menus = [
    MenuItem(
      name: '交接',
      icon: Icons.work_rounded,
      color: const Color.fromARGB(255, 255, 255, 255),
      children: [
        MenuItem(
          name: '网点交接',
          imagePath: 'assets/icons/handover_circle.svg',
          iconPath: 'assets/icons/net_handover_icon.svg',
          route: '/outlets/box-scan',
          color: const Color.fromARGB(255, 115, 190, 240).withOpacity(0.1),
        ),
        MenuItem(
          name: '金库交接',
          imagePath: 'assets/icons/treasury_reat.svg',
          iconPath: 'assets/icons/treasury_handover_icon.svg',
          route: '/outlets/box-handover',
          color: const Color.fromARGB(255, 134, 221, 245).withOpacity(0.1),
        ),
      ],
    ),
    MenuItem(
      name: '我的',
      icon: Icons.person_rounded,
      route: '/plugin-test',
      color: const Color(0xFF0489FE),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePages();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 初始化页面
  void _initializePages() {
    setState(() {
      for (var menu in menus) {
        if (menu.children != null) {
          _pages.add(_buildSubMenuPage(menu));
        }
      }
    });
  }

  // 构建子菜单页面
  Widget _buildSubMenuPage(MenuItem menu) {
    return Scaffold(
        body: Container(
            decoration:
                const BoxDecoration(color: Color.fromARGB(255, 245, 246, 250)),
            child: Column(children: [
              _buildHeader(menu),
              Expanded(
                  // 子菜单
                  child: FadeTransition(
                opacity: _fadeAnimation,
                child: GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: menu.children?.length ?? 0,
                  itemBuilder: (context, index) {
                    final child = menu.children![index];
                    return _buildMenuCard(child);
                  },
                ),
              ))
            ])));
  }

  // 构建菜单卡片
  Widget _buildMenuCard(MenuItem menu) {
    return Hero(
      tag: menu.name,
      child: Card(
        elevation: 2, // 阴影
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () {
            if (menu.route != null) {
              Navigator.pushNamed(context, menu.route!);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: menu.color,
              boxShadow: [
                BoxShadow(
                  color:
                      const Color.fromARGB(255, 255, 255, 255).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 背景SVG - 放大并定位到右下区域
                Positioned(
                  right: -30,
                  bottom: -30,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // 模糊效果
                      child: SvgPicture.asset(
                        menu.imagePath!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // 右下角居中图标
                if (menu.iconPath != null)
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: SvgPicture.asset(
                      menu.iconPath!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      color: Colors.white,
                    ),
                  ),
                // 右上角放置一个箭头角标 - 放在最后确保在最上层
                Positioned(
                  top: 12,
                  right: 12,
                  child: SvgPicture.asset(
                    'assets/icons/arrow_right_icon.svg',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ),
                // 文字内容
                Positioned(
                  top: 12,
                  left: 12,
                  child: Text(
                    menu.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建Header
  Widget _buildHeader(MenuItem menu) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 245, 246, 250),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 221, 218, 218).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            menu.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 3, 3, 3),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF29A8FF)),
              ),
            )
          : _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 226, 224, 224).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF29A8FF),
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            elevation: 0,
            enableFeedback: false,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: menus
                .map((menu) => BottomNavigationBarItem(
                      icon: Icon(menu.icon),
                      label: menu.name,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
