import 'package:shared_preferences/shared_preferences.dart';

class LocationPollingConfig {
  // 默认轮询间隔（秒）
  static const int defaultPollingInterval = 120;

  // 最小轮询间隔（秒）
  static const int minPollingInterval = 3;

  // 最大轮询间隔（秒）
  static const int maxPollingInterval = 3600;

  // 是否启用位置轮询
  static const bool enableLocationPolling = true;

  // 是否在应用启动时自动开始轮询
  static const bool autoStartPolling = true;

  // 位置精度要求（米）
  static const double locationAccuracy = 10.0;

  // 位置超时时间（秒）
  static const int locationTimeout = 10;

  // 是否记录位置日志
  static const bool enableLocationLogging = true;

  // 位置数据上传间隔（秒），0表示不上传
  static const int uploadInterval = 0;

  static const String _prefKeyPollingInterval = 'location_polling_interval_secs';

  // 获取已保存的轮询间隔（异步），若未设置则返回默认值
  static Future<int> getSavedPollingInterval() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? saved = prefs.getInt(_prefKeyPollingInterval);
    final int value = saved ?? defaultPollingInterval;
    return _clampInterval(value);
  }

  // 设置并持久化轮询间隔
  static Future<void> setPollingInterval(int seconds) async {
    final int value = _clampInterval(seconds);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeyPollingInterval, value);
  }

  // 检查是否应该上传位置数据
  static bool shouldUploadLocation() {
    return uploadInterval > 0;
  }

  // 获取位置上传间隔
  static int getUploadInterval() {
    return uploadInterval;
  }

  static int _clampInterval(int seconds) {
    if (seconds < minPollingInterval) return minPollingInterval;
    if (seconds > maxPollingInterval) return maxPollingInterval;
    return seconds;
  }
}