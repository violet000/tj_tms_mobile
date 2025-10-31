import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_bmflocation/flutter_bmflocation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tj_tms_mobile/services/foreground_service_manager.dart';
import 'location_config.dart';

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
    await requestLocationPermission();
    _locationPlugin.setAgreePrivacy(true);
    BMFMapSDK.setAgreePrivacy(true);

    if (Platform.isIOS) {
      _locationPlugin.authAK('YOUR_IOS_AK');
    } else if (Platform.isAndroid) {
      BMFMapSDK.setCoordType(BMF_COORD_TYPE.BD09LL);
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

    // Android 10+ 后台定位 & Android 13+ 通知
    if (Platform.isAndroid) {
      final bg = await Permission.locationAlways.status;
      if (bg != PermissionStatus.granted) {
        await Permission.locationAlways.request();
      }
      final notify = await Permission.notification.status;
      if (notify != PermissionStatus.granted) {
        await Permission.notification.request();
      }
    }

    return true;
  }

  // 获取单次位置（flutter_bmflocation）
  Future<Map<String, dynamic>?> getSingleLocation() async {
    Completer<Map<String, dynamic>>? completer;
    try {
      final androidOptions = LocationConfig.getAndroidOptions();
      final iosOptions = LocationConfig.getIOSOptions();
      await _locationPlugin.prepareLoc(androidOptions.getMap(), iosOptions.getMap());

      completer = Completer<Map<String, dynamic>>();

      if (Platform.isIOS) {
        _locationPlugin.singleLocationCallback(callback: (BaiduLocation result) {
          if (!completer!.isCompleted) {
            completer.complete(Map<String, dynamic>.from(result.getMap()));
          }
        });
        final success = await _locationPlugin.singleLocation(<String, dynamic>{
          'isReGeocode': true,
          'isNetworkState': true
        });
        if (!success && !completer.isCompleted) {
          return null;
        }
      } else {
        _locationPlugin.seriesLocationCallback(callback: (BaiduLocation result) {
          if (!completer!.isCompleted) {
            completer.complete(Map<String, dynamic>.from(result.getMap()));
            _locationPlugin.stopLocation();
          }
        });
        final success = await _locationPlugin.startLocation();
        if (!success) return null;
      }

      return await completer.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          _locationPlugin.stopLocation();
          return <String, dynamic>{};
        },
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error getting single location: $e');
      return null;
    }
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