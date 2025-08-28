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

class NetworkSettingsPage extends StatefulWidget {
  const NetworkSettingsPage({Key? key}) : super(key: key);

  @override
  State<NetworkSettingsPage> createState() => _NetworkSettingsPageState();
}

class _NetworkSettingsPageState extends State<NetworkSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _vpsIpController = TextEditingController();
  final TextEditingController _agpsIntervalController = TextEditingController();
  final TextEditingController _deviceIdController = TextEditingController();

  static const String vpsKey = 'network_vps_ip';
  static const String agpsIntervalKey = 'agps_interval_seconds';
  Map<String, dynamic> _deviceInfo = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadDeviceInfo();
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
    // 从接口获取AGPS时间间隔
    await _loadAGPSInterval();
  }

  Future<void> _loadAGPSInterval() async {
    try {
      debugPrint('开始加载AGPS时间间隔...');
      final service = await Service18082.create();
      final Map<String, dynamic> result =
          await service.getAGPSParam(<String, dynamic>{
        'catalog': '',
        'paramName': 'GPS_SEND_TIME',
        'statement': '',
        'description': '',
        'pageSize': 10,
        'curRow': 1
      });
      debugPrint('AGPS时间间隔接口返回结果: $result');
      if (result['retCode'] == '000000') {
        final List<dynamic> dataList =
            result['data']['list'] as List<dynamic>? ?? <dynamic>[];
        if (dataList.isNotEmpty) {
          final Map<String, dynamic> agpsData =
              dataList.first as Map<String, dynamic>;
          final String? paramValue = agpsData['paramValue'] as String?;
          if (paramValue != null) {
            final int? interval = int.tryParse(paramValue);
            if (interval != null) {
              _agpsIntervalController.text = interval.toString();
              // 保存到本地存储
              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              await prefs.setInt(agpsIntervalKey, interval);
              return;
            }
          }
        }
      }
      // 如果接口获取失败，使用本地保存的值或默认值
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? saved = prefs.getInt(agpsIntervalKey);
      final int current =
          saved ?? await LocationPollingConfig.getSavedPollingInterval();
      _agpsIntervalController.text = current.toString();
    } catch (e) {
      // 如果接口调用失败，使用本地保存的值或默认值
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? saved = prefs.getInt(agpsIntervalKey);
      final int current =
          saved ?? await LocationPollingConfig.getSavedPollingInterval();
      _agpsIntervalController.text = current.toString();
    }
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState?.validate() ?? false) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      var input = _vpsIpController.text.trim();
      if (!input.startsWith('http')) {
        input = "http://" + input;
      }
      if (!_isValidServerAddress(input)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('IP/域名格式不正确，请检查后重试')),
        );
        return;
      }
      // 去除末尾多余斜杠
      final normalized = input.replaceAll(RegExp(r"/+$/"), '');
      // 同步写入 vpsKey（主）和 vmsKey（兼容）
      await prefs.setString(vpsKey, normalized);
      // AGPS时间间隔从接口获取，不需要手动保存
      // 获取当前保存的AGPS时间间隔用于后台轮询
      final int? savedInterval = prefs.getInt(agpsIntervalKey);
      if (savedInterval != null) {
        await LocationPollingConfig.setPollingInterval(savedInterval);
        // 让后台轮询立即生效
        LocationPollingManager().setPollingInterval(savedInterval);
      }
      DioServiceManager().clearAllServices();
      // 刷新后台轮询使用的 Service 实例
      await LocationPollingManager().reloadService();
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
                        controller: _agpsIntervalController,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'AGPS时间间隔（秒）',
                          helperText: '此值由系统自动获取',
                          helperStyle: TextStyle(
                            color: Color.fromARGB(255, 191, 189, 189),
                          ),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFF5F5F5),
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _deviceIdController,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: '手持机设备ID',
                          helperText: '点击右侧按钮复制手持机设备ID',
                          helperStyle: const TextStyle(
                            color: Color.fromARGB(255, 191, 189, 189),
                          ),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          suffixIcon: Container(
                            padding: const EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: () {
                                final deviceId = _deviceIdController.text;
                                Clipboard.setData(
                                    ClipboardData(text: deviceId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: const [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text('设备ID已复制到剪贴板'),
                                      ],
                                    ),
                                    backgroundColor: Colors.green.shade600,
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.copy,
                                color: Theme.of(context).primaryColor,
                                size: 22,
                              ),
                              tooltip: '复制设备ID',
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                          ),
                        ),
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
    // _vmsIpController.dispose();
    _vpsIpController.dispose();
    _agpsIntervalController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }
}
