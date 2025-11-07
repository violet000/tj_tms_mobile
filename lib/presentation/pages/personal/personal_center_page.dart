import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:tj_tms_mobile/presentation/state/providers/verify_token_provider.dart';
import 'package:tj_tms_mobile/presentation/state/providers/face_login_provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:tj_tms_mobile/core/utils/util.dart' as app_utils;
import 'package:tj_tms_mobile/services/interval_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tj_tms_mobile/core/utils/location_helper.dart';
import 'package:tj_tms_mobile/services/foreground_service_manager.dart';
import 'package:tj_tms_mobile/data/datasources/interceptor/dio_service.dart';

class PersonalCenterPage extends StatefulWidget {
  const PersonalCenterPage({super.key});

  @override
  State<PersonalCenterPage> createState() => _PersonalCenterPageState();
}

class _PersonalCenterPageState extends State<PersonalCenterPage> {
  Map<String, dynamic> _deviceInfo = <String, dynamic>{};
  bool _isLoadingDeviceInfo = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final info = await app_utils.loadDeviceInfo();
      if (!mounted) return;
      setState(() {
        _deviceInfo = info ?? <String, dynamic>{};
        _isLoadingDeviceInfo = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deviceInfo = <String, dynamic>{};
        _isLoadingDeviceInfo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '个人中心',
      bottomWidget: _buildLogoutButton(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 顶部渐变信息区
            _buildTopProfile(context),
            const SizedBox(height: 5),
            // 功能区块
            ..._buildMenuList(context),
            const SizedBox(height: 10), // 替换 Spacer，添加固定间距
            // 设备信息展示
            FutureBuilder<Widget>(
              future: _buildDeviceInfoSection(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return snapshot.data ?? const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 20), // 底部留白，避免与底部按钮贴合
          ],
        ),
      ),
    );
  }

  Widget _buildTopProfile(BuildContext context) {
    return Stack(
      children: [
        // 渐变背景
        Container(
          height: 30,
        )
      ],
    );
  }

  List<Widget> _buildMenuList(BuildContext context) {
    // 获取所有登录用户信息
    final verifyTokenProvider =
        Provider.of<VerifyTokenProvider>(context, listen: false);
    final allUsersData = verifyTokenProvider.getAllUsersData();

    List<_MenuItemData> menuItems = [];

    // 为每个用户生成菜单项
    for (int i = 0; i < allUsersData.length; i++) {
      final userData = allUsersData[i];
      final username = userData['username']?.toString() ?? '未知用户';

      menuItems.add(_MenuItemData(
        icon: Icons.person,
        iconBg: _getUserColor(i),
        title: '押运员${i + 1}: $username',
        onTap: () {
          Navigator.pushNamed(
            context,
            '/personal/detail',
            arguments: {
              'userData': userData,
              'userIndex': i + 1,
            },
          );
        },
      ));
    }

    return menuItems
        .map((item) => Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14.0, vertical: 4),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 54,
                      decoration: BoxDecoration(
                        color: item.iconBg.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(item.icon, size: 20, color: item.iconBg),
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.normal),
                    ),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: item.onTap,
                  ),
                ),
              ),
            ))
        .toList();
  }

  // 根据用户索引获取不同的颜色
  Color _getUserColor(int index) {
    final colors = [
      const Color(0xFF2196F3), // 蓝色
      const Color(0xFF4CAF50), // 绿色
      const Color(0xFFFF9800), // 橙色
      const Color(0xFF9C27B0), // 紫色
      const Color(0xFFF44336), // 红色
    ];
    return colors[index % colors.length];
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12), // 底部留白
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 225, 20, 20),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        onPressed: () async {
          await _handleLogout();
        },
        child: const Text('退出登录',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }

  /// 退出登录并清除所有数据
  Future<void> _handleLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('agps_interval_seconds');
      await prefs.remove('current_interval_seconds');
      await prefs.remove('location_polling_interval_secs');
      final verifyTokenProvider = Provider.of<VerifyTokenProvider>(context, listen: false);
      verifyTokenProvider.clearToken();
      final faceLoginProvider = Provider.of<FaceLoginProvider>(context, listen: false);
      faceLoginProvider.clearData(0);
      faceLoginProvider.clearData(1);
      DioServiceManager().clearAccessTokenForAll();
      SystemNavigator.pop();
    } catch (e) {
      // 如果清除数据失败，仍然退出APP
      SystemNavigator.pop();
    }
  }

  Future<Widget> _buildDeviceInfoSection() async {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '设备信息',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isLoadingDeviceInfo)
                const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                ...await _buildDeviceInfoItems(),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Widget>> _buildDeviceInfoItems() async {
    final List<Widget> items = [];
    int effectiveInterval = 0;
    
    try {
      effectiveInterval = await IntervalManager.getEffectiveInterval();
    } catch (e) {
      effectiveInterval = 0;
    }

    if (Platform.isAndroid) {
      items.addAll([
        _buildInfoItem('AGPS间隔', '${effectiveInterval}秒'),
        _buildInfoItem('设备型号', (_deviceInfo['model'] as String?) ?? '未知'),
        _buildInfoItem('制造商', (_deviceInfo['manufacturer'] as String?) ?? '未知'),
        _buildInfoItem(
            'Android版本', (_deviceInfo['version'] as String?) ?? '未知'),
        _buildInfoItem('SDK版本', '${_deviceInfo['sdkInt'] ?? '未知'}'),
        _buildInfoItem('设备ID', (_deviceInfo['deviceId'] as String?) ?? '未知'),
      ]);
    } else if (Platform.isIOS) {
      items.addAll([
        _buildInfoItem('设备名称', (_deviceInfo['name'] as String?) ?? '未知'),
        _buildInfoItem('设备型号', (_deviceInfo['model'] as String?) ?? '未知'),
        _buildInfoItem(
            '系统版本', (_deviceInfo['systemVersion'] as String?) ?? '未知'),
        _buildInfoItem('设备ID', (_deviceInfo['deviceId'] as String?) ?? '未知'),
      ]);
    }

    return items;
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final Color iconBg;
  final String title;
  final VoidCallback onTap;
  const _MenuItemData(
      {required this.icon,
      required this.iconBg,
      required this.title,
      required this.onTap});
}
