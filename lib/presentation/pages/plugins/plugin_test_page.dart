import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tj_tms_mobile/core/utils/location_helper.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/uhf_scan_button.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/barcode_scanner_widget.dart';
import 'package:tj_tms_mobile/routes/app_routes.dart';

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

  // UHF扫描相关
  final List<String> _uhfScannedTags = [];
  bool _isUHFScanning = false;

  // 条码扫描相关
  String _barcodeResult = '未扫描';
  bool _isBarcodeScanning = false;

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

  // 定位相关方法
  Future<void> _initializeLocation() async {
    await _locationHelper.initialize();
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

  void _toggleContinuousLocation() {
    if (_locationSubscription == null) {
      final tracking = _locationHelper.startTracking();
      _locationSubscription = tracking.stream.listen((location) {
        if (mounted) {
          setState(() {
            _locationResult = location;
          });
        }
      });
    } else {
      _locationSubscription?.cancel();
      _locationSubscription = null;
    }
  }

  // UHF扫描相关方法
  void _handleUHFTagScanned(String tag) {
    if (!_uhfScannedTags.contains(tag)) {
      setState(() {
        _uhfScannedTags.insert(0, tag);
        if (_uhfScannedTags.length > 100) {
          _uhfScannedTags.removeLast();
        }
      });
    }
  }

  void _handleUHFError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('UHF错误: $error')),
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制到剪贴板')),
      );
    }
  }

  // 条码扫描相关方法
  void _handleBarcodeResult(String result) {
    setState(() {
      _barcodeResult = result;
    });
  }

  void _handleBarcodeError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('条码扫描错误: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
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
            //   Tab(text: 'AGPS定位'),
            //   Tab(text: 'UHF扫描'),
            //   Tab(text: '条码扫描'),
              Tab(text: '活体检测'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // AGPS定位页面
            // _buildLocationPage(),
            // // UHF扫描页面
            // _buildUHFPage(),
            // // 条码扫描页面
            // _buildBarcodePage(),
            // 活体检测页面
            _buildLivenessDetectionPage(),
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
                onPressed: _isLocationLoading ? null : _getSingleLocation,
                child: Text(_isLocationLoading ? '定位中...' : '单次定位'),
              ),
              ElevatedButton(
                onPressed: _toggleContinuousLocation,
                child: Text(_locationSubscription == null ? '持续定位' : '停止定位'),
              ),
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

  Widget _buildUHFPage() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          width: double.infinity,
          child: UHFScanButton(
            buttonWidth: 100,
            buttonHeight: 48,
            onTagScanned: _handleUHFTagScanned,
            onError: _handleUHFError,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _uhfScannedTags.isEmpty
              ? const Center(child: Text('暂无扫描数据'))
              : ListView.builder(
                  itemCount: _uhfScannedTags.length,
                  itemBuilder: (context, index) {
                    final tag = _uhfScannedTags[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text('EPC: $tag'),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () => _copyToClipboard(tag),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBarcodePage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '扫码功能',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '上次扫描结果:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _barcodeResult,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '扫码区域:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  BarcodeScannerWidget(
                    onScanResult: _handleBarcodeResult,
                    onScanError: _handleBarcodeError,
                    autoStart: false,
                    autoRestart: true,
                    resultBuilder: (result) => Text(
                      result,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    errorBuilder: (error) => Text(
                      error,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                    loadingBuilder: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivenessDetectionPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '活体检测功能',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '活体检测说明:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• 支持眨眼、张嘴、左转、右转等动作检测\n'
                    '• 可配置检测动作数量和随机性\n'
                    '• 支持前端和后端防Hack检测\n'
                    '• 提供完整的检测结果回调',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.livenessDetection);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        '进入活体检测',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 