import 'dart:async';
import 'package:tj_tms_mobile/services/location_manager.dart';
import 'package:tj_tms_mobile/core/config/location_polling_config.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';
import 'package:tj_tms_mobile/data/datasources/api/9087/service_9087.dart';
import 'package:tj_tms_mobile/core/utils/util.dart' as app_utils;
import 'package:tj_tms_mobile/services/foreground_service_manager.dart';
 

class LocationPollingManager {
  static final LocationPollingManager _instance =
      LocationPollingManager._internal();
  factory LocationPollingManager() => _instance;
  LocationPollingManager._internal();

  final LocationManager _locationManager = LocationManager();
  Timer? _locationTimer; // 不再使用周期性单次定位；保留字段以兼容停止逻辑
  StreamSubscription<Map<String, dynamic>>? _locationSubscription;
  Map<String, dynamic>? _currentLocation;
  bool _isPolling = false;
  int _pollingInterval = LocationPollingConfig.defaultPollingInterval;
  Service9087? _service9087;
  Map<String, dynamic> _deviceInfo = <String, dynamic>{};
  DateTime? _lastUploadAt;

  Function(Map<String, dynamic>)? _onLocationUpdate;
  Function(String)? _onError;

  // 获取当前状态
  bool get isPolling => _isPolling;
  Map<String, dynamic>? get currentLocation => _currentLocation;
  int get pollingInterval => _pollingInterval;

  // 初始化
  Future<void> initialize() async {
    try {
      await _locationManager.initialize();
      // 从配置加载已保存的轮询间隔
      try {
        final int saved = await LocationPollingConfig.getSavedPollingInterval();
        _pollingInterval = saved;
        // 若历史配置过大，自动降到30秒，贴合插件 scanSpan=30s
        if (_pollingInterval > 60) {
          _pollingInterval = 30;
          await LocationPollingConfig.setPollingInterval(_pollingInterval);
        }
      } catch (_) {}
      _loadDeviceInfo();
      _service9087 = await Service9087.create();
    } catch (e) {
      AppLogger.error('位置轮询管理器初始化失败: $e');
      rethrow;
    }
  }

  // 重新加载网络服务（用于切换IP后生效）
  Future<void> reloadService() async {
    try {
      _service9087 = await Service9087.create();
    } catch (e) {
      AppLogger.error('重新加载 Service9087 失败: $e');
    }
  }

  Future<void> _loadDeviceInfo() async {
    final info = await app_utils.loadDeviceInfo();
    _deviceInfo = info;
  }

  // 设置回调函数
  void setCallbacks({
    Function(Map<String, dynamic>)? onLocationUpdate,
    Function(String)? onError,
  }) {
    _onLocationUpdate = onLocationUpdate;
    _onError = onError;
  }

  // 启动位置轮询
  void startPolling() {
    if (_isPolling) {
      return;
    }

    if (!LocationPollingConfig.enableLocationPolling) {
      return;
    }

    _isPolling = true;
    // 启动前台服务以保持后台运行
    _startForegroundService();
    // 切换为插件级连续定位：订阅持续回调，按间隔做节流上送
    _locationSubscription = _locationManager
        .startContinuousLocation()
        .listen((location) {
      _currentLocation = location;
      final now = DateTime.now();
      if (_lastUploadAt == null ||
          now.difference(_lastUploadAt!).inSeconds >= _pollingInterval) {
        _lastUploadAt = now;
        _processLocationData(location);
        _onLocationUpdate?.call(location);
      }
    }, onError: (Object e) {
      AppLogger.error('连续定位回调异常: $e');
      _onError?.call('连续定位回调异常: $e');
    });
  }

  // 启动前台服务
  Future<void> _startForegroundService() async {
    try {
      await ForegroundServiceManager.startForegroundService();
    } catch (e) {
      AppLogger.error('启动前台服务异常: $e');
    }
  }

  // 停止位置轮询
  void stopPolling() {
    if (!_isPolling) {
      return;
    }
    _locationTimer?.cancel();
    _locationTimer = null;
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _locationManager.stopContinuousLocation();
    _isPolling = false;
    // 停止前台服务
    _stopForegroundService();
  }

  // 停止前台服务
  Future<void> _stopForegroundService() async {
    try {
      await ForegroundServiceManager.stopForegroundService();
    } catch (e) {
      AppLogger.error('停止前台服务异常: $e');
    }
  }

  // 设置轮询间隔
  void setPollingInterval(int seconds) async {
    try {
      await LocationPollingConfig.setPollingInterval(seconds);
      _pollingInterval = seconds;
      // 连续定位场景仅更新节流门限时间点
      _lastUploadAt = null;
    } catch (e) {
      AppLogger.error('设置轮询间隔失败: $e');
      _onError?.call('设置轮询间隔失败: $e');
    }
  }

  // 处理位置数据
  void _processLocationData(Map<String, dynamic> location) {
    // 检查位置是否有效
    if (location['latitude'] != null && location['longitude'] != null) {
      _uploadLocationData(location);
    } else {
      _uploadLocationData(location);
    }
  }

  // 上传位置数据到服务器
  Future<void> _uploadLocationData(Map<String, dynamic> location) async {
    const int maxRetries = 5; // 增加重试次数
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final dynamic latitude = location['latitude']; // 经度
        final dynamic longitude = location['longitude']; // 纬度
        final date = DateTime.now();
        final formattedDateTime = _formatDateTime(date);
        if (latitude != null && longitude != null) {
          await _service9087?.sendGpsInfo(<String, dynamic>{
            'handheldNo': _deviceInfo['deviceId'],
            'x': longitude,
            'y': latitude,
            'timestamp': date.millisecondsSinceEpoch,
            'dateTime': formattedDateTime,
            'status':
                (latitude != null && longitude != null) ? 'valid' : 'invalid'
          });
          return; // 成功上传，退出重试循环
        }
      } catch (e) {
        retryCount++;
        AppLogger.error('上送失败(retry=$retryCount): $e');
      }
    }
  }

  // 获取状态信息
  Map<String, dynamic> getStatus() {
    return <String, dynamic>{
      'isPolling': _isPolling,
      'interval': _pollingInterval,
      'lastLocation': _currentLocation,
      'hasLocation': _currentLocation != null,
      'enablePolling': LocationPollingConfig.enableLocationPolling,
      'enableLogging': LocationPollingConfig.enableLocationLogging,
      'shouldUpload': LocationPollingConfig.shouldUploadLocation(),
    };
  }

  // 释放资源
  void dispose() {
    stopPolling();
    _onLocationUpdate = null;
    _onError = null;
  }

  // yyyy-MM-dd HH:mm:ss 格式化
  String _formatDateTime(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}:${two(date.second)}';
  }
}
