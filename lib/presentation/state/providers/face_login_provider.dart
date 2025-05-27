import 'package:flutter/material.dart';

class FaceLoginProvider extends ChangeNotifier {
  final Map<int, String?> _faceImages = {};
  final Map<int, String> _usernames = {};

  String? getFaceImage(int index) => _faceImages[index];
  String? getUsername(int index) => _usernames[index];

  void setFaceImage(int index, String? imageBase64) {
    _faceImages[index] = imageBase64;
    notifyListeners();
  }

  void setUsername(int index, String username) {
    _usernames[index] = username;
    notifyListeners();
  }

  void clearData(int index) {
    _faceImages.remove(index);
    _usernames.remove(index);
    notifyListeners();
  }
} 