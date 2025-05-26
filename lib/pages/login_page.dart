import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';

// ignore: slash_for_doc_comments
/**
 * @author: kychen
 * @date: 2025-04-18
 * @description: 登录页面
 */
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey1 = GlobalKey<FormState>(); // 第一个用户的表单key
  final _formKey2 = GlobalKey<FormState>(); // 第二个用户的表单key
  final _usernameController1 = TextEditingController(); // 第一个用户的用户名控制器
  final _passwordController1 = TextEditingController(); // 第一个用户的密码控制器
  final _usernameController2 = TextEditingController(); // 第二个用户的用户名控制器
  final _passwordController2 = TextEditingController(); // 第二个用户的密码控制器
  bool _isLoading = false; // 是否正在加载
  bool _obscurePassword1 = true; // 第一个用户是否隐藏密码
  bool _obscurePassword2 = true; // 第二个用户是否隐藏密码
  File? _imageFile1; // 第一个用户的图片文件
  File? _imageFile2; // 第二个用户的图片文件
  final ImagePicker _picker = ImagePicker(); // 创建ImagePicker实例
  bool _isAccountVerified1 = false; // 第一个用户是否已通过账号验证
  bool _isAccountVerified2 = false; // 第二个用户是否已通过账号验证

  // 登录人员列表
  final List<Map<String, String>> _loginUsers = [
    {'name': '押运员1', 'id': '001'},
    {'name': '押运员2', 'id': '002'},
  ];

  @override
  void dispose() {
    _usernameController1.dispose();
    _passwordController1.dispose();
    _usernameController2.dispose();
    _passwordController2.dispose();
    super.dispose();
  }

  Future<void> _takePhoto(int userIndex) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear, // 使用后置摄像头
      );
      if (photo != null) {
        setState(() {
          if (userIndex == 0) {
            _imageFile1 = File(photo.path);
          } else {
            _imageFile2 = File(photo.path);
          }
        });

        // 调用照片验证
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        // 清除对应的账号验证状态
        if (userIndex == 0) {
          authProvider.clearAccountVerification1();
        } else {
          authProvider.clearAccountVerification2();
        }
        await authProvider.verifyWithPhoto(
          userIndex: userIndex,
          photoPath: photo.path,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拍照失败: $e')),
        );
      }
    }
  }

  Future<void> _showAccountLoginDialog(int userIndex) async {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController(
      text: userIndex == 0
          ? _usernameController1.text
          : _usernameController2.text,
    );
    final passwordController = TextEditingController(
      text: userIndex == 0
          ? _passwordController1.text
          : _passwordController2.text,
    );
    bool obscurePassword = true;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '账号登录',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            labelText: '用户名',
                            prefixIcon: Icon(Icons.person, size: 16),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入用户名';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: '密码',
                            prefixIcon: const Icon(Icons.lock, size: 16),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 16,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入密码';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            // 保存账号信息
                            if (userIndex == 0) {
                              _usernameController1.text =
                                  usernameController.text;
                              _passwordController1.text =
                                  passwordController.text;
                            } else {
                              _usernameController2.text =
                                  usernameController.text;
                              _passwordController2.text =
                                  passwordController.text;
                            }

                            // 调用账号登录
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final success = await authProvider.loginWithAccount(
                              userIndex: userIndex,
                              username: usernameController.text,
                              password: passwordController.text,
                            );

                            if (success && mounted) {
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: const Text('确认'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _canSubmit() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // 检查是否所有用户都已完成登录准备
    if (authProvider.isAccountVerified1 && authProvider.isAccountVerified2) {
      // 两个用户都是账号验证
      return true;
    } else if (authProvider.isPhotoVerified1 && authProvider.isPhotoVerified2) {
      // 两个用户都是照片登录
      return true;
    } else {
      // 混合登录方式
      if (authProvider.isAccountVerified1 && authProvider.isPhotoVerified2) {
        return true;
      } else if (authProvider.isPhotoVerified1 && authProvider.isAccountVerified2) {
        return true;
      }
      return false;
    }
  }

  void _handleSubmit() async {
    if (!_canSubmit()) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('提示'),
            ],
          ),
          content: const Text('请先完成所有登录信息!'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.submitVerification();

    if (success && mounted) {
      // 登录成功后导航到主页
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  // 删除照片
  void _deletePhoto(int userIndex) {
    setState(() {
      if (userIndex == 0) {
        _imageFile1 = null;
      } else {
        _imageFile2 = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕尺寸
    final size = MediaQuery.of(context).size;
    // 计算动态边距
    final horizontalPadding = size.width * 0.05; // 水平边距为屏幕宽度的5%
    final verticalPadding = size.height * 0.02; // 垂直边距为屏幕高度的2%

    // 定义主题色
    final primaryColor = const Color(0xFF1976D2); // 深蓝色
    final accentColor = const Color(0xFFE3F2FD); // 非常淡的蓝色
    final backgroundColor = const Color(0xFFF0F4F8); // 更柔和的灰蓝色背景
    final textColor = const Color(0xFF455A64); // 更柔和的蓝灰色文字
    final secondaryTextColor = const Color(0xFF78909C); // 次要文字颜色
    final borderColor = const Color(0xFFE0E0E0); // 浅灰色边框

    // 监听 AuthProvider 的状态变化
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accentColor.withOpacity(0.8),
              backgroundColor,
              backgroundColor.withOpacity(0.9),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 应用标题
              Container(
                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                decoration: BoxDecoration(
                  color: accentColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '外勤配送登录',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              // 登录区域
              Expanded(
                child: Row(
                  children: [
                    // 第一个用户登录区域
                    Expanded(
                      child: _buildUserLoginSection(
                        userIndex: 0,
                        userName: _loginUsers[0]['name']!,
                        imageFile: _imageFile1,
                        isAccountVerified: authProvider.isAccountVerified1,
                        primaryColor: primaryColor,
                        accentColor: accentColor,
                        borderColor: borderColor,
                      ),
                    ),

                    // 分隔线
                    Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      color: borderColor,
                    ),

                    // 第二个用户登录区域
                    Expanded(
                      child: _buildUserLoginSection(
                        userIndex: 1,
                        userName: _loginUsers[1]['name']!,
                        imageFile: _imageFile2,
                        isAccountVerified: authProvider.isAccountVerified2,
                        primaryColor: primaryColor,
                        accentColor: accentColor,
                        borderColor: borderColor,
                      ),
                    ),
                  ],
                ),
              ),

              // 统一的提交按钮
              Container(
                padding: EdgeInsets.all(horizontalPadding),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Flex(
                    direction: Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        flex: 4,
                        child: ElevatedButton(
                          onPressed:
                              authProvider.isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  '登录',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 36,
                        child: TextButton(
                          onPressed: _handleSettings,
                          style: TextButton.styleFrom(
                            foregroundColor: secondaryTextColor,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.settings,
                                size: 16,
                                color: secondaryTextColor,
                              ),
                              Text(
                                "设置",
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 13,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: verticalPadding),
            ],
          ),
        ),
      ),
    );
  }

  // 设置页面
  void _handleSettings() {
    print("打开设置页面");
    Navigator.pushNamed(context, AppRoutes.settings);
  }

  // 用户登录区
  Widget _buildUserLoginSection({
    required int userIndex,
    required String userName,
    required File? imageFile,
    required bool isAccountVerified,
    required Color primaryColor,
    required Color accentColor,
    required Color borderColor,
  }) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isPhotoVerified = userIndex == 0 ? authProvider.isPhotoVerified1 : authProvider.isPhotoVerified2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // 用户名称和切换按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                userName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: () => _showAccountLoginDialog(userIndex),
                icon: const Icon(Icons.person, size: 16),
                label: const Text('账号登录', style: TextStyle(fontSize: 14)),
                style: TextButton.styleFrom(
                  foregroundColor:
                      isAccountVerified ? Colors.green : primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(100, 36),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 验证状态提示
          if (isAccountVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '已录入人员账号',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (isPhotoVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '已拍摄人员照片',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (!isAccountVerified && !isPhotoVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '请选择录入方式',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // 照片预览区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              imageFile,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.camera_alt,
                              size: 32,
                              color: primaryColor.withOpacity(0.5),
                            ),
                          ),
                  ),
                  if (imageFile != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _deletePhoto(userIndex),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 拍照按钮
          ElevatedButton.icon(
            onPressed: () => _takePhoto(userIndex),
            icon: const Icon(Icons.camera_alt, size: 16),
            label: Text(
              imageFile != null ? '重新拍摄' : '拍摄照片',
              style: const TextStyle(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              minimumSize: const Size(120, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
