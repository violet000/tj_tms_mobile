class LocationPollingConfig {
  // 默认轮询间隔（秒）
  static const int defaultPollingInterval = 30;
  
  // 最小轮询间隔（秒）
  static const int minPollingInterval = 30;
  
  // 最大轮询间隔（秒）
  static const int maxPollingInterval = 60;
  
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
  
  // 获取当前轮询间隔
  static int getPollingInterval() {
    return defaultPollingInterval;
  }
  
  // 设置轮询间隔
  static Future<void> setPollingInterval(int seconds) async {
    if (seconds < minPollingInterval || seconds > maxPollingInterval) {
      throw ArgumentError('轮询间隔必须在${minPollingInterval}-${maxPollingInterval}秒之间');
    }
  }
  
  // 检查是否应该上传位置数据
  static bool shouldUploadLocation() {
    return uploadInterval > 0;
  }
  
  // 获取位置上传间隔
  static int getUploadInterval() {
    return uploadInterval;
  }
} 