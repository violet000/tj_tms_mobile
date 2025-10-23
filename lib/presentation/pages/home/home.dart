import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:tj_tms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/error_page.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';
import 'package:tj_tms_mobile/presentation/pages/personal/personal_center_page.dart';
// import 'package:tj_tms_mobile/services/location_polling_manager.dart';
import 'package:tj_tms_mobile/data/datasources/api/18082/service_18082.dart';
import 'package:tj_tms_mobile/services/interval_manager.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const HomePage({super.key, this.arguments});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  int _selectedIndex = 0;
  final List<Widget> _pages = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<MenuItem> menus = [];
  bool _isInitialized = false; // 初始化状态

  // 位置轮询相关
  // final LocationPollingManager _locationPollingManager =
  //     LocationPollingManager();

  @override
  void initState() {
    super.initState();

    // 注册应用生命周期监听
    WidgetsBinding.instance.addObserver(this);

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

  int parseIntervalToSeconds({
    required String paramValue,
    required String statement,
  }) {
    final int? raw = int.tryParse(paramValue);
    if (raw == null) return 0;
    // 若含 ss 则按秒；否则若含 mm 按分钟；否则若含 HH 按小时；默认当作秒
    if (statement.contains('ss')) return raw;
    if (statement.contains('mm')) return raw * 60;
    if (statement.contains('HH')) return raw * 3600;
    return raw;
  }

  // Future<void> _loadAGPSInterval() async {
  //   try {
  //     AppLogger.info('开始加载AGPS间隔配置');
      
  //     final service = await Service18082.create();
  //     final result = await service.getAGPSParam(<String, dynamic>{
  //       'catalog': '',
  //       'paramName': 'GPS_SEND_TIME',
  //       'statement': '',
  //       'description': '',
  //       'pageSize': 10,
  //       'curRow': 1
  //     });
      
  //     if ((result['retCode'] as String?) == '000000') {
  //       final List<dynamic> dataList =
  //           (result['retList'] as List<dynamic>?) ?? <dynamic>[];
  //       if (dataList.isNotEmpty) {
  //         final Map<String, dynamic> agpsData =
  //             dataList.first as Map<String, dynamic>;
  //         final String? paramValue = agpsData['paramValue']?.toString();
  //         final String? statement = agpsData['statement']?.toString();
  //         if (paramValue != null) {
  //           final int interval = parseIntervalToSeconds(
  //               paramValue: paramValue, statement: statement ?? '');
            
  //           AppLogger.info('从服务器获取到AGPS间隔: ${interval}秒');
  //           await IntervalManager.setBothIntervals(interval);
  //           // await _startLocationPolling();
  //           return;
  //         }
  //       }
  //     }
      
  //     // 如果服务器获取失败，使用本地保存的配置
  //     AppLogger.info('服务器获取AGPS间隔失败，使用本地配置');
  //     final saved = await IntervalManager.getAGPSInterval();
  //     final current = saved ?? await IntervalManager.getDefaultInterval();
  //     await IntervalManager.setCurrentInterval(current);
  //     if (saved != null && saved > 0) {
  //       await IntervalManager.updateLocationPollingConfig(saved);
  //     }
  //     // await _startLocationPolling();
  //   } catch (e) {
  //     AppLogger.error('加载AGPS间隔配置失败: $e');
      
  //     // 异常情况下使用默认配置
  //     try {
  //       final saved = await IntervalManager.getAGPSInterval();
  //       final current = saved ?? await IntervalManager.getDefaultInterval();
  //       await IntervalManager.setCurrentInterval(current);
  //       if (saved != null && saved > 0) {
  //         await IntervalManager.updateLocationPollingConfig(saved);
  //       }
  //       // await _startLocationPolling();
  //     } catch (innerError) {
  //       AppLogger.error('启动位置轮询服务失败: $innerError');
  //     }
  //   }
  // }

  // 异步初始化
  Future<void> _initializeAsync() async {
    _initializeBasicUI();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      _animationController.forward();
      
      // 在UI初始化完成后再启动AGPS服务
      // _loadAGPSInterval();
      
    }
  }
  
  // 页面恢复机制
  // void _restorePageState() {
  //   if (mounted && _isInitialized) {
  //     // 延迟执行，避免快速切换导致的问题
  //     Future.delayed(const Duration(milliseconds: 100), () {
  //       if (mounted) {
  //         setState(() {
  //         });
          
  //         _initializePages();
          
  //         if (_animationController.status != AnimationStatus.completed) {
  //           _animationController.forward();
  //         }
  //       }
  //     });
  //   }
  // }

  // 启动位置轮询服务
  // Future<void> _startLocationPolling() async {
  //   try {
  //     await _locationPollingManager.initialize();
  //     _attachLocationCallbacks();
      
  //     // 使用IntervalManager获取有效的间隔值，添加错误处理
  //     int effectiveInterval = 0;
  //     try {
  //       effectiveInterval = await IntervalManager.getEffectiveInterval();
  //     } catch (e) {
  //       AppLogger.error('获取AGPS间隔失败: $e');
  //       effectiveInterval = 30; // 使用默认值
  //     }
      
  //     if (effectiveInterval > 0) {
  //       _locationPollingManager.setPollingInterval(effectiveInterval);
  //     }
      
  //     // 启动位置轮询
  //     _locationPollingManager.startPolling();
  //   } catch (e) {
  //     AppLogger.error('位置轮询服务初始化失败: $e');
  //   }
  // }

  // 绑定位置更新与错误回调（前台时启用）
  // void _attachLocationCallbacks() {
  //   _locationPollingManager.setCallbacks(
  //     onLocationUpdate: (location) {
  //       if (!mounted) return;
  //       setState(() {});
  //     },
  //     onError: (error) {
  //       AppLogger.error('错误: $error');
  //     },
  //   );
  // }

  // 解绑回调（后台时避免触发UI）
  // void _detachLocationCallbacks() {
  //   _locationPollingManager.setCallbacks(onLocationUpdate: null, onError: null);
  // }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   AppLogger.info('应用生命周期状态变化: $state');

  //   // 前台：恢复回调并确保轮询运行；后台：仅解绑回调，确保轮询继续运行
  //   switch (state) {
  //     case AppLifecycleState.resumed:
  //       AppLogger.info('应用恢复前台，重新绑定回调并确保轮询运行');
        
  //       // 强制清理可能残留的Loading遮罩
  //       try {
  //         EasyLoading.dismiss();
  //       } catch (e) {
  //         AppLogger.error('清理Loading遮罩失败: $e');
  //       }
        
  //       // 确保UI状态正确恢复
  //       if (mounted) {
  //         setState(() {
  //         });
  //       }
  //       // 调用页面恢复机制
  //       _restorePageState();
  //       _attachLocationCallbacks();
  //       if (!_locationPollingManager.isPolling) {
  //         _locationPollingManager.startPolling();
  //       }
  //       break;
  //     case AppLifecycleState.inactive:
  //       AppLogger.info('应用进入非活动状态，保持回调并确保轮询运行');
  //       _attachLocationCallbacks();
  //       if (!_locationPollingManager.isPolling) {
  //         _locationPollingManager.startPolling();
  //       }
  //       break;
  //     case AppLifecycleState.paused: // 息屏待机
  //       AppLogger.info('应用进入后台（息屏待机），解绑回调但保持轮询运行');
  //       _detachLocationCallbacks();
  //       // 确保轮询继续运行，不受息屏影响
  //       if (!_locationPollingManager.isPolling) {
  //         _locationPollingManager.startPolling();
  //       }
  //       break;
  //     case AppLifecycleState.detached: // 退出
  //       break;
  //   }
  // }

  // 初始化
  void _initializeBasicUI() {
    setState(() {
      menus = [
        MenuItem(
          name: '交接',
          index: 1,
          unselectedIcon: 'assets/storage/inner_unselected.svg',
          selectedIcon: 'assets/storage/inner_selected.svg',
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
    // 移除应用生命周期监听
    WidgetsBinding.instance.removeObserver(this);

    // 确保动画控制器正确释放
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
    _animationController.dispose();
    
    // 清空回调，避免已销毁页面触发UI更新
    // _locationPollingManager.setCallbacks(onLocationUpdate: null, onError: null);
    
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
            Navigator.pushNamed(context, menu.route!,
                arguments: {'mode': menu.mode});
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
    // 添加额外的安全检查，防止黑屏
    if (!mounted) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF29A8FF)),
          ),
        ),
      );
    }
    
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
    
    // 安全检查页面索引
    if (_pages.isEmpty || _selectedIndex >= _pages.length) {
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
                '页面加载中...',
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
    
    // 确保当前页面有效
    final currentPage = _pages[_selectedIndex];
    if (currentPage == null) {
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
                '页面恢复中...',
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
      body: currentPage,
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
                // 安全检查索引范围
                if (index >= 0 && index < menus.length) {
                  setState(() {
                    _selectedIndex = index;
                    AppLogger.info('selectedIndex: $_selectedIndex');
                  });
                } else {
                  AppLogger.error('无效的页面索引: $index');
                }
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
