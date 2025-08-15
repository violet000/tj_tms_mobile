import 'package:flutter/material.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tj_tms_mobile/data/datasources/interceptor/dio_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // _vmsIpController.text = prefs.getString(vmsKey) ?? '10.34.12.130:9087';
    _vpsIpController.text = prefs.getString(vpsKey) ?? '10.7.100.22:8082';
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState?.validate() ?? false) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // await prefs.setString(vmsKey, _vmsIpController.text);
      await prefs.setString(vpsKey, _vpsIpController.text);
      DioServiceManager().clearAllServices();
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
