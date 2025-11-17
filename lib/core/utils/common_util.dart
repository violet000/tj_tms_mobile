import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';

// 公共方法：获取设备信息
Future<Map<String, dynamic>> getDeviceInfo() async {
  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    String deviceId = await FlutterUdid.consistentUdid ?? '';
    return <String, dynamic>{
      'deviceId': deviceId,
      'model': androidInfo.model,
      'manufacturer': androidInfo.manufacturer,
      'version': androidInfo.version.release,
      'sdkInt': androidInfo.version.sdkInt,
    };
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    String deviceId = await FlutterUdid.consistentUdid ?? '';
    return <String, dynamic>{
      'deviceId': deviceId,
      'model': iosInfo.model,
      'systemVersion': iosInfo.systemVersion,
      'name': iosInfo.name,
    };
  }
  return <String, dynamic>{};
}

// 公共方法：带错误捕获的设备信息加载（便于直接调用）
Future<Map<String, dynamic>> loadDeviceInfo() async {
  try {
    return await getDeviceInfo();
  } catch (e) {
    return <String, dynamic>{};
  }
}

// 公共方法：单独获取 UDID（便于需要裸 UDID 的调用方）
Future<String> getUdid() async {
  try {
    final udid = await FlutterUdid.consistentUdid;
    return udid;
  } catch (e) {
    // 获取失败时回退到平台标识符
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown';
    }
    return 'unknown';
  }
}

/// 解析编号和标签ID
/// 
/// 输入格式：编号-标签ID
/// 返回：{'plateNumber': '编号', 'tagId': '标签ID'}
/// 
/// [carNo] 编号字符串，格式为"编号-标签ID"
/// 返回包含编号和标签ID的Map，如果解析失败则返回空字符串
Map<String, String> parseCarNoAndTagId(String carNo) {
  if (carNo.isEmpty) {
    return {'plateNumber': '', 'tagId': ''};
  }
  
  final parts = carNo.split('-');
  if (parts.length != 2) {
    // 如果没有'-'分隔符，整个字符串作为编号
    return {'plateNumber': carNo, 'tagId': ''};
  }
  
  return {
    'plateNumber': parts[0].trim(),
    'tagId': parts[1].trim(),
  };
}

/// 获取编号（从完整字符串中提取）
/// 
/// [carNo] 编号字符串，格式为"编号-标签ID"
/// 返回编号部分
String getPlateNumber(String carNo) {
  return parseCarNoAndTagId(carNo)['plateNumber'] ?? '';
}

/// 获取编号（从完整字符串中提取）
/// 
/// [carNo] 编号字符串，格式为"编号-标签ID"
/// 返回编号部分
String getTagId(String carNo) {
  return parseCarNoAndTagId(carNo)['tagId'] ?? '';
}