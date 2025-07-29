import 'dart:typed_data';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tj_tms_mobile/presentation/pages/plugins/plugin_test_page.dart';

import '../../../data/datasources/api/18082/service_18082.dart'; // 确保导入插件测试页

// 菜单项模型
class MenuItem {
  final String name;
  final String? imagePath;
  final String? iconPath;
  final IconData? icon;
  final List<MenuItem>? children;
  final String? route;
  final Color? color;
  final int? mode;

  MenuItem({
    required this.name,
    this.imagePath,
    this.iconPath,
    this.icon,
    this.children,
    this.route,
    this.color,
    this.mode,
  });
}

class User {
  final String userNo;       // 用户编号
  final String userName;     // 用户姓名
  final String numId;        // 身份证号
  final String cocn;         // 人脸base64
  final String avatar;       // 头像
  final String phone;        // 手机号
  final String role;         // 角色

  User({
    required this.userNo,
    required this.userName,
    required this.numId,
    required this.cocn,
    required this.avatar,
    required this.phone,
    required this.role,
  });
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userNo: json['userNo'] as String,
      userName: json['userName'] as String,
      numId: json['numId'] as String,
      cocn: json['cocn'] as String,
      avatar: json['avatar'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
    );
  }
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
  //todo 后续需换成实际登陆用户
  // 在HomePage中更新模拟数据
  User currentUser = User(
    userNo: '00000001',
    userName: '张三',
    numId: '110101199003072536',
    cocn: '', // 这里放base64字符串
    avatar: 'assets/icons/user_person.svg',
    phone: '13800138000',
    role: '管理员',
  );

  final List<User> users = [
    User(
      userNo: '00000002',
      userName: '李四',
      numId: '110101198502143215',
      cocn: '', // 这里放base64字符串
      avatar: 'assets/icons/user_person.svg',
      phone: '13900139000',
      role: '操作员',
    ),
  ];

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
          mode: 0,
        ),
        MenuItem(
          name: '金库交接',
          imagePath: 'assets/icons/treasury_reat.svg',
          iconPath: 'assets/icons/treasury_handover_icon.svg',
          route: '/outlets/box-handover',
          color: const Color.fromARGB(255, 134, 221, 245).withOpacity(0.1),
          mode: 1,
        ),
      ],
    ),
    MenuItem(
      name: '我的',
      icon: Icons.person_rounded,
      route: '/user-list',
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
        } else if (menu.route == '/user-list') {
          // 添加用户列表页面
          _pages.add(_buildUserListPage());
        } else if (menu.route == '/plugin-test') {
          // 添加插件测试页面
          _pages.add(const PluginTestPage());
        }
      }
    });
  }

  // 构建用户列表页面
  Widget _buildUserListPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 245, 246, 250),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Container(
        color: const Color.fromARGB(255, 245, 246, 250),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 押运员1标题
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text(
                '押运员1',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 当前用户信息卡片（紧凑版）
            _buildCompactUserCard(currentUser, isCurrentUser: true),
            const SizedBox(height: 16),
            // 押运员2标题
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text(
                '押运员2',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return _buildCompactUserCard(users[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

// 构建紧凑版用户卡片（统一样式）
  Widget _buildCompactUserCard(User user, {bool isCurrentUser = false}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => UserDetailPage(userNo: user.userNo),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          height: 60, // 固定高度使卡片更紧凑
          child: Row(
            children: [
              SvgPicture.asset(
                user.avatar,
                width: 40, // 缩小头像尺寸
                height: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${user.userName} ${user.userNo}',
                  style: const TextStyle(
                    fontSize: 16, // 稍小字体
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
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
          splashColor: Colors.transparent, // 点击时没有水波纹效果
          highlightColor: Colors.transparent, // 点击时没有高亮效果
          onTap: () {
            if (menu.route != null) {
              // 根据路由判断是哪个页面，并传递 mode 参数
              if (menu.route == '/outlets/box-scan') {
                Navigator.pushNamed(context, menu.route!, arguments: {'mode': menu.mode});
              } else if (menu.route == '/outlets/box-handover') {
                Navigator.pushNamed(context, menu.route!, arguments: {'mode': menu.mode});
              } else {
                Navigator.pushNamed(context, menu.route!);
              }
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

  // 注销登录
  void _logout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定要退出当前账号吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // 关闭对话框
                Navigator.pop(context); // 返回上一页
                // 这里可以添加实际的退出登录逻辑
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('退出'),
            ),
          ],
        );
      },
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

// 更新用户详情页面
class UserDetailPage extends StatefulWidget {
  final String userNo; // 通过用户编号查询

  const UserDetailPage({super.key, required this.userNo});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  late final Service18082 _service;
  User? _user;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _service = Service18082(); // 初始化 _service
    _fetchUserData(widget.userNo);
  }
  Uint8List base64Decode(String source) {
    return base64.decode(source);
  }
  // 模拟从后端获取用户数据
  Future<void> _fetchUserData(String escortNo) async {
    try {
      if (escortNo.isEmpty) {
        // 2. 在使用 context 之前检查 mounted
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('编号不能为空')),
        );
        return;
      }
      // 保持 isLoading 为 true
      if (!mounted) return;
      setState(() => _isLoading = true);
      final Map<String, dynamic> response = await _service.getEscortByNo(escortNo);
      print("response $response");
      if (!mounted) return;

      if (response['retCode'] == '000000') {
        setState(() {
          // 在 setState 中同时更新 _user 和 _isLoading
          final userData = <String, dynamic>{
            'userNo': response['userNo']??'',
            'userName': response['userName']??'',
            'numId': response['numId']??'',
            'cocn': response['cocn']??'',
            'avatar': response['avatar']??'',
            'phone': response['phone']??'',
            'role': response['role']??'',
          };
          _user = User.fromJson(userData);
          _isLoading = false;
        });
      } else {
        print('未能加载用户数据: ${response['retMsg']}');
        throw Exception('未能加载用户数据: ${response['retMsg']}');
      }
    } catch (e) {
      // 2. 在使用 context 之前检查 mounted
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: ${e.toString()}')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人信息'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _logout(context),
          ),
        ],
      ),
        // 3. 修改这里的判断逻辑
        body: (_isLoading || _user == null)
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // 4. 使用 _user! (空安全断言)，因为我们已经检查过它不为 null
          _user!.cocn.isNotEmpty
              ? CircleAvatar(
            radius: 60,
            backgroundImage: MemoryImage(
              base64Decode(_user!.cocn),
            ),
          )
              : CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            child: SvgPicture.asset(
              _user!.avatar,
              width: 100,
              height: 100,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _user!.userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _user!.role,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),
          _buildInfoItem('用户编号', _user!.userNo),
          _buildInfoItem('身份证号', _user!.numId),
          _buildInfoItem('手机号码', _user!.phone),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _showChangePasswordDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF29A8FF),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              '修改密码',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    ),
    );
  }


  Widget _buildInfoItem(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('修改密码'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '当前密码',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '新密码',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '确认新密码',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF29A8FF),
              ),
              child: const Text('确认修改'),
            ),
          ],
        );
      },
    );
  }

  void _changePassword() {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('两次输入的新密码不一致')),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码长度不能少于6位')),
      );
      return;
    }

    // 这里添加实际的密码修改逻辑
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('密码修改成功')),
    );

    // 清空输入框
    _passwordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  void _logout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定要退出当前账号吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // 关闭对话框
                Navigator.pop(context); // 返回用户列表页
                // 这里可以添加实际的退出登录逻辑
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('退出'),
            ),
          ],
        );
      },
    );
  }
}