import 'package:flutter/material.dart';
import 'package:tj_tms_mobile/services/battery_optimization_service.dart';
import 'package:tj_tms_mobile/services/app_keep_alive_service.dart';

/// 电池优化自动检测和弹框服务
/// 类似于定位权限的处理方式
class BatteryOptimizationAutoDialog {
  static bool _hasShownDialog = false;
  static bool _isChecking = false;
  
  /// 自动检测电池优化状态并弹框
  static Future<void> checkAndShowDialog(BuildContext context) async {
    if (_hasShownDialog || _isChecking) return;
    
    _isChecking = true;
    
    try {
      // 检查电池优化状态
      final bool isIgnoring = await BatteryOptimizationService.isIgnoringBatteryOptimizations();
      
      if (!isIgnoring) {
        _hasShownDialog = true;
        await _showBatteryOptimizationDialog(context);
      }
    } catch (e) {
      print('检查电池优化状态失败: $e');
    } finally {
      _isChecking = false;
    }
  }
  
  /// 显示电池优化对话框
  static Future<void> _showBatteryOptimizationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // 不允许点击外部关闭
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 96, 177, 252),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.battery_alert,
                  color: Color.fromARGB(255, 233, 244, 255),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '电池优化',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '为了确保应用正常运行，需要添加到电池优化白名单',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '防止应用被系统杀死，确保后台服务正常运行',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _hasShownDialog = false; // 允许下次再次显示
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: const Text(
                '稍后',
                style: TextStyle(fontSize: 14),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _requestBatteryOptimization(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 100, 181, 255),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '立即设置',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }
  
  /// 请求电池优化设置
  static Future<void> _requestBatteryOptimization(BuildContext context) async {
    try {
      // 显示加载提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('正在打开电池优化设置...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
      
      // 请求忽略电池优化
      await BatteryOptimizationService.requestIgnoreBatteryOptimizations();
      
      // 延迟检查结果
      Future.delayed(const Duration(seconds: 3), () async {
        final bool isIgnoring = await BatteryOptimizationService.isIgnoringBatteryOptimizations();
        if (isIgnoring) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('电池优化设置成功！'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Text('请手动完成电池优化设置'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('设置失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// 重置对话框状态（用于测试或重新显示）
  static void resetDialogState() {
    _hasShownDialog = false;
    _isChecking = false;
  }
  
  /// 检查所有保活权限并显示相应的对话框
  static Future<void> checkAllKeepAlivePermissions(BuildContext context) async {
    try {
      final permissions = await AppKeepAliveService.checkAllKeepAlivePermissions();
      
      // 优先处理电池优化
      if (!permissions['batteryOptimization']!) {
        await checkAndShowDialog(context);
        return;
      }
      
      // 如果电池优化已设置，检查其他权限
      if (!permissions['notification']!) {
        await _showNotificationDialog(context);
      }
    } catch (e) {
      print('检查保活权限失败: $e');
    }
  }
  
  /// 显示通知权限对话框
  static Future<void> _showNotificationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notifications_off,
                  color: Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '通知权限',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '需要通知权限来显示前台服务状态',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '确保应用正常运行和状态显示',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: const Text(
                '稍后',
                style: TextStyle(fontSize: 14),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await AppKeepAliveService.openNotificationSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '去设置',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }
}