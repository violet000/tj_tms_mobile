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
  ContinuousLocationResult? _continuousHandle;
  int _callbackCount = 0;
  DateTime? _lastCallbackAt;

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
    // 只取消本页面的订阅，不释放 LocationHelper（单例，由应用生命周期管理）
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _continuousHandle?.stopTracking();
    _continuousHandle = null;
    // 不调用 _locationHelper.dispose()，因为 LocationManager 是单例，可能被其他组件使用
    super.dispose();
  }

  // 定位相关方法
  Future<void> _initializeLocation() async {
    await _locationHelper.initialize();
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
              Tab(text: 'AGPS定位'),
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
                onPressed: null,
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

} 