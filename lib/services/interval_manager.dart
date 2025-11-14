import 'package:shared_preferences/shared_preferences.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';
import 'package:tj_tms_mobile/core/config/location_polling_config.dart';

/// 间隔值管理工具类
class IntervalManager {
  // 常量定义
  static const String agpsIntervalKey = 'agps_interval_seconds';
  static const String interfaceIntervalKey = 'interface_interval_seconds';
  static const String currentIntervalKey = 'current_interval_seconds';

  /// 获取AGPS间隔值（从接口获取的值）
  static Future<int?> getAGPSInterval() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final interval = prefs.getInt(agpsIntervalKey);
      return interval;
    } catch (e) {
      return null;
    }
  }

  /// 获取当前使用的间隔值（其他地方使用的值）
  static Future<int?> getCurrentInterval() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final interval = prefs.getInt(currentIntervalKey);
      return interval;
    } catch (e) {
      return null;
    }
  }

  /// 获取接口的间隔值
  static Future<int?> getInterfaceInterval() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final interval = prefs.getInt(interfaceIntervalKey);
      return interval;
    } catch (e) {
      return null;
    }
  }

  /// 获取有效的间隔值（优先使用AGPS值，否则使用当前值）
  static Future<int> getEffectiveInterval() async {
    try {
      final agpsInterval = await getInterfaceInterval();
      final currentInterval = await getCurrentInterval();

      // 优先使用AGPS间隔值
      if (agpsInterval != null && agpsInterval > 0) {
        return agpsInterval;
      }

      // 否则使用当前间隔值
      if (currentInterval != null && currentInterval > 0) {
        return currentInterval;
      }
      return 30;
    } catch (e) {
      return 30; // 默认30秒
    }
  }

  /// 设置AGPS间隔值
  static Future<void> setAGPSInterval(int interval) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(agpsIntervalKey, interval);
    } catch (e) {
    }
  }

  /// 设置当前间隔值
  static Future<void> setCurrentInterval(int interval) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(currentIntervalKey, interval);
    } catch (e) {
    }
  }

  // 设置接口的间隔值
  static Future<void> setInterfaceInterval(int interval) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(interfaceIntervalKey, interval);
    } catch (e) {
    }
  }

  /// 同时设置AGPS和当前间隔值
  static Future<void> setBothIntervals(int interval) async {
    try {
      await Future.wait([
        setAGPSInterval(interval),
        setCurrentInterval(interval),
      ]);
    } catch (e) {
    }
  }

  /// 获取默认间隔值（从LocationPollingConfig）
  static Future<int> getDefaultInterval() async {
    try {
      final defaultInterval =
          await LocationPollingConfig.getSavedPollingInterval();
      return defaultInterval as int;
    } catch (e) {
      return 30; // 默认30秒
    }
  }

  /// 更新LocationPollingConfig中的间隔值
  static Future<void> updateLocationPollingConfig(int interval) async {
    try {
      await LocationPollingConfig.setPollingInterval(interval);
    } catch (e) {
    }
  }

  /// 清除所有间隔值
  static Future<void> clearAllIntervals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(agpsIntervalKey);
      await prefs.remove(currentIntervalKey);
    } catch (e) {
    }
  }

  /// 获取所有间隔值信息
  static Future<Map<String, dynamic>> getAllIntervalInfo() async {
    try {
      final agpsInterval = await getAGPSInterval();
      final currentInterval = await getCurrentInterval();
      final effectiveInterval = await getEffectiveInterval();
      final defaultInterval = await getDefaultInterval();

      return <String, dynamic>{
        'agpsInterval': agpsInterval,
        'currentInterval': currentInterval,
        'effectiveInterval': effectiveInterval,
        'defaultInterval': defaultInterval,
      };
    } catch (e) {
      return <String, dynamic>{
        'agpsInterval': null,
        'currentInterval': null,
        'effectiveInterval': 30,
        'defaultInterval': 30,
      };
    }
  }
}
