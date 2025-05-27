import 'package:flutter/material.dart';

class FaceLoginProvider extends ChangeNotifier {
  final Map<int, String?> _faceImages = {};
  final Map<int, String> _usernames = {};
  final Map<int, bool> _isFaceLogin = {};

  String? getFaceImage(int index) => _faceImages[index];
  String? getUsername(int index) => _usernames[index];
  bool isFaceLogin(int index) => _isFaceLogin[index] ?? true;

  void setFaceImage(int index, String? imageBase64) {
    _faceImages[index] = imageBase64;
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
    _isFaceLogin.remove(index);
    notifyListeners();
  }
} 