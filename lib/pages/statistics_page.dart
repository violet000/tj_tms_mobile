import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/location_helper.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final LocationHelper _locationHelper = LocationHelper();
  Map<String, dynamic>? _locationResult;
  bool _isLoading = false;
  StreamSubscription<Map<String, dynamic>>? _locationSubscription;

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

  Future<void> _initializeLocation() async {
    await _locationHelper.initialize();
  }

  Future<void> _getSingleLocation() async {
    // 1. 设置加载状态
    setState(() {
      _isLoading = true;
      _locationResult = null;
    });

    try {
      // 2. 调用单点定位
      final result = await _locationHelper.getLocation();
      
      // 3. 更新UI状态
      setState(() {
        _locationResult = result.location;
        _isLoading = false;
      });

      // 4. 处理错误情况
      if (result.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('定位错误: ${result.error}')),
          );
        }
      }
    } catch (e) {
      // 5. 处理异常情况
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('定位异常: $e')),
        );
      }
    }
  }

  void _startContinuousLocation() {
    final tracking = _locationHelper.startTracking();
    _locationSubscription?.cancel();
    _locationSubscription = tracking.stream.listen((location) {
      if (mounted) {
        setState(() {
          _locationResult = location;
        });
      }
    });
  }

  void _stopContinuousLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('位置信息'),
      ),
      body: Column(
        children: [
          // 操作按钮
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _getSingleLocation,
                  child: Text(_isLoading ? '定位中...' : '单次定位'),
                ),
                ElevatedButton(
                  onPressed: _locationSubscription == null 
                      ? _startContinuousLocation 
                      : _stopContinuousLocation,
                  child: Text(_locationSubscription == null ? '持续定位' : '停止定位'),
                ),
              ],
            ),
          ),

          // 位置信息显示
          Expanded(
            child: _locationResult == null
                ? const Center(child: Text('暂无位置信息'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 显示主要位置信息
                        if (_locationResult!['latitude'] != null)
                          _buildLocationItem('纬度', _locationResult!['latitude']),
                        if (_locationResult!['longitude'] != null)
                          _buildLocationItem('经度', _locationResult!['longitude']),
                        if (_locationResult!['address'] != null)
                          _buildLocationItem('地址', _locationResult!['address']),
                        
                        const Divider(),
                        
                        // 显示其他位置信息
                        ..._locationResult!.entries
                            .where((entry) => !['latitude', 'longitude', 'address'].contains(entry.key))
                            .map((entry) => _buildLocationItem(entry.key, entry.value)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
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