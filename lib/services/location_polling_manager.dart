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
  Timer? _locationTimer;
  Map<String, dynamic>? _currentLocation;
  bool _isPolling = false;
  int _pollingInterval = LocationPollingConfig.defaultPollingInterval;
  Service9087? _service9087;
  Map<String, dynamic> _deviceInfo = <String, dynamic>{};

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
      AppLogger.info('LocationPollingManager 已重新加载 Service9087');
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
      AppLogger.info('位置轮询已在运行中，跳过启动');
      return;
    }

    if (!LocationPollingConfig.enableLocationPolling) {
      AppLogger.warning('位置轮询功能已禁用，无法启动');
      return;
    }

    _isPolling = true;
    AppLogger.info('开始位置轮询，间隔: ${_pollingInterval}秒');

    // 启动前台服务以保持后台运行
    _startForegroundService();

    // 获取一次位置
    _getCurrentLocation();

    // 设置定时器
    _locationTimer =
        Timer.periodic(Duration(seconds: _pollingInterval), (timer) {
      AppLogger.info('定时器触发，获取位置信息');
      _getCurrentLocation();
    });
  }

  // 启动前台服务
  Future<void> _startForegroundService() async {
    try {
      final success = await ForegroundServiceManager.startForegroundService();
      if (success) {
        AppLogger.info('前台服务启动成功');
      } else {
        AppLogger.warning('前台服务启动失败');
      }
    } catch (e) {
      AppLogger.error('启动前台服务异常: $e');
    }
  }

  // 停止位置轮询
  void stopPolling() {
    if (!_isPolling) {
      AppLogger.info('位置轮询未在运行，无需停止');
      return;
    }
    _locationTimer?.cancel();
    _locationTimer = null;
    _isPolling = false;
    AppLogger.info('位置轮询已停止');

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
      if (_isPolling) {
        // 正在轮询时仅重置定时器，避免前台服务的重复 stop/start 造成竞态
        _locationTimer?.cancel();
        _locationTimer = Timer.periodic(Duration(seconds: _pollingInterval), (timer) {
          AppLogger.info('定时器触发，获取位置信息');
          _getCurrentLocation();
        });
      }
    } catch (e) {
      AppLogger.error('设置轮询间隔失败: $e');
      _onError?.call('设置轮询间隔失败: $e');
    }
  }

  // 获取当前位置
  Future<void> _getCurrentLocation() async {
    try {
      final location = await _locationManager.getSingleLocation();
      if (location != null) {
        _currentLocation = location;
        _processLocationData(location);
        _onLocationUpdate?.call(location);
      } else {
        _uploadHeartbeat();
      }
    } catch (e) {
      _onError?.call('获取位置失败: $e');
      // 发生异常时也上传心跳包
      _uploadHeartbeat();
    }
  }

  // 上传心跳包
  Future<void> _uploadHeartbeat() async {
    try {
      AppLogger.info('上传心跳包');
    } catch (e) {
      AppLogger.error('心跳包上传失败: $e');
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
        final dynamic latitude = location['latitude'];
        final dynamic longitude = location['longitude'];
        if (latitude != null && longitude != null) {
          await _service9087?.sendGpsInfo(<String, dynamic>{
            'handheldNo': _deviceInfo['deviceId'],
            'x': latitude,
            'y': longitude,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'status':
                (latitude != null && longitude != null) ? 'valid' : 'invalid'
          });
          return; // 成功上传，退出重试循环
        }
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          _onError?.call('位置数据上传失败: $e');
        } else {
          final delaySeconds = retryCount * 3;
          await Future<void>.delayed(Duration(seconds: delaySeconds));
        }
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
}
