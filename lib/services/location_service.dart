import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_bmflocation/flutter_bmflocation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'location_config.dart';
import 'dart:async';

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

    // 请求设备权限
    await requestLocationPermission();

    // 设置隐私政策同意
    _locationPlugin.setAgreePrivacy(true);
    BMFMapSDK.setAgreePrivacy(true);

    if (Platform.isIOS) {
      // 设置iOS AK
      _locationPlugin.authAK('YOUR_IOS_AK');
      BMFMapSDK.setApiKeyAndCoordType('YOUR_IOS_AK', BMF_COORD_TYPE.BD09LL);
    } else if (Platform.isAndroid) {
      // 设置Android AK
      BMFMapSDK.setCoordType(BMF_COORD_TYPE.BD09LL);
    }

    _locationPlugin.getApiKeyCallback(callback: (String result) {
      print('鉴权结果：' + result);
    });

    _isInitialized = true;
  }

  Future<bool> requestLocationPermission() async {
    if (kIsWeb) return true;  // 判断是否是web平台, 如果是web平台，不执行权限检查
    
    var status = await Permission.location.status;
    if (status == PermissionStatus.granted) {
      return true;
    } else {
      status = await Permission.location.request();
      return status == PermissionStatus.granted;
    }
  }

  // 获取单次位置
  Future<Map<String, dynamic>?> getSingleLocation() async {
    try {
      // 设置定位参数
      final androidOptions = LocationConfig.getAndroidOptions();
      final iosOptions = LocationConfig.getIOSOptions();
      await _locationPlugin.prepareLoc(androidOptions.getMap(), iosOptions.getMap());

      // 创建一个Completer来等待位置结果
      final completer = Completer<Map<String, dynamic>?>();

      if (Platform.isIOS) {
        // 设置单次定位回调
        _locationPlugin.singleLocationCallback(callback: (BaiduLocation result) {
          completer.complete(Map<String, dynamic>.from(result.getMap()));
        });

        // 开始单次定位
        final success = await _locationPlugin.singleLocation(<String, dynamic>{
          'isReGeocode': true,
          'isNetworkState': true
        });

        if (!success) {
          completer.complete(null);
        }
      } else {
        // Android需要先设置连续定位回调，然后启动定位
        _locationPlugin.seriesLocationCallback(callback: (BaiduLocation result) {
          completer.complete(Map<String, dynamic>.from(result.getMap()));
          _locationPlugin.stopLocation(); // 获取到位置后停止定位
        });

        final success = await _locationPlugin.startLocation();
        if (!success) {
          completer.complete(null);
        }
      }

      // 等待位置结果，设置超时时间为10秒
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _locationPlugin.stopLocation();
          return null;
        },
      );
    } catch (e) {
      print('Error getting single location: $e');
      return null;
    }
  }

  // 开始连续位置更新
  void startLocationUpdates({
    required Function(Map<String, dynamic>) onLocationUpdate,
  }) {
    // 设置定位参数
    final androidOptions = LocationConfig.getAndroidOptions();
    final iosOptions = LocationConfig.getIOSOptions();
    _locationPlugin.prepareLoc(androidOptions.getMap(), iosOptions.getMap());

    _locationPlugin.startLocation();
    _locationPlugin.seriesLocationCallback(callback: (result) {
      onLocationUpdate(Map<String, dynamic>.from(result.getMap()));
    });
  }

  // 停止连续位置更新
  void stopLocationUpdates() {
    _locationPlugin.stopLocation();
  }
} 