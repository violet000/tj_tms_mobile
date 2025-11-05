import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_bmflocation/flutter_bmflocation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tj_tms_mobile/services/foreground_service_manager.dart';
import 'location_config.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final LocationFlutterPlugin _locationPlugin = LocationFlutterPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // 判断是否是web平台, 如果是web平台，不执行插件权限部分
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    // 权限与隐私
    final bool granted = await requestLocationPermission();
    if (!granted) {
      return;
    }
    _locationPlugin.setAgreePrivacy(true);
    BMFMapSDK.setAgreePrivacy(true);

    if (Platform.isIOS) {
      // 添加iOS的AK
    } else if (Platform.isAndroid) {
      BMFMapSDK.setCoordType(BMF_COORD_TYPE.COMMON);
    }

    _isInitialized = true;
  }

  Future<bool> requestLocationPermission() async {
    if (kIsWeb) return true;  // web 不检查

    // 前台定位
    var status = await Permission.location.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.location.request();
      if (status != PermissionStatus.granted) return false;
    }

    // 后台定位
    status = await Permission.locationAlways.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.locationAlways.request();
      if (status != PermissionStatus.granted) return false;
    }

    // 通知权限
    status = await Permission.notification.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.notification.request();
      if (status != PermissionStatus.granted) return false;
    }

    return true;
  }

  // 开始连续位置更新（flutter_bmflocation）
  void startLocationUpdates({
    required Function(Map<String, dynamic>) onLocationUpdate,
  }) {
    // 先注册回调
    _locationPlugin.seriesLocationCallback(callback: (BaiduLocation result) {
      // ignore: avoid_print
      print('[LocationService] 收到连续定位回调');
      onLocationUpdate(Map<String, dynamic>.from(result.getMap()));
    });

    // 准备参数
    final androidOptions = LocationConfig.getAndroidOptions();
    final iosOptions = LocationConfig.getIOSOptions();
    final Map<String, dynamic> androidMap = androidOptions.getMap();
    androidMap['scanSpan'] = 3000; // 连续模式
    androidMap['isOnceLocation'] = false; 
    androidMap['openGps'] = true;
    androidMap['locationNotify'] = true; 
    androidMap['isLocationCacheEnable'] = false; 
    androidMap.remove('locationPurpose');

    // 启动前台服务以提高保活
    try {
      ForegroundServiceManager.startForegroundService();
    } catch (_) {}

    _locationPlugin.prepareLoc(androidMap, iosOptions.getMap());
    _locationPlugin.startLocation();
  }

  // 停止连续位置更新
  void stopLocationUpdates() {
    _locationPlugin.stopLocation();
  }
}