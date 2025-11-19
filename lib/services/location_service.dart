import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_bmflocation/flutter_bmflocation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tj_tms_mobile/services/foreground_service_manager.dart';
import 'location_config.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final LocationFlutterPlugin _locationPlugin = LocationFlutterPlugin();
  bool _isInitialized = false;
  StreamSubscription<Position>? _geoStreamSub;
  Timer? _geoFallbackTimer;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // 判断是否是web平台, 如果是web平台，不执行插件权限部分
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    if (!LocationConfig.offlineGpsOnly) {
      _locationPlugin.setAgreePrivacy(true);
      BMFMapSDK.setAgreePrivacy(true);
    }

    if (!LocationConfig.offlineGpsOnly) {
      if (Platform.isIOS) {
        _locationPlugin.authAK('YOUR_IOS_AK');
      } else if (Platform.isAndroid) {
        BMFMapSDK.setCoordType(BMF_COORD_TYPE.COMMON);
      }
    }

    _isInitialized = true;
  }

  // 获取单次位置（flutter_bmflocation）
  Future<Map<String, dynamic>?> getSingleLocation() async {
    Completer<Map<String, dynamic>>? completer;
    try {
      // 纯离线GPS：直接走 geolocator
      if (LocationConfig.offlineGpsOnly) {
        return await _getSingleLocationWithGeolocator();
      }
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
          // 'isReGeocode': true,
          // 'isNetworkState': true
          'isReGeocode': false, // 关闭逆地理，避免网络依赖
          'isNetworkState': false // 不请求网络状态
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

      final result = await completer.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () async {
          _locationPlugin.stopLocation();
          // 超时则尝试纯GPS回退
          return await _getSingleLocationWithGeolocator();
        },
      );
      // 若为空或无经纬度，再次回退
      if (result == null || result['latitude'] == null || result['longitude'] == null) {
        return await _getSingleLocationWithGeolocator();
      }
      return result;
    } catch (e) {
      // ignore: avoid_print
      print('Error getting single location: $e');
      // 发生异常则回退
      return await _getSingleLocationWithGeolocator();
    }
  }

  // 开始连续位置更新（flutter_bmflocation）
  void startLocationUpdates({
    required Function(Map<String, dynamic>) onLocationUpdate,
  }) {
    // 启动前台服务以提高保活
    try {
      ForegroundServiceManager.startForegroundService();
    } catch (_) {}

    if (LocationConfig.offlineGpsOnly) {
      // 先尝试获取一次当前位置以触发冷启动搜星，再进入持续流
      _emitCurrentPositionOnce(onLocationUpdate);
      _startGeolocatorStream(onLocationUpdate);
      return;
    }

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

    _locationPlugin.prepareLoc(androidMap, iosOptions.getMap());
    _locationPlugin.startLocation();

    // 启动一个回退定时器：若若干秒内没有任何回调，则启用 geolocator 连续流
    _geoFallbackTimer?.cancel();
    _geoFallbackTimer = Timer(const Duration(seconds: 8), () async {
      if (_geoStreamSub == null) {
        await _startGeolocatorStream(onLocationUpdate);
      }
    });
  }

  // 停止连续位置更新
  void stopLocationUpdates() {
    if (!LocationConfig.offlineGpsOnly) {
      _locationPlugin.stopLocation();
    }
    _geoFallbackTimer?.cancel();
    _geoFallbackTimer = null;
    _geoStreamSub?.cancel();
    _geoStreamSub = null;
  }

  // —— 纯GPS回退（geolocator） ——
  Future<Map<String, dynamic>> _getSingleLocationWithGeolocator() async {
    try {
      final hasPermission = await _ensureGeolocatorPermissions();
      if (!hasPermission) return <String, dynamic>{};
      Position position;
      if (Platform.isAndroid) {
        // 在 Android 上强制使用系统 LocationManager，避免 GMS 依赖
        position = await Geolocator.getPositionStream(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0,
            intervalDuration: const Duration(seconds: 60), 
            forceLocationManager: true,
          ),
        ).first.timeout(const Duration(seconds: 25));
      } else {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: const Duration(seconds: 25),
        );
      }
      final gcj02 = _wgs84ToGcj02(position.latitude, position.longitude); // 转换为GCJ02坐标
      return <String, dynamic>{
        'latitude': gcj02.latitude,
        'longitude': gcj02.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'altitude': position.altitude,
        'coordinateType': 'gcj02',
        'from': 'geolocator',
      };
    } catch (e) {
      return <String, dynamic>{};
    }
  }

  Future<void> _startGeolocatorStream(Function(Map<String, dynamic>) onLocationUpdate) async {
    try {
      final hasPermission = await _ensureGeolocatorPermissions();
      if (!hasPermission) return;
      final LocationSettings settings = Platform.isAndroid
          ? AndroidSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 0,
              intervalDuration: const Duration(seconds: 60),
              forceLocationManager: true,
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 0,
            );
      _geoStreamSub = Geolocator.getPositionStream(locationSettings: settings).listen((position) {
        final gcj02 = _wgs84ToGcj02(position.latitude, position.longitude);
        onLocationUpdate(<String, dynamic>{
          'latitude': gcj02.latitude,
          'longitude': gcj02.longitude,
          'accuracy': position.accuracy,
          'speed': position.speed,
          'altitude': position.altitude,
          'coordinateType': 'gcj02',
          'from': 'geolocator',
        });
      });
    } catch (e) {
      // ignore: avoid_print
      print('Geolocator stream fallback error: $e');
    }
  }

  Future<bool> _ensureGeolocatorPermissions() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
      return false;
    }
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      // 尝试提醒打开位置服务（不会阻塞）
      try { await Geolocator.openLocationSettings(); } catch (_) {}
    }
    return enabled;
  }

  BMFCoordinate _wgs84ToGcj02(double lat, double lon) {
    if (_outOfChina(lat, lon)) return BMFCoordinate(lat, lon);
    final dLat = _transformLat(lon - 105.0, lat - 35.0);
    final dLon = _transformLon(lon - 105.0, lat - 35.0);
    const double pi = math.pi;
    const double a = 6378245.0;
    const double ee = 0.00669342162296594323;
    final radLat = lat / 180.0 * pi;
    var magic = math.sin(radLat);
    magic = 1 - ee * magic * magic;
    final sqrtMagic = math.sqrt(magic);
    final mgLat = lat + (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi);
    final mgLon = lon + (dLon * 180.0) / (a / sqrtMagic * math.cos(radLat) * pi);
    return BMFCoordinate(mgLat, mgLon);
  }

  bool _outOfChina(double lat, double lon) {
    return lon < 72.004 || lon > 137.8347 || lat < 0.8293 || lat > 55.8271;
  }

  double _transformLat(double x, double y) {
    double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * math.sqrt(x.abs());
    ret += (20.0 * math.sin(6.0 * x * math.pi) + 20.0 * math.sin(2.0 * x * math.pi)) * 2.0 / 3.0;
    ret += (20.0 * math.sin(y * math.pi) + 40.0 * math.sin(y / 3.0 * math.pi)) * 2.0 / 3.0;
    ret += (160.0 * math.sin(y / 12.0 * math.pi) + 320 * math.sin(y * math.pi / 30.0)) * 2.0 / 3.0;
    return ret;
  }

  double _transformLon(double x, double y) {
    double ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * math.sqrt(x.abs());
    ret += (20.0 * math.sin(6.0 * x * math.pi) + 20.0 * math.sin(2.0 * x * math.pi)) * 2.0 / 3.0;
    ret += (20.0 * math.sin(x * math.pi) + 40.0 * math.sin(x / 3.0 * math.pi)) * 2.0 / 3.0;
    ret += (150.0 * math.sin(x / 12.0 * math.pi) + 300.0 * math.sin(x / 30.0 * math.pi)) * 2.0 / 3.0;
    return ret;
  }

  // 先获取一次当前位置并回调（用于冷启动尽快拿到首点）
  Future<void> _emitCurrentPositionOnce(Function(Map<String, dynamic>) onLocationUpdate) async {
    final data = await _getSingleLocationWithGeolocator();
    if (data.isNotEmpty && data['latitude'] != null && data['longitude'] != null) {
      onLocationUpdate(data);
    }
  }
}