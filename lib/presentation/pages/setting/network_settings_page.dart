import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tj_tms_mobile/data/datasources/interceptor/dio_service.dart';
import 'package:tj_tms_mobile/services/location_polling_manager.dart';
import 'package:tj_tms_mobile/core/utils/util.dart' as app_utils;

class NetworkSettingsPage extends StatefulWidget {
  const NetworkSettingsPage({Key? key}) : super(key: key);

  @override
  State<NetworkSettingsPage> createState() => _NetworkSettingsPageState();
}

class _NetworkSettingsPageState extends State<NetworkSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  // final TextEditingController _vmsIpController = TextEditingController();
  final TextEditingController _vpsIpController = TextEditingController();

  // static const String vmsKey = 'network_vms_ip';
  static const String vpsKey = 'network_vps_ip';
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

  Future<void> _loadConfig() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // _vmsIpController.text = prefs.getString(vmsKey) ?? '10.7.100.230:8082';
    _vpsIpController.text = prefs.getString(vpsKey) ?? '10.7.100.22:8082';
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState?.validate() ?? false) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // await prefs.setString(vmsKey, _vmsIpController.text);
      var input = _vpsIpController.text.trim();
      if (!input.startsWith('http')) {
        input = 'http://' + input;
      }
      // 若无端口，默认补充8082
      final uri = Uri.tryParse(input);
      if (uri != null &&
          (uri.hasScheme && uri.host.isNotEmpty) &&
          (uri.port == 0)) {
        input = uri.replace(port: 8082).toString();
      }
      await prefs.setString(vpsKey, input.replaceAll(RegExp(r"/+$"), ''));
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
                           fontWeight: FontWeight.w600,
                           color: Colors.black87,
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 12),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                     decoration: BoxDecoration(
                       color: Colors.grey.shade50,
                       border: Border.all(color: const Color.fromARGB(255, 238, 237, 237)),
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
                                   color: Colors.black87,
                                   letterSpacing: 0.5,
                                 ),
                               ),
                               const SizedBox(height: 4),
                               Text(
                                 '点击右侧按钮复制',
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
                             color: Theme.of(context).primaryColor.withOpacity(0.1),
                             borderRadius: BorderRadius.circular(8),
                           ),
                           child: IconButton(
                             onPressed: () {
                               final deviceId = (_deviceInfo['deviceId'] as String?) ?? '未知';
                               Clipboard.setData(ClipboardData(text: deviceId));
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                   content: Row(
                                     children: [
                                       Icon(
                                         Icons.check_circle,
                                         color: Colors.white,
                                         size: 20,
                                       ),
                                       const SizedBox(width: 8),
                                       const Text('设备ID已复制到剪贴板'),
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
              const SizedBox(height: 32,),
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
                    child: OutlinedButton(
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
    super.dispose();
  }
}
