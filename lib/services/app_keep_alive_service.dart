import 'package:flutter/services.dart';
import 'battery_optimization_service.dart';

/// 应用保活服务
/// 用于引导用户设置各种保活权限
class AppKeepAliveService {
  static const MethodChannel _channel = MethodChannel('com.example.tj_tms_mobile/app_keep_alive');
  
  /// 检查自启动权限
  static Future<bool> isAutoStartEnabled() async {
    try {
      final bool result = await _channel.invokeMethod<bool>('isAutoStartEnabled') ?? false;
      print('自启动权限检查结果: $result');
      return result;
    } catch (e) {
      print('检查自启动权限失败: $e');
      return false;
    }
  }
  
  /// 打开自启动设置页面
  static Future<void> openAutoStartSettings() async {
    try {
      await _channel.invokeMethod<void>('openAutoStartSettings');
      print('已打开自启动设置页面');
    } catch (e) {
      print('打开自启动设置页面失败: $e');
    }
  }
  
  /// 检查后台运行权限
  static Future<bool> isBackgroundRunEnabled() async {
    try {
      final bool result = await _channel.invokeMethod<bool>('isBackgroundRunEnabled') ?? false;
      print('后台运行权限检查结果: $result');
      return result;
    } catch (e) {
      print('检查后台运行权限失败: $e');
      return false;
    }
  }
  
  /// 打开后台运行设置页面
  static Future<void> openBackgroundRunSettings() async {
    try {
      await _channel.invokeMethod<void>('openBackgroundRunSettings');
      print('已打开后台运行设置页面');
    } catch (e) {
      print('打开后台运行设置页面失败: $e');
    }
  }
  
  /// 检查通知权限
  static Future<bool> isNotificationEnabled() async {
    try {
      final bool result = await _channel.invokeMethod<bool>('isNotificationEnabled') ?? false;
      print('通知权限检查结果: $result');
      return result;
    } catch (e) {
      print('检查通知权限失败: $e');
      return false;
    }
  }
  
  /// 打开通知设置页面
  static Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod<void>('openNotificationSettings');
      print('已打开通知设置页面');
    } catch (e) {
      print('打开通知设置页面失败: $e');
    }
  }
  
  /// 检查所有保活权限
  static Future<Map<String, bool>> checkAllKeepAlivePermissions() async {
    try {
      final Map<String, bool> result = {
        'batteryOptimization': await BatteryOptimizationService.isIgnoringBatteryOptimizations(),
        'autoStart': await isAutoStartEnabled(),
        'backgroundRun': await isBackgroundRunEnabled(),
        'notification': await isNotificationEnabled(),
      };
      print('所有保活权限检查结果: $result');
      return result;
    } catch (e) {
      print('检查保活权限时发生错误: $e');
      return {
        'batteryOptimization': false,
        'autoStart': false,
        'backgroundRun': false,
        'notification': false,
      };
    }
  }
  
  /// 引导用户设置所有保活权限
  static Future<void> guideAllKeepAliveSettings() async {
    try {
      final permissions = await checkAllKeepAlivePermissions();
      
      if (!permissions['batteryOptimization']!) {
        print('需要设置电池优化权限');
        await BatteryOptimizationService.requestIgnoreBatteryOptimizations();
      }
      
      if (!permissions['autoStart']!) {
        print('需要设置自启动权限');
        await openAutoStartSettings();
      }
      
      if (!permissions['backgroundRun']!) {
        print('需要设置后台运行权限');
        await openBackgroundRunSettings();
      }
      
      if (!permissions['notification']!) {
        print('需要设置通知权限');
        await openNotificationSettings();
      }
    } catch (e) {
      print('引导设置保活权限时发生错误: $e');
    }
  }
}