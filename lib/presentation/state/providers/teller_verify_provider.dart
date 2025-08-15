import 'package:flutter/material.dart';

class TellerVerifyProvider extends ChangeNotifier {
  final Map<int, String?> _faceImages = {};
  final Map<int, String> _usernames = {};
  final Map<int, String> _passwords = {};
  final Map<int, bool> _isFaceLogin = {};

  String? getFaceImage(int index) => _faceImages[index];
  String? getUsername(int index) => _usernames[index];
  String? getPassword(int index) => _passwords[index];
  bool isFaceLogin(int index) => _isFaceLogin[index] ?? true;

  void setFaceImage(int index, String? imageBase64) {
    _faceImages[index] = imageBase64;
    notifyListeners();
  }

  void setPassword(int index, String password) {
    _passwords[index] = password;
    notifyListeners();
  }

  void setUsername(int index, String username) {
    _usernames[index] = username;
    notifyListeners();
  }

  void toggleLoginMode(int index) {
    _isFaceLogin[index] = !isFaceLogin(index);
    notifyListeners();
  }

  void clearData(int index) {
    _faceImages.remove(index);
    _usernames.remove(index);
    _passwords.remove(index);
    _isFaceLogin.remove(index);
    notifyListeners();
  }

  void clearAllData() {
    _faceImages.clear();
    _usernames.clear();
    _passwords.clear();
    _isFaceLogin.clear();
    notifyListeners();
  }

  // 验证柜员信息是否完整
  bool isTellerValid(int index) {
    final username = _usernames[index];
    final password = _passwords[index];
    final faceImage = _faceImages[index];
    
    // 用户名必须存在
    if (username == null || username.isEmpty) {
      return false;
    }
    
    // 密码或人脸图片至少有一个
    final hasPassword = password != null && password.isNotEmpty;
    final hasFaceImage = faceImage != null && faceImage.isNotEmpty;
    
    return hasPassword || hasFaceImage;
  }

  // 获取所有柜员信息
  Map<String, dynamic> getAllTellerData() {
    return <String, dynamic>{
      'faceImages': Map<int, String?>.from(_faceImages),
      'usernames': Map<int, String>.from(_usernames),
      'passwords': Map<int, String>.from(_passwords),
      'isFaceLogin': Map<int, bool>.from(_isFaceLogin),
    };
  }
} 