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

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadDeviceInfo();
    // _checkBatteryOptimizationStatus();
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
