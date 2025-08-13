import 'package:flutter/material.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:flutter/services.dart'; // 顶部引入

class PersonalCenterPage extends StatelessWidget {
  const PersonalCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '个人中心',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 顶部渐变信息区
            _buildTopProfile(context),
            const SizedBox(height: 5),
            // 功能区块
            ..._buildMenuList(context),
            const SizedBox(height: 20), // 替换 Spacer，添加固定间距
            // 退出登录按钮
            _buildLogoutButton(),
            const SizedBox(height: 20), // 底部间距
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
          height: 80,
        ),
        // 头像和信息
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                // Container(
                //   child: const CircleAvatar(
                //     radius: 38,
                //     backgroundColor: Color.fromARGB(255, 128, 189, 243),
                //   ),
                // ),
                // const SizedBox(height: 10),
                Text(
                  'admin',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 107, 106, 106),
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '角色: 超级管理员',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color.fromARGB(255, 107, 106, 106),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMenuList(BuildContext context) {
    final List<_MenuItemData> menuItems = [
      // _MenuItemData(
      //   icon: Icons.import_contacts_outlined,
      //   iconBg: const Color.fromARGB(255, 87, 79, 247),
      //   title: '导入EXCEL表',
      //   onTap: () {
      //     Navigator.push<void>(
      //       context,
      //       MaterialPageRoute<void>(
      //           builder: (context) => const ImportExcelPage()),
      //     );
      //   },
      // ),
      _MenuItemData(
        icon: Icons.devices,
        iconBg: const Color(0xFF81C784),
        title: '设备管理',
        onTap: () {
          Navigator.pushNamed(context, '/personal_center/dev-url-management');
        },
      ),
      _MenuItemData(
        icon: Icons.gif_box_rounded,
        iconBg: const Color(0xFFFFB74D),
        title: '托盘管理',
        onTap: () {
          Navigator.pushNamed(context, '/personal_center/shelf-management');
        },
      ),
      _MenuItemData(
        icon: Icons.place,
        iconBg: const Color(0xFFBA68C8),
        title: '地标管理',
        onTap: () {
          Navigator.pushNamed(context, '/personal_center/location-management');
        },
      ),
      _MenuItemData(
        icon: Icons.border_clear_rounded,
        iconBg: const Color.fromARGB(255, 72, 195, 209),
        title: '库区管理',
        onTap: () {
          Navigator.pushNamed(
              context, '/personal_center/area-management');
        },
      ),
    ];
    return menuItems
        .map((item) => Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14.0, vertical: 4), // 左右间距24，上下间距4
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8), // 左右间距10，上下间距10
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


  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 18), // 底部留白
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
        onPressed: () {
          SystemNavigator.pop(); // 退出APP
        },
        child: const Text('退出登录',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
