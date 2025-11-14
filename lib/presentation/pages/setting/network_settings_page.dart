import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tj_tms_mobile/data/datasources/interceptor/dio_service.dart';
import 'package:tj_tms_mobile/data/datasources/api/18082/service_18082.dart';
import 'package:tj_tms_mobile/services/location_polling_manager.dart';
import 'package:tj_tms_mobile/core/config/location_polling_config.dart';
import 'package:tj_tms_mobile/core/utils/util.dart' as app_utils;
import 'package:tj_tms_mobile/core/config/env.dart';
import 'package:tj_tms_mobile/services/battery_optimization_service.dart';
import 'package:tj_tms_mobile/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NetworkSettingsPage extends StatefulWidget {
  const NetworkSettingsPage({Key? key}) : super(key: key);

  @override
  State<NetworkSettingsPage> createState() => _NetworkSettingsPageState();
}

class _NetworkSettingsPageState extends State<NetworkSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _vpsIpController = TextEditingController();
  final TextEditingController _vmsIpController = TextEditingController();
  // final TextEditingController _agpsIntervalController = TextEditingController();
  final TextEditingController _deviceIdController = TextEditingController();

  static const String vpsKey = 'network_vps_ip';
  static const String vmsKey = 'network_vms_ip';
  // static const String agpsIntervalKey = 'agps_interval_seconds';
  Map<String, dynamic> _deviceInfo = <String, dynamic>{};

  // 电池优化状态
  bool _isIgnoringBatteryOptimizations = false;
  bool _isCheckingBatteryOptimization = false;

  // 权限管理
  final PermissionService _permissionService = PermissionService();
  Map<Permission, PermissionStatus> _permissionStatuses = {};
  bool _isLoadingPermissions = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadDeviceInfo();
    _loadPermissionStatus();
    _checkBatteryOptimizationStatus();
  }

  Future<void> _loadDeviceInfo() async {
    final info = await app_utils.loadDeviceInfo();
    if (!mounted) return;
    setState(() {
      _deviceInfo = info;
    });
    // 设置设备ID到控制器
    _deviceIdController.text = (_deviceInfo['deviceId'] as String?) ?? '未知';
  }

  bool _isValidServerAddress(String raw) {
    if (raw.trim().isEmpty) return false;
    final String input = raw.trim();
    final String toValidate =
        input.startsWith('http') ? input : 'http://' + input;
    final Uri? uri = Uri.tryParse(toValidate);
    if (uri == null) return false;
    final bool schemeOk = uri.scheme == 'http' || uri.scheme == 'https';
    final bool hostOk = uri.host.isNotEmpty;
    return uri.isAbsolute && schemeOk && hostOk;
  }

  Future<void> _loadConfig() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _vpsIpController.text =
        prefs.getString(vpsKey) ?? '${Env.config.apiBaseUrl}:8082';
    _vmsIpController.text =
        prefs.getString(vmsKey) ?? '${Env.config.apiBaseUrl}:8082';
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState?.validate() ?? false) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      var vpsInput = _vpsIpController.text.trim();
      var vmsInput = _vmsIpController.text.trim();
      if (!vpsInput.startsWith('http')) {
        vpsInput = "http://" + vpsInput;
      }
      if (!vmsInput.startsWith('http')) {
        vmsInput = "http://" + vmsInput;
      }
      if (!_isValidServerAddress(vpsInput)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('网络IP/域名格式不正确，请检查后重试')),
        );
        return;
      }
      if (!_isValidServerAddress(vmsInput)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPSIP/域名格式不正确，请检查后重试')),
        );
        return;
      }
      // 去除末尾多余斜杠
      final normalized = vpsInput.replaceAll(RegExp(r"/+$/"), '');
      final normalizedVms = vmsInput.replaceAll(RegExp(r"/+$/"), '');
      // 同步写入 vpsKey
      await prefs.setString(vpsKey, normalized);
      await prefs.setString(vmsKey, normalizedVms);
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功')),
      );
    }
  }

  void _backToLogin() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  /// 加载权限状态
  Future<void> _loadPermissionStatus() async {
    if (kIsWeb) return;

    setState(() {
      _isLoadingPermissions = true;
    });

    try {
      final statuses = await _permissionService.getAllPermissionStatus();
      // 同时加载电池优化状态
      await _checkBatteryOptimizationStatus();

      if (mounted) {
        setState(() {
          _permissionStatuses = statuses;
          _isLoadingPermissions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPermissions = false;
        });
      }
    }
  }

  /// 申请所有权限
  Future<void> _requestAllPermissions() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Web平台无需申请权限')),
      );
      return;
    }

    setState(() {
      _isLoadingPermissions = true;
    });

    try {
      final results = await _permissionService.requestAllPermissions();

      // 同时刷新电池优化状态
      await _checkBatteryOptimizationStatus();

      if (mounted) {
        setState(() {
          _permissionStatuses = results;
          _isLoadingPermissions = false;
        });

        // 检查是否有未授予的权限
        final deniedPermissions = results.entries
            .where((e) => e.value != PermissionStatus.granted)
            .toList();

        if (deniedPermissions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('所有权限已授予'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // 检查是否有永久拒绝的权限
          final permanentlyDenied = deniedPermissions
              .where((e) => e.value == PermissionStatus.permanentlyDenied)
              .toList();

          if (permanentlyDenied.isNotEmpty) {
            // 如果有永久拒绝的权限，自动打开设置页面
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('部分权限需要手动设置，正在打开设置页面...'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
            // 延迟打开设置，让用户看到提示
            Future.delayed(const Duration(milliseconds: 500), () {
              _permissionService.openAppSettingsPage();
            });
          } else {
            // 其他情况，显示提示并允许用户手动打开设置
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('部分权限未授予，请前往设置中手动开启'),
                backgroundColor: Colors.orange,
                action: SnackBarAction(
                  label: '打开设置',
                  textColor: Colors.white,
                  onPressed: () {
                    _permissionService.openAppSettingsPage();
                  },
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPermissions = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('权限申请失败: $e')),
        );
      }
    }
  }

  /// 获取权限状态文本
  String _getPermissionStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '已授予';
      case PermissionStatus.denied:
        return '已拒绝';
      case PermissionStatus.restricted:
        return '受限';
      case PermissionStatus.limited:
        return '受限';
      case PermissionStatus.permanentlyDenied:
        return '永久拒绝';
      default:
        return '未知';
    }
  }

  /// 获取权限状态颜色
  Color _getPermissionStatusColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
      case PermissionStatus.restricted:
      case PermissionStatus.limited:
        return Colors.orange;
      case PermissionStatus.permanentlyDenied:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// 获取权限名称
  String _getPermissionName(Permission permission) {
    if (permission == Permission.location) {
      return '前台定位权限';
    } else if (permission == Permission.locationAlways) {
      return '后台定位权限';
    } else if (permission == Permission.notification) {
      return '通知权限';
    }
    return permission.toString();
  }

  /// 检查电池优化状态
  Future<void> _checkBatteryOptimizationStatus() async {
    if (kIsWeb) return;

    setState(() {
      _isCheckingBatteryOptimization = true;
    });

    try {
      final isIgnoring =
          await BatteryOptimizationService.isIgnoringBatteryOptimizations();
      if (mounted) {
        setState(() {
          _isIgnoringBatteryOptimizations = isIgnoring;
          _isCheckingBatteryOptimization = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingBatteryOptimization = false;
        });
      }
    }
  }

  /// 请求忽略电池优化
  Future<void> _requestBatteryOptimization() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Web平台无需设置电池优化')),
      );
      return;
    }

    try {
      await BatteryOptimizationService.requestIgnoreBatteryOptimizations();

      // 延迟检查结果，给用户时间完成设置
      Future.delayed(const Duration(seconds: 2), () async {
        await _checkBatteryOptimizationStatus();

        if (mounted) {
          if (_isIgnoringBatteryOptimizations) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('电池优化设置成功！'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('请手动完成电池优化设置'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请求电池优化设置失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '网络设置',
      showBackButton: true,
      onBackPressed: _backToLogin,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _vpsIpController,
                        decoration: const InputDecoration(
                          labelText: '网络IP配置',
                          helperText: '应用程序访问的网络地址',
                          helperStyle: TextStyle(
                            color: Color.fromARGB(255, 191, 189, 189),
                          ),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入网络IP配置';
                          }
                          if (!_isValidServerAddress(value)) {
                            return '网络IP配置格式不正确';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _vmsIpController,
                        decoration: const InputDecoration(
                          labelText: 'GPSIP配置',
                          helperText: '应用程序访问的网络地址（GPS）',
                          helperStyle: TextStyle(
                            color: Color.fromARGB(255, 191, 189, 189),
                          ),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入GPS IP配置';
                          }
                          if (!_isValidServerAddress(value)) {
                            return 'GPS IP配置格式不正确';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      // 权限管理部分
                      if (!kIsWeb) ...[
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          '权限管理',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 权限状态列表
                        ..._permissionStatuses.entries.where((entry) => entry.key != Permission.location && entry.key != Permission.locationAlways).map((entry) {
                          final permission = entry.key;
                          final status = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(_getPermissionName(permission)),
                              subtitle: Text(_getPermissionStatusText(status)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPermissionStatusColor(status)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getPermissionStatusColor(status),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _getPermissionStatusText(status),
                                  style: TextStyle(
                                    color: _getPermissionStatusColor(status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                        // 电池优化状态卡片
                        Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: const Text('电池优化'),
                            subtitle: Text(
                              _isIgnoringBatteryOptimizations
                                  ? '已忽略电池优化'
                                  : '未忽略电池优化',
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: (_isIgnoringBatteryOptimizations
                                        ? Colors.green
                                        : Colors.orange)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isIgnoringBatteryOptimizations
                                      ? Colors.green
                                      : Colors.orange,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _isIgnoringBatteryOptimizations ? '已设置' : '未设置',
                                style: TextStyle(
                                  color: _isIgnoringBatteryOptimizations
                                      ? Colors.green
                                      : Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // const SizedBox(height: 16),
                        // // 申请权限按钮
                        // SizedBox(
                        //   width: double.infinity,
                        //   child: ElevatedButton.icon(
                        //     onPressed: _isLoadingPermissions
                        //         ? null
                        //         : _requestAllPermissions,
                        //     icon: _isLoadingPermissions
                        //         ? const SizedBox(
                        //             width: 16,
                        //             height: 16,
                        //             child: CircularProgressIndicator(
                        //               strokeWidth: 2,
                        //             ),
                        //           )
                        //         : const Icon(Icons.security),
                        //     label: Text(
                        //       _isLoadingPermissions ? '申请中...' : '申请所有权限',
                        //     ),
                        //     style: ElevatedButton.styleFrom(
                        //       padding: const EdgeInsets.symmetric(vertical: 16),
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 8),
                        // 刷新权限状态按钮
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoadingPermissions
                                ? null
                                : _loadPermissionStatus,
                            icon: const Icon(Icons.refresh),
                            label: const Text('刷新权限状态'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 电池优化设置按钮
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isCheckingBatteryOptimization
                                ? null
                                : _requestBatteryOptimization,
                            icon: _isCheckingBatteryOptimization
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.battery_charging_full),
                            label: Text(
                              _isCheckingBatteryOptimization
                                  ? '检查中...'
                                  : '设置电池优化',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        // const SizedBox(height: 8),
                        // // 刷新电池优化状态按钮
                        // SizedBox(
                        //   width: double.infinity,
                        //   child: OutlinedButton.icon(
                        //     onPressed: _isCheckingBatteryOptimization
                        //         ? null
                        //         : _checkBatteryOptimizationStatus,
                        //     icon: const Icon(Icons.refresh),
                        //     label: const Text('刷新电池优化状态'),
                        //     style: OutlinedButton.styleFrom(
                        //       padding: const EdgeInsets.symmetric(vertical: 16),
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 8),
                        // 打开设置按钮
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _permissionService.openAppSettingsPage();
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('打开应用设置'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveConfig,
                      child: const Text('保存'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _backToLogin,
                      child: const Text('返回登录'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _vmsIpController.dispose();
    _vpsIpController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }
}
