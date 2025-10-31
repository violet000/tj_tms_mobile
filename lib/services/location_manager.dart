import 'dart:async';
import 'package:flutter/material.dart';
import 'location_service.dart';

// 提供高级位置操作的类
class LocationManager {
  static final LocationManager _instance = LocationManager._internal();
  factory LocationManager() => _instance;
  LocationManager._internal();

  final LocationService _locationService = LocationService();
  bool _isContinuousLocationActive = false;
  StreamController<Map<String, dynamic>>? _locationStreamController;
  DateTime? _lastCallbackAt;
  Timer? _watchdogTimer;
  int _watchdogIntervalSeconds = 6; // 检查与重启阈值（秒）

  // 初始化位置服务
  Future<void> initialize() async {
    await _locationService.initialize();
  }

  // 获取单次位置更新
  // 返回一个Futur
  Future<Map<String, dynamic>?> getSingleLocation() async {
    return await _locationService.getSingleLocation();
  }

  // 开始连续位置更新
  // 返回一个Stream，包含位置更新
  Stream<Map<String, dynamic>> startContinuousLocation() {
    if (_isContinuousLocationActive) {
      return _locationStreamController!.stream;
    }

    _locationStreamController = StreamController<Map<String, dynamic>>.broadcast();
    _isContinuousLocationActive = true;

    _locationService.startLocationUpdates(
      onLocationUpdate: (location) {
        _lastCallbackAt = DateTime.now();
        // 不做节流，交由上层控制上送间隔
        _locationStreamController?.add(location);
      },
    );

    _startWatchdog();

    return _locationStreamController!.stream;
  }

  // 停止连续位置更新
  void stopContinuousLocation() {
    if (_isContinuousLocationActive) {
      _locationService.stopLocationUpdates();
      _locationStreamController?.close();
      _locationStreamController = null;
      _isContinuousLocationActive = false;
      _stopWatchdog();
    }
  }

  void _startWatchdog() {
    _stopWatchdog();
    _watchdogTimer = Timer.periodic(Duration(seconds: _watchdogIntervalSeconds), (_) {
      if (!_isContinuousLocationActive) return;
      final last = _lastCallbackAt;
      if (last == null) return;
      final diff = DateTime.now().difference(last).inSeconds;
      if (diff >= _watchdogIntervalSeconds) {
        _locationService.stopLocationUpdates();
        _locationService.startLocationUpdates(
          onLocationUpdate: (location) {
            _lastCallbackAt = DateTime.now();
            final updated = Map<String, dynamic>.from(location);
            updated['_restart'] = true;
            _locationStreamController?.add(updated);
          },
        );
      }
    });
  }

  void _stopWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  // 检查是否正在连续位置更新
  bool get isContinuousLocationActive => _isContinuousLocationActive;

  // 设置看门狗检查/重启间隔
  void setWatchdogIntervalSeconds(int seconds) {
    final next = seconds <= 0 ? 6 : seconds;
    _watchdogIntervalSeconds = next;
    if (_isContinuousLocationActive) {
      _startWatchdog();
    }
  }

  // 释放位置管理器
  void dispose() {
    stopContinuousLocation();
  }
} 