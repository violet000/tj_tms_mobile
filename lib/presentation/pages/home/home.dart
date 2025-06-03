import 'package:flutter/material.dart';

// 菜单项模型
class MenuItem {
  final String name;
  final IconData icon;
  final List<MenuItem>? children;
  final String? route;
  final Color? color;

  MenuItem({
    required this.name,
    required this.icon,
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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final List<Widget> _pages = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<MenuItem> menus = [
    MenuItem(
      name: '首页',
      icon: Icons.home_rounded,
      route: '/home',
      color: const Color(0xFF29A8FF),
    ),
    MenuItem(
      name: '网点交接',
      icon: Icons.work_rounded,
      color: const Color(0xFF0489FE),
      children: [
        MenuItem(
          name: '款箱扫描',
          icon: Icons.task_rounded,
          route: '/outlets/box-scan',
          color: const Color(0xFF29A8FF),
        ),
        MenuItem(
          name: '款箱交接',
          icon: Icons.assignment_rounded,
          route: '/outlets/box-handover',
          color: const Color(0xFF0489FE),
        ),
      ],
    ),
    MenuItem(
      name: '金库交接',
      icon: Icons.message_rounded,
      color: const Color(0xFF0489FE),
      children: [
        MenuItem(
          name: '款箱扫描',
          icon: Icons.task_rounded,
          route: '/box-scan',
          color: const Color(0xFF29A8FF),
        ),
        MenuItem(
          name: '款箱交接',
          icon: Icons.assignment_rounded,
          route: '/box-handover',
          color: const Color(0xFF0489FE),
        ),
      ],
    ),
    MenuItem(
      name: '插件测试',
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
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
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
        } else {
          _pages.add(_buildDefaultPage(menu));
        }
      }
    });
  }
  
  // 构建子菜单页面
  Widget _buildSubMenuPage(MenuItem menu) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
        ),
        child: Column(
          children: [
            _buildHeader(menu),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                  ),
                  itemCount: menu.children?.length ?? 0,
                  itemBuilder: (context, index) {
                    final child = menu.children![index];
                    return _buildMenuCard(child);
                  },
                ),
              )
            )
          ]
        )
      )
    );
  }

  // 构建默认页面
  Widget _buildDefaultPage(MenuItem menu) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
        ),
        child: Column(
          children: [
            _buildHeader(menu),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      menu.icon,
                      size: 64,
                      color: menu.color,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      menu.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: menu.color,
                      ),
                    ),
                    if (menu.route != null) ...[
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, menu.route!);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: menu.color,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: const Text(
                          '进入',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建菜单卡片
  Widget _buildMenuCard(MenuItem menu) {
    return Hero(
      tag: menu.name,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
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
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  menu.icon,
                  size: 50,
                  color: menu.color,
                ),
                const SizedBox(height: 8),
                Text(
                  menu.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: menu.color,
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
        color: const Color(0xFF0489FE),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: Colors.white,
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
              color: Colors.black.withOpacity(0.1),
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
            items: menus.map((menu) => BottomNavigationBarItem(
              icon: Icon(menu.icon),
              label: menu.name,
            )).toList(),
          ),
        ),
      ),
    );
  }
}