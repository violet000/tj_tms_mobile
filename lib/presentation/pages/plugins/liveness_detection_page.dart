import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:tj_tms_mobile/services/liveness_detection_service.dart';
import 'package:tj_tms_mobile/core/config/liveness_config.dart';

class LivenessDetectionPage extends StatefulWidget {
  const LivenessDetectionPage({Key? key}) : super(key: key);

  @override
  State<LivenessDetectionPage> createState() => _LivenessDetectionPageState();
}

class _LivenessDetectionPageState extends State<LivenessDetectionPage> {
  bool _isInitialized = false;
  bool _isAvailable = false;
  
  // 配置参数 - 从配置文件获取
  final String _license = LivenessConfig.license;
  final String _packageLicense = LivenessConfig.packageLicense;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  /// 检查活体检测是否可用
  Future<void> _checkAvailability() async {
    try {
      final bool available = await LivenessDetectionService.isAvailable();
      setState(() {
        _isAvailable = available;
      });
    } catch (e) {
      print('检查活体检测可用性失败: $e');
    }
  }

  /// 初始化活体检测
  Future<void> _initializeLivenessDetection() async {
    try {
      EasyLoading.show(status: '初始化中...');
      
      final bool success = await LivenessDetectionService.initialize(
        license: _license,
        packageLicense: _packageLicense,
      );
      
      EasyLoading.dismiss();
      
      if (success) {
        setState(() {
          _isInitialized = true;
        });
        EasyLoading.showSuccess('初始化成功');
      } else {
        EasyLoading.showError('初始化失败');
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('初始化失败: $e');
    }
  }

  /// 开始活体检测
  Future<void> _startLivenessDetection() async {
    if (!_isInitialized) {
      EasyLoading.showError('请先初始化活体检测');
      return;
    }

    try {
      EasyLoading.show(status: '启动活体检测...');
      
      final bool success = await LivenessDetectionService.startLivenessDetection();
      
      EasyLoading.dismiss();
      
      if (success) {
        EasyLoading.showSuccess('活体检测已启动');
      } else {
        EasyLoading.showError('启动活体检测失败');
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('启动活体检测失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('活体检测'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 状态信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '活体检测状态',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          _isAvailable ? Icons.check_circle : Icons.error,
                          color: _isAvailable ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text('可用性: ${_isAvailable ? "可用" : "不可用"}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isInitialized ? Icons.check_circle : Icons.pending,
                          color: _isInitialized ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text('初始化状态: ${_isInitialized ? "已初始化" : "未初始化"}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 配置信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '配置信息',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text('License: ${_license.substring(0, 10)}...'),
                    const SizedBox(height: 8),
                    Text('Package License: ${_packageLicense.substring(0, 10)}...'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 操作按钮
            if (!_isInitialized)
              ElevatedButton(
                onPressed: _isAvailable ? _initializeLivenessDetection : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '初始化活体检测',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            
            if (_isInitialized) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _startLivenessDetection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '开始活体检测',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // 说明信息
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '使用说明',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. 首先点击"初始化活体检测"按钮\n'
                      '2. 初始化成功后，点击"开始活体检测"\n'
                      '3. 按照屏幕提示完成眨眼、张嘴、左转、右转等动作\n'
                      '4. 检测完成后会显示结果',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 