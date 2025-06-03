// 存储/获取token
import 'package:flutter/foundation.dart';

class VerifyTokenProvider extends ChangeNotifier {
  String? access_token;
  
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
    notifyListeners();
  }
}