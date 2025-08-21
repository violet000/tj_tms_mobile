import 'package:flutter/services.dart';

class ForegroundServiceManager {
  static const MethodChannel _channel = MethodChannel('location_service');
  
  /// 启动前台服务
  static Future<bool> startForegroundService() async {
    try {
      final bool result = await _channel.invokeMethod<bool>('startForegroundService') ?? false;
      return result;
    } on PlatformException catch (e) {
      return false;
    }
  }
  
  /// 停止前台服务
  static Future<bool> stopForegroundService() async {
    try {
      final bool result = await _channel.invokeMethod<bool>('stopForegroundService') ?? false;
      return result;
    } on PlatformException catch (e) {
      return false;
    }
  }
} 