import 'package:flutter/material.dart';
import 'package:tj_tms_mobile/services/location_polling_manager.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';

class LocationPollingTestPage extends StatefulWidget {
  const LocationPollingTestPage({super.key});

  @override
  State<LocationPollingTestPage> createState() => _LocationPollingTestPageState();
}

class _LocationPollingTestPageState extends State<LocationPollingTestPage> with WidgetsBindingObserver {
  final LocationPollingManager _locationPollingManager = LocationPollingManager();
  Map<String, dynamic>? _currentLocation;
  Map<String, dynamic>? _status;
  List<String> _logMessages = [];
  AppLifecycleState _currentLifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    // 注册应用生命周期监听
    WidgetsBinding.instance.addObserver(this);
    _initializeLocationPolling();
  }

  Future<void> _initializeLocationPolling() async {
    try {
      await _locationPollingManager.initialize();
      
      // 设置回调函数
      _locationPollingManager.setCallbacks(
        onLocationUpdate: (location) {
          setState(() {
            _currentLocation = location;
            _addLogMessage('位置更新: 纬度=${location['latitude']}, 经度=${location['longitude']}');
          });
        },
        onError: (error) {
          _addLogMessage('错误: $error');
        },
      );
      
      _updateStatus();
    } catch (e) {
      _addLogMessage('初始化失败: $e');
    }
  }

  void _addLogMessage(String message) {
    setState(() {
      _logMessages.add('${DateTime.now().toString().substring(11, 19)}: $message');
      if (_logMessages.length > 50) {
        _logMessages.removeAt(0);
      }
    });
  }

  void _updateStatus() {
    setState(() {
      _status = _locationPollingManager.getStatus();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _currentLifecycleState = state;
    });
    _addLogMessage('应用生命周期状态变化: $state');
  }

  void _togglePolling() {
    if (_locationPollingManager.isPolling) {
      _locationPollingManager.stopPolling();
      _addLogMessage('停止位置轮询');
    } else {
      _locationPollingManager.startPolling();
      _addLogMessage('启动位置轮询');
    }
    _updateStatus();
  }

  void _setPollingInterval(int seconds) {
    _locationPollingManager.setPollingInterval(seconds);
    _addLogMessage('设置轮询间隔为${seconds}秒');
    _updateStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('位置轮询测试'),
        backgroundColor: const Color(0xFF29A8FF),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状态信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '轮询状态',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildStatusItem('轮询中', _status!['isPolling'] ?? false),
                    _buildStatusItem('轮询间隔', '${_status!['interval'] ?? 0}秒'),
                    _buildStatusItem('有位置数据', _status!['hasLocation'] ?? false),
                    _buildStatusItem('启用轮询', _status!['enablePolling'] ?? false),
                    _buildStatusItem('启用日志', _status!['enableLogging'] ?? false),
                    _buildStatusItem('需要上传', _status!['shouldUpload'] ?? false),
                    _buildStatusItem('应用状态', _currentLifecycleState.toString().split('.').last),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 控制按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _togglePolling,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _locationPollingManager.isPolling 
                          ? Colors.red 
                          : const Color(0xFF29A8FF),
                    ),
                    child: Text(
                      _locationPollingManager.isPolling ? '停止轮询' : '开始轮询',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _setPollingInterval(30),
                    child: const Text('30秒间隔'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _setPollingInterval(60),
                    child: const Text('60秒间隔'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 当前位置信息
            if (_currentLocation != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '当前位置',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _buildLocationItem('纬度', _currentLocation!['latitude']),
                      _buildLocationItem('经度', _currentLocation!['longitude']),
                      if (_currentLocation!['address'] != null)
                        _buildLocationItem('地址', _currentLocation!['address']),
                      if (_currentLocation!['accuracy'] != null)
                        _buildLocationItem('精度', '${_currentLocation!['accuracy']}米'),
                      if (_currentLocation!['time'] != null)
                        _buildLocationItem('时间', _currentLocation!['time']),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // 日志信息
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '日志信息',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _logMessages.clear();
                              });
                            },
                            child: const Text('清空'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _logMessages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text(
                                _logMessages[index],
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: TextStyle(
              color: value is bool 
                  ? (value ? Colors.green : Colors.red)
                  : Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '未知',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // 移除应用生命周期监听
    WidgetsBinding.instance.removeObserver(this);
    _locationPollingManager.dispose();
    super.dispose();
  }
} 