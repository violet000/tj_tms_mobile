import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tj_tms_mobile/services/foreground_service_manager.dart';
import 'package:tj_tms_mobile/services/location_manager.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';

class AppExitHelper {
  static const MethodChannel _appControl =
      MethodChannel('com.zijin.tj_tms_mobile/app_control');

  static Future<void> exitApp() async {
    try {
      // 停止持续定位 + 前台服务
      LocationManager().stopContinuousLocation();
    } catch (e) {
    }

    try {
      await ForegroundServiceManager.stopForegroundService();
    } catch (e) {
    }

    // 重置原生 Baidu Location，切断旧通道
    try {
      const MethodChannel('location_service')
          .invokeMethod<void>('resetBaiduLocation')
          .catchError((Object _) {});
    } catch (_) {}

    // 等待50~100ms，给原生清理时间
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // 请求原生退出（finishAndRemoveTask + 杀进程双保险）
    try {
      await _appControl.invokeMethod<void>('exitApp');
      return;
    } catch (e) {
    }

    // 兜底：SystemNavigator.pop（注意：某些 ROM 不会彻底杀进程）
    try {
      // ignore: deprecated_member_use
      await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
    } catch (e) {
    }
  }
}


