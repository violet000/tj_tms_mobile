import 'package:flutter/services.dart';

// 标签读取插件

class UHFPlugin {
  static const MethodChannel _channel = MethodChannel('com.example.uhf_plugin/uhf');

  static Future<bool> init() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('init');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to initialize UHF reader: ${e.message}');
      return false;
    }
  }

  static Future<void> free() async {
    try {
      await _channel.invokeMethod<void>('free');
    } on PlatformException catch (e) {
      print('Failed to free UHF reader: ${e.message}');
    }
  }

  static Future<List<String>> startScan() async {
    try {
      final List<dynamic>? tags = await _channel.invokeMethod<List<dynamic>>('startScan');
      return tags?.map((dynamic tag) => tag.toString()).toList() ?? [];
    } on PlatformException catch (e) {
      print('Failed to scan tags: ${e.message}');
      return [];
    }
  }

  static Future<bool> writeTag(String epc, String data) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('writeTag', {'epc': epc, 'data': data});
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to write tag: ${e.message}');
      return false;
    }
  }

  static Future<bool> lockTag(String epc) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('lockTag', {'epc': epc});
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to lock tag: ${e.message}');
      return false;
    }
  }

  static Future<bool> killTag(String epc) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('killTag', {'epc': epc});
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to kill tag: ${e.message}');
      return false;
    }
  }
} 