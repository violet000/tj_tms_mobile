import 'package:flutter/material.dart';
import 'package:tj_tms_mobile/core/errors/error_handler.dart';
import 'package:tj_tms_mobile/data/datasources/remote/api_service.dart';
import 'package:tj_tms_mobile/presentation/pages/login/face_login/face_login.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final ApiService _apiService = ApiService(
    baseUrl: 'https://api.example.com',
  );

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.post(
        '/login',
        body: <String, String>{
          'username': _usernameController.text,
          'password': _passwordController.text,
        },
      );
      
      // TODO: 处理登录成功逻辑
      print('登录成功: $response');
      
    } catch (e) {
      ErrorHandler.handleAuthError(context, e);
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
      length: 2,
      child: Scaffold(
        body: Stack(
          children: [
            // 蓝色背景部分
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topSectionHeight,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
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
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Text(
                      '天津银行外勤配送系统',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 237, 238, 239),
                      ),
                    ),
                  ),
                  Container(
                    width: screenWidth * 0.85,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
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
                        children: const [
                          // Tab切换栏
                          TabBar(
                            indicator: UnderlineTabIndicator(
                              borderSide: BorderSide(
                                width: 5,
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
                          SizedBox(height: 20),
                          
                          // Tab内容
                          SizedBox(
                            height: 230,
                            child: TabBarView(
                              physics: NeverScrollableScrollPhysics(),
                              children: [
                                // 押运人员1的输入框
                                FaceLogin(),
                                // 押运人员2的输入框
                                FaceLogin(),
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
          ],
        ),
      ),
    );
  }
}