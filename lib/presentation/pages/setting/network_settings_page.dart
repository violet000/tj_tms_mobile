import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tj_tms_mobile/data/datasources/interceptor/dio_service.dart';
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
    // 加载AGPS时间间隔
    final int? saved = prefs.getInt(agpsIntervalKey);
    final int current =
        saved ?? await LocationPollingConfig.getSavedPollingInterval();
    _agpsIntervalController.text = current.toString();
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
      // 规范化：去除末尾多余斜杠
      final normalized = input.replaceAll(RegExp(r"/+$/"), '');
      // 同步写入 vpsKey（主）和 vmsKey（兼容）
      await prefs.setString(vpsKey, normalized);
      // 保存AGPS时间间隔
      final String intervalText = _agpsIntervalController.text.trim();
      final int? interval = int.tryParse(intervalText);
      final int min = LocationPollingConfig.minPollingInterval;
      final int max = LocationPollingConfig.maxPollingInterval;
      if (interval == null || interval < min || interval > max) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('时间间隔需在$min-$max 秒之间')),
        );
        return;
      }
      await LocationPollingConfig.setPollingInterval(interval);
      await prefs.setInt(agpsIntervalKey, interval);
      // 让后台轮询立即生效
      LocationPollingManager().setPollingInterval(interval);
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
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'AGPS时间间隔（秒）',
                          helperText:
                              '范围 ${LocationPollingConfig.minPollingInterval}-${LocationPollingConfig.maxPollingInterval} 秒',
                          border: OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入AGPS时间间隔（秒）';
                          }
                          final v = int.tryParse(value);
                          if (v == null) {
                            return '必须是数字';
                          }
                          if (v < LocationPollingConfig.minPollingInterval ||
                              v > LocationPollingConfig.maxPollingInterval) {
                            return '需在${LocationPollingConfig.minPollingInterval}-${LocationPollingConfig.maxPollingInterval}之间';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.device_hub,
                                size: 20,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '设备ID',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromARGB(221, 93, 92, 92),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 18),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border.all(
                                  color: const Color.fromARGB(255, 249, 249, 249)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (_deviceInfo['deviceId'] as String?) ?? '未知',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Color.fromARGB(221, 164, 164, 164),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '点击右侧进行复制',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      final deviceId =
                                          (_deviceInfo['deviceId'] as String?) ?? '未知';
                                      Clipboard.setData(ClipboardData(text: deviceId));
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
                              ],
                            ),
                          ),
                        ],
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
    super.dispose();
  }
}
