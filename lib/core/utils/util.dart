import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';

// 公共方法：获取设备信息
Future<Map<String, dynamic>> getDeviceInfo() async {
  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return <String, dynamic>{
      'deviceId': androidInfo.id,
      'model': androidInfo.model,
      'manufacturer': androidInfo.manufacturer,
      'version': androidInfo.version.release,
      'sdkInt': androidInfo.version.sdkInt,
    };
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return <String, dynamic>{
      'deviceId': iosInfo.identifierForVendor,
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
    AppLogger.error('获取设备信息失败: $e');
    return <String, dynamic>{};
  }
}