// 存储/获取token
import 'package:flutter/foundation.dart';

class VerifyTokenProvider extends ChangeNotifier {
  String? access_token;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _allUsersData = []; // 存储所有用户数据
  
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
    _allUsersData.clear();
    notifyListeners();
  }

  // 设置用户数据
  void setUserData(Map<String, dynamic> data) {
    _userData = data;
    notifyListeners();
  }

  // 获取用户数据
  Map<String, dynamic>? getUserData() => _userData;

  // 添加用户数据到列表
  void addUserData(Map<String, dynamic> data) {
    _allUsersData.add(data);
    notifyListeners();
  }

  // 获取所有用户数据
  List<Map<String, dynamic>> getAllUsersData() => _allUsersData;

  // 根据用户名获取用户数据
  Map<String, dynamic>? getUserDataByUsername(String username) {
    try {
      return _allUsersData.firstWhere((user) => user['username'] == username);
    } catch (e) {
      return null;
    }
  }
}