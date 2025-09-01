import 'package:flutter/services.dart';

/// 活体检测服务
class LivenessDetectionService {
  static const MethodChannel _channel = MethodChannel('com.example.tj_tms_mobile/liveness_detection');
  static const EventChannel _events = EventChannel('com.example.tj_tms_mobile/liveness_detection_events');
  static Stream<dynamic>? _eventStream;
  
  /// 初始化活体检测
  /// [license] SDK算法授权码
  /// [packageLicense] SDK包名授权码
  static Future<bool> initialize({
    required String license,
    required String packageLicense,
  }) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('initialize', {
        'license': license,
        'packageLicense': packageLicense,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('初始化活体检测失败: ${e.message}');
      return false;
    }
  }

  /// 配置活体检测参数（一次或多次调用均可）
  static Future<bool> configure(Map<String, dynamic> config) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('configure', {
        'config': config,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('配置活体检测失败: ${e.message}');
      return false;
    }
  }
  
  /// 开始活体检测
  static Future<bool> startLivenessDetection() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('startLivenessDetection');
      return result ?? false;
    } on PlatformException catch (e) {
      print('启动活体检测失败: ${e.message}');
      return false;
    }
  }
  
  /// 检查活体检测是否可用
  static Future<bool> isAvailable() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } on PlatformException catch (e) {
      print('检查活体检测可用性失败: ${e.message}');
      return false;
    }
  }

  /// 订阅原生事件（开始、成功、失败、取消、进度等）
  static Stream<dynamic> events() {
    _eventStream ??= _events.receiveBroadcastStream();
    return _eventStream!;
  }
} 