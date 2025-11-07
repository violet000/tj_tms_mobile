import 'dart:developer' as developer;

/// 日志级别枚举
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  fatal,
}

/// 日志级别扩展
extension LogLevelExtension on LogLevel {
  String get name {
    switch (this) {
      case LogLevel.verbose:
        return 'VERBOSE';
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.fatal:
        return 'FATAL';
    }
  }

  String get emoji {
    switch (this) {
      case LogLevel.verbose:
        return '🔍';
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.fatal:
        return '💀';
    }
  }

  int get priority {
    switch (this) {
      case LogLevel.verbose:
        return 0;
      case LogLevel.debug:
        return 1;
      case LogLevel.info:
        return 2;
      case LogLevel.warning:
        return 3;
      case LogLevel.error:
        return 4;
      case LogLevel.fatal:
        return 5;
    }
  }
}

/// 自定义支持长文本log的打印器
class LongPrettyPrinter {
  final int wrapLength; // 控制换行长度
  final bool showTimestamp; // 是否显示时间戳
  final bool showLogLevel; // 是否显示日志级别
  final bool enableColors; // 是否启用颜色
  final String? customPrefix; // 自定义前缀
  final LogLevel minLevel; // 最小日志级别

  LongPrettyPrinter({
    this.wrapLength = 1000,
    this.showTimestamp = true,
    this.showLogLevel = true,
    this.enableColors = true,
    this.customPrefix,
    this.minLevel = LogLevel.debug,
  });

  /// 格式化消息
  String _formatMessage(String message, LogLevel level) {
    final buffer = StringBuffer();
    
    // 添加时间戳
    if (showTimestamp) {
      final timestamp = DateTime.now().toString();
      buffer.write('[$timestamp] ');
    }
    
    // 添加日志级别
    if (showLogLevel) {
      final levelStr = _getLogLevelString(level);
      buffer.write('$levelStr ');
    }
    
    // 添加自定义前缀
    if (customPrefix != null && customPrefix!.isNotEmpty) {
      buffer.write('[$customPrefix] ');
    }
    
    // 添加格式化后的消息内容
    buffer.write(_wrapText(message));
    
    return buffer.toString();
  }

  /// 获取日志级别字符串
  String _getLogLevelString(LogLevel level) {
    final emoji = level.emoji;
    final name = level.name;
    
    if (enableColors) {
      switch (level) {
        case LogLevel.verbose:
          return '$emoji \x1B[90m[$name]\x1B[0m';
        case LogLevel.debug:
          return '$emoji \x1B[36m[$name]\x1B[0m';
        case LogLevel.info:
          return '$emoji \x1B[32m[$name]\x1B[0m';
        case LogLevel.warning:
          return '$emoji \x1B[33m[$name]\x1B[0m';
        case LogLevel.error:
          return '$emoji \x1B[31m[$name]\x1B[0m';
        case LogLevel.fatal:
          return '$emoji \x1B[35m[$name]\x1B[0m';
      }
    } else {
      return '$emoji [$name]';
    }
  }

  /// 文本换行处理
  String _wrapText(String text) {
    if (text.length <= wrapLength) {
      return text;
    }

    final buffer = StringBuffer();
    int currentIndex = 0;
    
    while (currentIndex < text.length) {
      final remainingLength = text.length - currentIndex;
      final chunkLength = remainingLength > wrapLength ? wrapLength : remainingLength;
      
      // 查找最佳换行点
      int breakPoint = _findBestBreakPoint(text, currentIndex, chunkLength);
      
      // 添加当前行
      buffer.write(text.substring(currentIndex, breakPoint));
      
      // 如果不是最后一行，添加换行符
      if (breakPoint < text.length) {
        buffer.write('\n');
      }
      
      currentIndex = breakPoint;
    }
    
    return buffer.toString();
  }

  /// 查找最佳换行点
  int _findBestBreakPoint(String text, int startIndex, int maxLength) {
    final endIndex = startIndex + maxLength;
    
    // 如果剩余文本长度小于等于最大长度，直接返回结束位置
    if (endIndex >= text.length) {
      return text.length;
    }
    
    // 优先在换行符处换行
    final newlineIndex = text.indexOf('\n', startIndex);
    if (newlineIndex != -1 && newlineIndex <= endIndex) {
      return newlineIndex + 1; // 包含换行符
    }
    
    // 其次在空格处换行
    final spaceIndex = text.lastIndexOf(' ', endIndex);
    if (spaceIndex > startIndex) {
      return spaceIndex + 1; // 包含空格
    }
    
    // 最后在标点符号处换行
    final punctuationIndex = _findLastPunctuation(text, startIndex, endIndex);
    if (punctuationIndex > startIndex) {
      return punctuationIndex + 1;
    }
    
    // 如果都没有找到合适的换行点，强制换行
    return endIndex;
  }

  /// 查找最后一个标点符号
  int _findLastPunctuation(String text, int startIndex, int endIndex) {
    const punctuationMarks = [',', '.', ';', ':', '!', '?', '，', '。', '；', '：', '！', '？'];
    
    for (int i = endIndex - 1; i >= startIndex; i--) {
      if (punctuationMarks.contains(text[i])) {
        return i;
      }
    }
    
    return -1;
  }

  /// 打印日志
  void log(LogLevel level, dynamic message, [dynamic error, StackTrace? stackTrace]) {
    // 检查日志级别
    if (level.priority < minLevel.priority) {
      return;
    }

    final formattedMessage = _formatMessage(message.toString(), level);
    
    // 根据日志级别选择不同的输出方式
    switch (level) {
      case LogLevel.verbose:
      case LogLevel.debug:
        developer.log(formattedMessage);
        break;
      case LogLevel.info:
        print(formattedMessage);
        break;
      case LogLevel.warning:
        print(formattedMessage);
        break;
      case LogLevel.error:
      case LogLevel.fatal:
        print(formattedMessage);
        if (error != null) {
          print('Error: $error');
        }
        if (stackTrace != null) {
          print('StackTrace: $stackTrace');
        }
        break;
    }
  }
}

/// 日志管理器
class AppLogger {
  static LongPrettyPrinter? _printer;
  
  /// 获取日志打印机实例
  static LongPrettyPrinter get printer {
    _printer ??= LongPrettyPrinter(
      wrapLength: 1000,
      showTimestamp: true,
      showLogLevel: true,
      enableColors: true,
      customPrefix: 'TMS_MOBILE',
      minLevel: LogLevel.debug,
    );
    return _printer!;
  }
  
  /// 初始化日志
  static void init({
    int wrapLength = 1000,
    bool showTimestamp = true,
    bool showLogLevel = true,
    bool enableColors = true,
    String? customPrefix,
    LogLevel minLevel = LogLevel.debug,
  }) {
    _printer = LongPrettyPrinter(
      wrapLength: wrapLength,
      showTimestamp: showTimestamp,
      showLogLevel: showLogLevel,
      enableColors: enableColors,
      customPrefix: customPrefix,
      minLevel: minLevel,
    );
  }
  
  /// 详细日志
  static void verbose(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    printer.log(LogLevel.verbose, message, error, stackTrace);
  }
  
  /// 调试日志
  static void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    printer.log(LogLevel.debug, message, error, stackTrace);
  }
  
  /// 信息日志
  static void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    printer.log(LogLevel.info, message, error, stackTrace);
  }
  
  /// 警告日志
  static void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    printer.log(LogLevel.warning, message, error, stackTrace);
  }
  
  /// 错误日志
  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    printer.log(LogLevel.error, message, error, stackTrace);
  }
  
  /// 致命错误日志
  static void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    printer.log(LogLevel.fatal, message, error, stackTrace);
  }
  
  /// 网络请求日志
  static void network(String method, String url, {Map<String, dynamic>? headers, dynamic body, int? statusCode}) {
    final message = '''
🌐 Network Request:
Method: $method
URL: $url
${headers != null ? 'Headers: $headers' : ''}
${body != null ? 'Body: $body' : ''}
${statusCode != null ? 'Status: $statusCode' : ''}
''';
    printer.log(LogLevel.info, message);
  }
  
  /// API响应日志
  static void apiResponse(String endpoint, dynamic response, {int? statusCode, String? error}) {
    final message = '''
📡 API Response:
Endpoint: $endpoint
${statusCode != null ? 'Status: $statusCode' : ''}
${error != null ? 'Error: $error' : ''}
Response: $response
''';
    if (error != null) {
      printer.log(LogLevel.error, message);
    } else {
      printer.log(LogLevel.info, message);
    }
  }
  
  /// 用户操作日志
  static void userAction(String action, {Map<String, dynamic>? parameters}) {
    final message = '''
👤 User Action:
Action: $action
${parameters != null ? 'Parameters: $parameters' : ''}
''';
    printer.log(LogLevel.info, message);
  }
  
  /// 性能日志
  static void performance(String operation, Duration duration) {
    final message = '''
⚡ Performance:
Operation: $operation
Duration: ${duration.inMilliseconds}ms
''';
    printer.log(LogLevel.debug, message);
  }

  /// 扫码日志
  static void scan(String type, String code, {String? location}) {
    final message = '''
📱 Scan:
Type: $type
Code: $code
${location != null ? 'Location: $location' : ''}
''';
    printer.log(LogLevel.info, message);
  }

  /// 位置日志
  static void location(double latitude, double longitude, {String? address}) {
    final message = '''
📍 Location:
Latitude: $latitude
Longitude: $longitude
${address != null ? 'Address: $address' : ''}
''';
    printer.log(LogLevel.debug, message);
  }

  /// 设备信息日志
  static void deviceInfo(String deviceId, String deviceModel, {String? osVersion}) {
    final message = '''
📱 Device Info:
Device ID: $deviceId
Model: $deviceModel
${osVersion != null ? 'OS Version: $osVersion' : ''}
''';
    printer.log(LogLevel.info, message);
  }
}