import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:flutter_bmflocation/flutter_bmflocation.dart';

class LocationConfig {
  /// 设置Android端定位参数
  static BaiduLocationAndroidOption getAndroidOptions() {
    return BaiduLocationAndroidOption(
      coorType: 'bd09ll',
      locationMode: BMFLocationMode.hightAccuracy,
      isNeedAddress: false,
      isNeedAltitude: false, // 不需要海拔，减少功耗
      isNeedLocationPoiList: false,
      isNeedNewVersionRgc: false,
      isNeedLocationDescribe: false,
      openGps: true,
      coordType: BMFLocationCoordType.bd09ll
    );
  }

  /// 设置iOS端定位参数
  static BaiduLocationIOSOption getIOSOptions() {
    return BaiduLocationIOSOption(
      coordType: BMFLocationCoordType.bd09ll,
      BMKLocationCoordinateType: 'BMKLocationCoordinateTypeBMK09LL',
      desiredAccuracy: BMFDesiredAccuracy.best
    );
  }

  /// 设置地图参数
  static BMFMapOptions getMapOptions({
    double latitude = 39.917215,
    double longitude = 116.380341,
    int zoomLevel = 12,
  }) {
    return BMFMapOptions(
      center: BMFCoordinate(latitude, longitude),
      zoomLevel: zoomLevel,
      mapPadding: BMFEdgeInsets(top: 0, left: 0, right: 0, bottom: 0)
    );
  }
} 