// 存储/获取token
import 'package:flutter/foundation.dart';

class VerifyTokenProvider extends ChangeNotifier {
  String? access_token;
  Map<String, dynamic>? _userData;
  
  VerifyTokenProvider({required this.access_token});

  // 设置token
  void setToken(String token) {
    access_token = token;
    notifyListeners();
  }

  // 获取token
  String? getToken() => access_token;

  // 清除token
  void clearToken() {
    access_token = '';
    _userData = null;
    notifyListeners();
  }

  // 设置用户数据
  void setUserData(Map<String, dynamic> data) {
    _userData = data;
    notifyListeners();
  }

  // 获取用户数据
  Map<String, dynamic>? getUserData() => _userData;
}