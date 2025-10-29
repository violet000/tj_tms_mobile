import 'package:flutter/services.dart';

class ForegroundServiceManager {
  static const MethodChannel _channel = MethodChannel('location_service');
  static bool _started = false;
  
  /// 启动前台服务
  static Future<bool> startForegroundService() async {
    try {
      if (_started) return true;
      final bool result = await _channel.invokeMethod<bool>('startForegroundService') ?? false;
      if (result) _started = true;
      return result;
    } catch (_) {
      return false;
    }
  }

  /// 停止前台服务
  static Future<bool> stopForegroundService() async {
    try {
      final bool result = await _channel.invokeMethod<bool>('stopForegroundService') ?? false;
      if (result) _started = false;
      return result;
    } catch (_) {
      return false;
    }
  }
} 