import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tj_tms_mobile/data/datasources/api/api.dart';
import 'package:tj_tms_mobile/core/errors/error_handler.dart';
import 'package:tj_tms_mobile/presentation/pages/login/face_login/face_login.dart';
import 'package:tj_tms_mobile/presentation/state/providers/face_login_provider.dart';
import 'package:tj_tms_mobile/presentation/state/providers/verify_token_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:tj_tms_mobile/presentation/pages/setting/network_settings_page.dart';
import 'package:tj_tms_mobile/core/utils/common_util.dart' as app_utils;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tj_tms_mobile/core/config/env.dart';
import 'package:tj_tms_mobile/data/datasources/interceptor/dio_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  Map<String, dynamic> _deviceInfo = <String, dynamic>{};
  bool _isLoading = false;

  late final VerifyTokenProvider _verifyTokenProvider;
  Service18082? _loginService;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _initializeLoginService();
    _verifyTokenProvider =
        Provider.of<VerifyTokenProvider>(context, listen: false);

    // Prefill user and ensure password mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final faceLoginProvider =
          Provider.of<FaceLoginProvider>(context, listen: false);
      // 用于快速测试，自动填入账号与密码
      faceLoginProvider.setUsername(0, '00000001');
      faceLoginProvider.setPassword(0, 'Aa123789!');

      // 切换为账号密码登录模式（如果当前为人脸模式）
      if (faceLoginProvider.isFaceLogin(0)) {
        faceLoginProvider.toggleLoginMode(0);
      }
    });
  }

  Future<void> _initializeLoginService() async {
    _loginService = await Service18082.create();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceInfo() async {
    final info = await app_utils.loadDeviceInfo();
    if (!mounted) return;
    setState(() {
      _deviceInfo = info;
    });
  }

  // 验证表单
  bool _validateFormData(
      String? username, String? password, String? faceImage) {
    if (username == null || username.isEmpty) {
      throw Exception('请输入用户名');
    }

    if ((password == null || password.isEmpty) &&
        (faceImage == null || faceImage.isEmpty)) {
      throw Exception('请输入密码或进行人脸拍照');
    }

    return true;
  }

  // 保存登录数据
  Future<void> _saveLoginData(
      String username, Map<String, dynamic> loginResult) async {
    // 设置用户的token作为当前token
    _verifyTokenProvider.setToken(loginResult['access_token'].toString());

    // 保存token到SharedPreferences，供其他服务使用
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'access_token', loginResult['access_token'].toString());

    // 保存用户数据到列表
    _verifyTokenProvider.addUserData(<String, dynamic>{
      'username': username,
      'access_token': loginResult['access_token'],
      'refresh_token': loginResult['refresh_token'],
      'expires_in': loginResult['expires_in'],
      'token_type': loginResult['token_type'],
      'scope': loginResult['scope'],
    });

    // 设置当前用户数据
    _verifyTokenProvider.setUserData(<String, dynamic>{
      'username': username,
      'access_token': loginResult['access_token'],
      'refresh_token': loginResult['refresh_token'],
      'expires_in': loginResult['expires_in'],
      'token_type': loginResult['token_type'],
      'scope': loginResult['scope'],
    });

    // 保存押运员信息到全局的 FaceLoginProvider
    final faceLoginProvider =
        Provider.of<FaceLoginProvider>(context, listen: false);
    faceLoginProvider.setUsername(0, username);
  }

  // 登录提交
  Future<void> _login() async {
    try {
      // // 确保登录服务已初始化
      // if (_loginService == null) {
      //   await _initializeLoginService();
      // }

      // // 获取全局的 FaceLoginProvider
      // final faceLoginProvider =
      //     Provider.of<FaceLoginProvider>(context, listen: false);

      // final faceImage = faceLoginProvider.getFaceImage(0);
      // final username = faceLoginProvider.getUsername(0) ?? '';
      // final password = faceLoginProvider.getPassword(0) ?? '';

      // // 在登录前，先将押运员信息保存到全局的 FaceLoginProvider
      // faceLoginProvider.setUsername(0, username);

      // // 验证数据
      // _validateFormData(username, password, faceImage);

      // setState(() {
      //   _isLoading = true;
      // });

      // EasyLoading.show(
      //   status: '登录中...',
      //   maskType: EasyLoadingMaskType.black,
      // );

      // if (_loginService == null) {
      //   await _initializeLoginService();
      // }
      // print(<String, dynamic>{
      //   'username': username,
      //   'password': (password == null || password.isEmpty)
      //       ? null
      //       : md5.convert(utf8.encode(password + 'messi')).toString(),
      //   'face': faceImage,
      //   'handheldNo': _deviceInfo['deviceId'] ?? '',
      //   'isImport': true
      // });
      // final Map<String, dynamic> loginResult =
      //     await _loginService!.accountLogin([
      //   <String, dynamic>{
      //     'username': username,
      //     'password': (password == null || password.isEmpty)
      //         ? null
      //         : md5.convert(utf8.encode(password + 'messi')).toString(),
      //     'face': faceImage,
      //     'handheldNo': _deviceInfo['deviceId'] ?? '',
      //     'isImport': true
      //   }
      // ]);

      // await _saveLoginData(username, loginResult);

      // EasyLoading.dismiss();
      // EasyLoading.showSuccess('登录成功');

      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      EasyLoading.dismiss();
      ErrorHandler.handleError(context, e);
      EasyLoading.showError('登录失败: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final topSectionHeight = screenHeight * 0.4; // 40% 的高度用于蓝色背景

    return DefaultTabController(
      length: 1,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // 蓝色背景部分
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topSectionHeight,
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFF29A8FF),
                          Color(0xFF0489FE),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: SvgPicture.asset(
                      'assets/icons/n_font.svg',
                      width: 80,
                      height: 80,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
            // 白色背景部分
            Positioned(
              top: topSectionHeight,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.white,
              ),
            ),
            // 登录表单
            Positioned(
              top: topSectionHeight * 0.25,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20, left: 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "你好",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 237, 238, 239),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "欢迎登录天津银行外勤配送系统",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 237, 238, 239),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: screenWidth * 0.85,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tab切换栏
                            Transform.translate(
                              offset: const Offset(0, -10),
                              child: const TabBar(
                                padding: EdgeInsets.only(top: 0),
                                indicator: UnderlineTabIndicator(
                                  borderSide: BorderSide(
                                    width: 3,
                                    color: Colors.blue,
                                  ),
                                ),
                                labelColor: Colors.black,
                                unselectedLabelColor: Colors.grey,
                                labelStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                unselectedLabelStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                                tabs: [
                                  Tab(text: '押运员'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Tab内容
                            const SizedBox(
                              height: 230,
                              child: TabBarView(
                                physics: NeverScrollableScrollPhysics(),
                                children: [
                                  // 押运人员的输入框
                                  FaceLogin(personIndex: 0),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 登录按钮
            Positioned(
              left: 0,
              right: 0,
              bottom: 50,
              child: Center(
                child: Column(
                  children: [
                    Consumer<FaceLoginProvider>(
                      builder: (context, faceLoginProvider, child) {
                        final faceImage = faceLoginProvider.getFaceImage(0);
                        final username = faceLoginProvider.getUsername(0);
                        final password = faceLoginProvider.getPassword(0);

                        // 检查押运员：faceImage和username有值 或者 username和password有值
                        bool personValid = (faceImage != null &&
                                faceImage.isNotEmpty &&
                                username != null &&
                                username.isNotEmpty) ||
                            (username != null &&
                                username.isNotEmpty &&
                                password != null &&
                                password.isNotEmpty);

                        bool isLoginEnabled = personValid && !_isLoading;

                        return ElevatedButton(
                          onPressed: isLoginEnabled ? _login : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF29A8FF),
                            minimumSize: Size(screenWidth * 0.85, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledBackgroundColor:
                                const Color.fromARGB(255, 228, 227, 227),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  '登录',
                                  style: TextStyle(
                                      color: isLoginEnabled
                                          ? Color.fromARGB(255, 241, 240, 240)
                                          : Colors.grey.shade600,
                                      fontSize: 16),
                                ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                              builder: (context) =>
                                  const NetworkSettingsPage()),
                        );
                      },
                      child: Text(
                        '设置网络',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF29A8FF),
                        ),
                      ),
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all(EdgeInsets.zero),
                        minimumSize: MaterialStateProperty.all(Size(0, 0)),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        overlayColor: MaterialStateProperty.all(Colors.white24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
