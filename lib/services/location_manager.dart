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
  Timer? _continuousTimer;
  bool _pollingInProgress = false;
  static const Duration _pollingInterval = Duration(seconds: 10);

  // 初始化位置服务
  Future<void> initialize() async {
    await _locationService.initialize();
  }

  // 获取单次位置更新
  // 返回一个Future，完成时包含位置数据或null（如果失败）
  Future<Map<String, dynamic>?> getSingleLocation() async {
    return await _locationService.getSingleLocation();
  }

  // 开始连续位置更新
  // 返回一个Stream，包含位置更新
  Stream<Map<String, dynamic>> startContinuousLocation() {
    if (_isContinuousLocationActive) {
      return _locationStreamController!.stream;
    }

    _locationStreamController = StreamController<Map<String, dynamic>>();
    _isContinuousLocationActive = true;

    // 使用单次定位定时轮询，避免依赖插件的连续定位参数
    _continuousTimer = Timer.periodic(_pollingInterval, (_) async {
      if (_pollingInProgress) return;
      _pollingInProgress = true;
      try {
        final location = await _locationService.getSingleLocation();
        if (location != null) {
          _locationStreamController?.add(location);
        }
      } finally {
        _pollingInProgress = false;
      }
    });

    return _locationStreamController!.stream;
  }

  // 停止连续位置更新
  void stopContinuousLocation() {
    if (_isContinuousLocationActive) {
      _continuousTimer?.cancel();
      _continuousTimer = null;
      _pollingInProgress = false;
      _locationStreamController?.close();
      _locationStreamController = null;
      _isContinuousLocationActive = false;
    }
  }

  // 检查是否正在连续位置更新
  bool get isContinuousLocationActive => _isContinuousLocationActive;

  // 释放位置管理器
  void dispose() {
    stopContinuousLocation();
  }
} 