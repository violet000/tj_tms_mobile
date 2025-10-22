import 'package:flutter/services.dart';

/// 电池优化服务
/// 用于检查和管理应用的电池优化状态
class BatteryOptimizationService {
  static const MethodChannel _channel = MethodChannel('com.example.tj_tms_mobile/battery_optimization');
  
  /// 检查是否已忽略电池优化
  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final bool result = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;
      print('电池优化状态检查结果: $result');
      return result;
    } catch (e) {
      print('检查电池优化状态失败: $e');
      return false;
    }
  }
  
  /// 请求忽略电池优化
  /// 会打开系统设置页面让用户手动允许
  static Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _channel.invokeMethod<void>('requestIgnoreBatteryOptimizations');
      print('已请求忽略电池优化');
    } catch (e) {
      print('请求忽略电池优化失败: $e');
    }
  }
  
  /// 打开应用设置页面
  /// 用户可以在设置页面手动管理电池优化
  static Future<void> openBatteryOptimizationSettings() async {
    try {
      await _channel.invokeMethod<void>('openBatteryOptimizationSettings');
      print('已打开应用设置页面');
    } catch (e) {
      print('打开应用设置页面失败: $e');
    }
  }
  
  /// 检查并引导用户设置电池优化
  /// 如果未忽略电池优化，会显示引导对话框
  static Future<bool> checkAndGuideBatteryOptimization() async {
    try {
      final bool isIgnoring = await isIgnoringBatteryOptimizations();
      if (!isIgnoring) {
        print('应用未忽略电池优化，需要引导用户设置');
        return false;
      } else {
        print('应用已忽略电池优化');
        return true;
      }
    } catch (e) {
      print('检查电池优化状态时发生错误: $e');
      return false;
    }
  }
}