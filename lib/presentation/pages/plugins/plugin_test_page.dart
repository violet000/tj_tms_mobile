import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tj_tms_mobile/services/location_helper.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/uhf_scan_button.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/barcode_scanner_widget.dart';
import 'package:tj_tms_mobile/routes/app_routes.dart';
import 'package:tj_tms_mobile/core/utils/common_util.dart' as app_utils;
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';
import 'package:tj_tms_mobile/data/datasources/api/9087/service_9087.dart';

// 内置GPS定位测试
class PluginTestPage extends StatefulWidget {
  const PluginTestPage({super.key});

  @override
  State<PluginTestPage> createState() => _PluginTestPageState();
}

class _PluginTestPageState extends State<PluginTestPage> {
  // 定位相关
  final LocationHelper _locationHelper = LocationHelper();
  Map<String, dynamic>? _locationResult;
  bool _isLocationLoading = false;
  StreamSubscription<Map<String, dynamic>>? _locationSubscription;
  ContinuousLocationResult? _continuousHandle;
  int _callbackCount = 0;
  DateTime? _lastCallbackAt;
  Service9087? _service9087;
  Map<String, dynamic> _deviceInfo = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _locationHelper.dispose();
    super.dispose();
  }

  // 加载设备信息
  Future<void> _loadDeviceInfo() async {
    final info = await app_utils.loadDeviceInfo();
    _deviceInfo = info;
  }

  // 定位相关方法
  Future<void> _initializeLocation() async {
    await _locationHelper.initialize();
    await _loadDeviceInfo();
    _service9087 = await Service9087.create();
  }

  Future<void> _getSingleLocation() async {
    setState(() {
      _isLocationLoading = true;
      _locationResult = null;
    });

    try {
      final result = await _locationHelper.getLocation();
      setState(() {
        _locationResult = result.location;
        _isLocationLoading = false;
      });

      if (result.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('定位错误: ${result.error}')),
        );
      }
    } catch (e) {
      setState(() => _isLocationLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('定位异常: $e')),
        );
      }
    }
  }

  // 上传位置数据（Home 页已停用GPS定位）
  Future<void> _uploadLocationData(Map<String, dynamic> location) async {
    try {
      final dynamic latitude = location['latitude'];
      final dynamic longitude = location['longitude'];
      final date = DateTime.now();
      final formattedDateTime = _formatDateTime(date);
      if (latitude != null && longitude != null) {
        await _service9087?.sendGpsInfo(<String, dynamic>{
          'handheldNo': _deviceInfo['deviceId'],
          'x': latitude,
          'y': longitude,
          'timestamp': date.millisecondsSinceEpoch,
          'dateTime': formattedDateTime,
          'status': 'valid',
        });
        return;
      }
    } catch (e) {
      AppLogger.error('上送失败: $e');
    }
  }

  // 格式化日期时间
  String _formatDateTime(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}:${two(date.second)}';
  }

  void _toggleContinuousLocation() {
    if (_locationSubscription == null) {
      _continuousHandle = _locationHelper.startTracking();
      _locationSubscription = _continuousHandle!.stream.listen((location) {
        // ignore: avoid_print
        print('[PluginTestPage] 收到定位: ${location['latitude']}, ${location['longitude']}');
        if (mounted) {
          setState(() {
            _locationResult = location;
            _callbackCount += 1;
            _lastCallbackAt = DateTime.now();
          });
        }
        _uploadLocationData(location);
      });
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已开启持续定位')),
        );
      }
    } else {
      _locationSubscription?.cancel();
      _locationSubscription = null;
      _continuousHandle?.stopTracking();
      _continuousHandle = null;
      _callbackCount = 0;
      _lastCallbackAt = null;
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已停止持续定位')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('插件测试'),
          bottom: const TabBar(
            labelColor: Color(0xFF29A8FF),
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
            indicatorColor: Color(0xFF29A8FF),
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'GPS定位'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLocationPage(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLocationPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: (_isLocationLoading || _locationSubscription != null)
                    ? null
                    : _getSingleLocation,
                child: Text(
                  _locationSubscription != null
                      ? '单次定位(禁用)'
                      : (_isLocationLoading ? '定位中...' : '单次定位'),
                ),
              ),
              ElevatedButton(
                onPressed: _toggleContinuousLocation,
                child: Text(_locationSubscription == null ? '持续定位' : '停止定位'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_locationSubscription == null ? '状态: 空闲' : '状态: 持续定位中'),
              Text('来源: ${_locationResult != null && _locationResult!['from'] != null ? _locationResult!['from'] : '-'}'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('累计回调: $_callbackCount'),
              Text('最近: ${_lastCallbackAt != null ? _formatTime(_lastCallbackAt!) : '-'}'),
            ],
          ),
        ),
        Expanded(
          child: _locationResult == null
              ? const Center(child: Text('暂无位置信息'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_locationResult!['latitude'] != null)
                        _buildLocationItem('纬度', _locationResult!['latitude']),
                      if (_locationResult!['longitude'] != null)
                        _buildLocationItem('经度', _locationResult!['longitude']),
                      if (_locationResult!['accuracy'] != null)
                        _buildLocationItem('精度(m)', _locationResult!['accuracy']),
                      if (_locationResult!['coordinateType'] != null)
                        _buildLocationItem('坐标系', _locationResult!['coordinateType']),
                      if (_locationResult!['from'] != null)
                        _buildLocationItem('来源', _locationResult!['from']),
                      if (_locationResult!['address'] != null)
                        _buildLocationItem('地址', _locationResult!['address']),
                      const Divider(),
                      ..._locationResult!.entries
                          .where((entry) => !['latitude', 'longitude', 'address'].contains(entry.key))
                          .map((entry) => _buildLocationItem(entry.key, entry.value)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  Widget _buildLocationItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
} 