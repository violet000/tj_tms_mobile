import 'dart:convert';
import 'package:flutter/services.dart';

class AssetLoader {
  /// 加载并解析 JSON 文件
  static Future<Map<String, dynamic>> loadJson(String assetPath) async {
    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error loading JSON file: $e');
      rethrow;
    }
  }

  /// 加载 location.json 文件
  static Future<Map<String, dynamic>> loadLocationConfig() async {
    return loadJson('assets/location.json');
  }
} 