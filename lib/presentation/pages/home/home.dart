import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/error_page.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';
import 'package:tj_tms_mobile/presentation/pages/personal/personal_center_page.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const HomePage({super.key, this.arguments});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final List<Widget> _pages = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<MenuItem> menus = [];
  bool _isInitialized = false; // 初始化状态

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    // 检查是否有传入的tab索引参数
    if (widget.arguments != null && widget.arguments!['selectedTab'] != null) {
      _selectedIndex = widget.arguments!['selectedTab'] as int;
    }

    // 延迟初始化，避免阻塞UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAsync();
    });
  }

  // 异步初始化
  Future<void> _initializeAsync() async {
    _initializeBasicUI();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      _animationController.forward();
    }
  }

  // 初始化
  void _initializeBasicUI() {
    setState(() {
      menus = [
        MenuItem(
          name: '交接',
          index: 1,
          unselectedIcon: 'storage/inner_unselected.svg',
          selectedIcon: 'storage/inner_selected.svg',
          children: [
            MenuItem(
              name: '网点交接',
              index: 0,
              mode: 0,
              imagePath: 'assets/icons/handover_circle.svg',
              iconPath: 'assets/icons/net_handover_icon.svg',
              route: '/outlets/box-scan',
              color: const Color.fromARGB(255, 115, 190, 240).withOpacity(0.1),
            ),
            MenuItem(
              name: '金库交接',
              index: 1,
              mode: 1,
              imagePath: 'assets/icons/treasury_reat.svg',
              iconPath: 'assets/icons/treasury_handover_icon.svg',
              route: '/outlets/box-handover',
              color: const Color.fromARGB(255, 134, 221, 245).withOpacity(0.1),
            )
          ],
          color: const Color(0xFF0489FE),
        ),
        MenuItem(
          name: '我的',
          index: 2,
          icon: Icons.business,
          route: '/personal_center_page',
          color: const Color(0xFF0489FE),
        ),
      ];
      _initializePages();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializePages() {
    setState(() {
      _pages.clear();
      for (var menu in menus) {
        if (menu.children != null) {
          _pages.add(_buildSubMenuPage(menu));
        } else if (menu.route != null) {
          // TODO: 这里需要优化，如果路由是/personal_center_page，则直接跳转到PersonalCenterPage，否则跳转到buildPlaceholderPage
          if (menu.route == '/personal_center_page') {
            _pages.add(const PersonalCenterPage());
          } else {
            _pages.add(buildPlaceholderPage(menu));
          }
        } else {
          _pages.add(buildEmptyPage(menu));
        }
      }
    });
  }

  /// 判断svg图片是否存在
  Future<bool> assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 构建子菜单页面
  Widget _buildSubMenuPage(MenuItem menu) {
    return PageScaffold(
      title: menu.name,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: menu.children?.length ?? 0,
          itemBuilder: (context, index) {
            final child = menu.children![index];
            return _buildInnerWorkMenuCard(child);
          },
          padding: const EdgeInsets.all(8.0),
        ),
      ),
    );
  }

  // 库内作业菜单卡片
  Widget _buildInnerWorkMenuCard(MenuItem menu) {
    return Hero(
      tag: menu.name,
      child: Card(
        elevation: 2, // 阴影
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          splashColor: Colors.transparent, // 点击时没有水波纹效果
          highlightColor: Colors.transparent, // 点击时没有高亮效果
          onTap: () {
            Navigator.pushNamed(context, menu.route!, arguments: {'mode': menu.mode});
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 90,
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
                      filter:
                          ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // 模糊效果
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
                      fontWeight: FontWeight.w500,
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

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF29A8FF)),
              ),
              const SizedBox(height: 16),
              Text(
                '正在加载...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
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
          child: Theme(
            data: Theme.of(context).copyWith(
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF29A8FF),
              unselectedItemColor: Colors.grey,
              selectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
              elevation: 0,
              enableFeedback: false,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                  AppLogger.info('selectedIndex: $_selectedIndex');
                });
              },
              items: menus
                  .map((menu) => BottomNavigationBarItem(
                        icon: menu.unselectedIcon != null
                            ? SvgPicture.asset(
                                menu.unselectedIcon!,
                                width: 18,
                                height: 18,
                                color: Colors.grey,
                              )
                            : Icon(menu.icon),
                        activeIcon: menu.selectedIcon != null
                            ? SvgPicture.asset(
                                menu.selectedIcon!,
                                width: 18,
                                height: 18,
                                color: const Color(0xFF29A8FF),
                              )
                            : Icon(menu.icon),
                        label: menu.name,
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
