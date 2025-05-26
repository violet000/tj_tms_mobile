import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../providers/auth_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final NetworkInfo _networkInfo = NetworkInfo();
  Map<String, dynamic> _deviceData = {};
  bool _isLoading = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initDeviceInfo();
      _initialized = true;
    }
  }

  Future<void> _initDeviceInfo() async {
    try {
      print('开始获取设备信息...');
      if (Theme.of(context).platform == TargetPlatform.android) {
        print('检测到 Android 平台');
        final androidInfo = await _deviceInfo.androidInfo;
        print('获取到的 Android 信息: $androidInfo');
        
        // 获取 MAC 地址
        String? macAddress = await _networkInfo.getWifiBSSID();
        print('MAC 地址: $macAddress');
        
        setState(() {
          _deviceData = {
            '设备型号': androidInfo.model,
            '品牌': androidInfo.brand,
            '制造商': androidInfo.manufacturer,
            'Android版本': androidInfo.version.release,
            'SDK版本': androidInfo.version.sdkInt.toString(),
            '设备ID': androidInfo.id,
            '硬件名称': androidInfo.hardware,
            '设备类型': androidInfo.device,
            '产品名称': androidInfo.product,
            'UUID': androidInfo.id,
            'MAC地址': macAddress ?? '未知',
            '指纹': androidInfo.fingerprint,
            '主机': androidInfo.host,
            '标签': androidInfo.tags,
            '类型': androidInfo.type,
            '是否物理设备': androidInfo.isPhysicalDevice ? '是' : '否',
          };
          _isLoading = false;
        });
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        print('检测到 iOS 平台');
        final iosInfo = await _deviceInfo.iosInfo;
        print('获取到的 iOS 信息: $iosInfo');
        
        // 获取 MAC 地址
        String? macAddress = await _networkInfo.getWifiBSSID();
        print('MAC 地址: $macAddress');
        
        setState(() {
          _deviceData = {
            '设备型号': iosInfo.model,
            '设备名称': iosInfo.name,
            '系统名称': iosInfo.systemName,
            '系统版本': iosInfo.systemVersion,
            '设备ID': iosInfo.identifierForVendor ?? '未知',
            'UUID': iosInfo.identifierForVendor ?? '未知',
            'MAC地址': macAddress ?? '未知',
            '是否物理设备': iosInfo.isPhysicalDevice ? '是' : '否',
            '本地化模型': iosInfo.localizedModel,
          };
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('获取设备信息时发生错误: $e');
      print('错误堆栈: $stackTrace');
      setState(() {
        _deviceData = {
          '错误': '获取设备信息失败',
          '错误详情': e.toString(),
          '错误堆栈': stackTrace.toString(),
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // 用户信息卡片
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '网络配置信息',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 设备信息卡片
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '设备信息',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else
                    ..._deviceData.entries.map((entry) => _buildDeviceInfoRow(
                          entry.key,
                          entry.value.toString(),
                        )),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }


  Widget _buildDeviceInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label：',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}