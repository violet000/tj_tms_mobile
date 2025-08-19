import 'dart:async';
import 'package:tj_tms_mobile/services/location_manager.dart';
import 'package:tj_tms_mobile/core/config/location_polling_config.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';
import 'package:tj_tms_mobile/data/datasources/api/18082/service_18082.dart';
import 'package:tj_tms_mobile/core/utils/util.dart' as app_utils;

class LocationPollingManager {
  static final LocationPollingManager _instance = LocationPollingManager._internal();
  factory LocationPollingManager() => _instance;
  LocationPollingManager._internal();

  final LocationManager _locationManager = LocationManager();
  Timer? _locationTimer;
  Map<String, dynamic>? _currentLocation;
  bool _isPolling = false;
  int _pollingInterval = LocationPollingConfig.defaultPollingInterval;
  Service18082? _service18082;
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
      _loadDeviceInfo();
      _service18082 = await Service18082.create();
    } catch (e) {
      AppLogger.error('位置轮询管理器初始化失败: $e');
      rethrow;
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
    
    // 获取一次位置
    _getCurrentLocation();
    
    // 设置定时器
    _locationTimer = Timer.periodic(Duration(seconds: _pollingInterval), (timer) {
      _getCurrentLocation();
    });
  }

  // 停止位置轮询
  void stopPolling() {
    if (!_isPolling) {
      return;
    }
    _locationTimer?.cancel();
    _locationTimer = null;
    _isPolling = false;
  }

  // 设置轮询间隔
  void setPollingInterval(int seconds) async {
    try {
      await LocationPollingConfig.setPollingInterval(seconds);
      _pollingInterval = seconds;
      if (_isPolling) {
        stopPolling();
        startPolling();
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
      }
    } catch (e) {
      _onError?.call('获取位置失败: $e');
    }
  }

  // 处理位置数据
  void _processLocationData(Map<String, dynamic> location) {
    // 检查位置是否有效
    if (location['latitude'] != null && location['longitude'] != null) {
      _uploadLocationData(location);
    }
  }

  // 上传位置数据到服务器
  Future<void> _uploadLocationData(Map<String, dynamic> location) async {
    try {
      await _service18082?.sendGpsInfo(<String, dynamic>{
        'handheldNo': _deviceInfo['deviceId'],
        'x': location['latitude'],
        'y': location['longitude']
      });
      AppLogger.info('位置数据上传完成');
    } catch (e) {
      _onError?.call('位置数据上传失败: $e');
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