import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

/// 统一的权限管理服务
/// 所有权限申请都通过此服务进行管理
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// 请求所有应用需要的权限
  /// 返回权限申请结果映射
  /// 如果权限被永久拒绝，会自动打开设置页面
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    if (kIsWeb) {
      // Web 平台返回所有权限为已授予
      return {
        Permission.location: PermissionStatus.granted,
        Permission.locationAlways: PermissionStatus.granted,
        Permission.notification: PermissionStatus.granted,
      };
    }

    final Map<Permission, PermissionStatus> results = {};
    final List<Permission> permanentlyDeniedPermissions = [];

    // 前台定位权限
    PermissionStatus status = await Permission.location.status;
    if (status == PermissionStatus.permanentlyDenied) {
      permanentlyDeniedPermissions.add(Permission.location);
      results[Permission.location] = status;
    } else if (status != PermissionStatus.granted) {
      status = await Permission.location.request();
      results[Permission.location] = status;
      // 如果请求后仍然是永久拒绝，记录
      if (status == PermissionStatus.permanentlyDenied) {
        permanentlyDeniedPermissions.add(Permission.location);
      }
    } else {
      results[Permission.location] = status;
    }

    // 后台定位权限
    status = await Permission.locationAlways.status;
    if (status == PermissionStatus.permanentlyDenied) {
      permanentlyDeniedPermissions.add(Permission.locationAlways);
      results[Permission.locationAlways] = status;
    } else if (status != PermissionStatus.granted) {
      status = await Permission.locationAlways.request();
      results[Permission.locationAlways] = status;
      // 如果请求后仍然是永久拒绝，记录
      if (status == PermissionStatus.permanentlyDenied) {
        permanentlyDeniedPermissions.add(Permission.locationAlways);
      }
    } else {
      results[Permission.locationAlways] = status;
    }

    // 通知权限
    status = await Permission.notification.status;
    if (status == PermissionStatus.permanentlyDenied) {
      permanentlyDeniedPermissions.add(Permission.notification);
      results[Permission.notification] = status;
    } else if (status != PermissionStatus.granted) {
      status = await Permission.notification.request();
      results[Permission.notification] = status;
      // 如果请求后仍然是永久拒绝，记录
      if (status == PermissionStatus.permanentlyDenied) {
        permanentlyDeniedPermissions.add(Permission.notification);
      }
    } else {
      results[Permission.notification] = status;
    }

    // 如果有权限被永久拒绝，自动打开设置页面
    if (permanentlyDeniedPermissions.isNotEmpty) {
      // 延迟一下，让用户看到权限申请对话框的结果
      Future.delayed(const Duration(milliseconds: 500), () {
        openAppSettings();
      });
    }

    return results;
  }

  /// 请求定位相关权限（前台+后台）
  Future<bool> requestLocationPermissions() async {
    if (kIsWeb) return true;

    // 前台定位
    PermissionStatus status = await Permission.location.status;
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

    return true;
  }

  /// 请求通知权限
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return true;

    PermissionStatus status = await Permission.notification.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.notification.request();
      if (status != PermissionStatus.granted) return false;
    }

    return true;
  }

  /// 检查定位权限状态
  Future<Map<Permission, PermissionStatus>> getLocationPermissionStatus() async {
    if (kIsWeb) {
      return {
        Permission.location: PermissionStatus.granted,
        Permission.locationAlways: PermissionStatus.granted,
      };
    }

    return {
      Permission.location: await Permission.location.status,
      Permission.locationAlways: await Permission.locationAlways.status,
    };
  }

  /// 检查通知权限状态
  Future<PermissionStatus> getNotificationPermissionStatus() async {
    if (kIsWeb) return PermissionStatus.granted;
    return await Permission.notification.status;
  }

  /// 检查所有权限状态
  Future<Map<Permission, PermissionStatus>> getAllPermissionStatus() async {
    if (kIsWeb) {
      return {
        Permission.location: PermissionStatus.granted,
        Permission.locationAlways: PermissionStatus.granted,
        Permission.notification: PermissionStatus.granted,
      };
    }

    return {
      Permission.location: await Permission.location.status,
      Permission.locationAlways: await Permission.locationAlways.status,
      Permission.notification: await Permission.notification.status,
    };
  }

  /// 打开应用设置页面
  Future<bool> openAppSettingsPage() async {
    if (kIsWeb) return false;
    return await openAppSettings();
  }
}
