import 'dart:async';
import 'package:flutter/material.dart';
import 'location_manager.dart';

// 位置帮助类
// 获取单次位置信息
// 开始持续定位
// 释放资源

class LocationResult {
  final Map<String, dynamic>? location;
  final bool isLoading;
  final String? error;

  LocationResult({
    this.location,
    this.isLoading = false,
    this.error,
  });
}

class LocationHelper {
  static final LocationHelper _instance = LocationHelper._internal();
  factory LocationHelper() => _instance;
  LocationHelper._internal();

  final LocationManager _locationManager = LocationManager();
  StreamSubscription<Map<String, dynamic>>? _locationSubscription;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      await _locationManager.initialize();
      _isInitialized = true;
    }
  }

  /// 返回包含位置信息和状态的 LocationResult 对象
  Future<LocationResult> getLocation() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final location = await _locationManager.getSingleLocation();
      return LocationResult(location: location);
    } catch (e) {
      return LocationResult(error: e.toString());
    }
  }

  /// 返回包含位置流和停止方法的 ContinuousLocationResult 对象
  ContinuousLocationResult startTracking() {
    _locationSubscription?.cancel();

    final locationStream = _locationManager.startContinuousLocation();

    return ContinuousLocationResult(
      stream: locationStream,
      stopTracking: () {
        _locationSubscription?.cancel();
        _locationSubscription = null;
        _locationManager.stopContinuousLocation();
      },
    );
  }

  /// 释放资源
  void dispose() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _locationManager.dispose();
    _isInitialized = false;
  }
}

class ContinuousLocationResult {
  final Stream<Map<String, dynamic>> stream;
  final VoidCallback stopTracking;

  ContinuousLocationResult({
    required this.stream,
    required this.stopTracking,
  });
} 