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

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  late final FaceLoginProvider _faceLoginProvider;
  late final VerifyTokenProvider _verifyTokenProvider;
  late final Service18082 _loginService;

  @override
  void initState() {
    super.initState();
    _faceLoginProvider = FaceLoginProvider();
    _loginService = Service18082();
    _verifyTokenProvider = Provider.of<VerifyTokenProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 登录提交
  Future<void> _login() async {
    try {
      final faceImage1 = _faceLoginProvider.getFaceImage(0);
      final username1 = _faceLoginProvider.getUsername(0);
      final password1 = _faceLoginProvider.getPassword(0);
      
      // 验证数据
      if (username1 == null || username1.isEmpty) {
        throw Exception('请输入用户名');
      }
      
      if (_faceLoginProvider.isFaceLogin(0)) {
        if (faceImage1 == null || faceImage1.isEmpty) {
          throw Exception('请进行人脸拍照');
        }
      } else {
        if (password1 == null || password1.isEmpty) {
          throw Exception('请输入密码');
        }
      }

      if (username1 == null || password1 == null) {
        throw Exception('用户名或密码不能为空');
      }

      final hashedPassword = md5.convert(utf8.encode(password1)).toString();
      setState(() {
        _isLoading = true;
      });
      // final hashedPassword = md5.convert(utf8.encode(password1 + 'messi')).toString();
      final Map<String, dynamic> loginResult = await _loginService.accountLogin(username1, hashedPassword);
      // 存储登录响应数据
      _verifyTokenProvider.setToken(loginResult['access_token'].toString());
      _verifyTokenProvider.setUserData(<String, dynamic>{
        'username': username1,
        'access_token': loginResult['access_token'],
        'refresh_token': loginResult['refresh_token'],
        'expires_in': loginResult['expires_in'],
        'token_type': loginResult['token_type'],
        'scope': loginResult['scope'],
      });
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      ErrorHandler.handleError(context, e);
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

    return ChangeNotifierProvider.value(
      value: _faceLoginProvider,
      child: DefaultTabController(
        length: 2,
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
                                    Tab(text: '押运员1'),
                                    Tab(text: '押运员2'),
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
                                    // 押运人员1的输入框
                                    FaceLogin(personIndex: 0),
                                    // 押运人员2的输入框
                                    FaceLogin(personIndex: 1),
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
                bottom: 30,
                child: Center(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF29A8FF),
                      minimumSize: Size(screenWidth * 0.85, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: Color(0xFF29A8FF),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            '登录',
                            style: TextStyle(color: Color.fromARGB(255, 241, 240, 240), fontSize: 16),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
