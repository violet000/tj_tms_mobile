import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:developer' as developer;

class BarcodeScannerWidget extends StatefulWidget {
  /// 扫描结果回调函数
  final Function(String) onScanResult;
  
  /// 扫描错误回调函数
  final Function(String)? onScanError;
  
  /// 是否自动开始扫描
  final bool autoStart;
  
  /// 是否在扫描成功后自动开始下一次扫描
  final bool autoRestart;
  
  /// 自定义扫描按钮
  final Widget? scanButton;
  
  /// 自定义结果显示组件
  final Widget Function(String)? resultBuilder;
  
  /// 自定义错误显示组件
  final Widget Function(String)? errorBuilder;
  
  /// 自定义加载状态显示组件
  final Widget? loadingBuilder;

  const BarcodeScannerWidget({
    Key? key,
    required this.onScanResult,
    this.onScanError,
    this.autoStart = false,
    this.autoRestart = true,
    this.scanButton,
    this.resultBuilder,
    this.errorBuilder,
    this.loadingBuilder,
  }) : super(key: key);

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  static const platform = MethodChannel('com.example.tj_tms_mobile/barcode_scanner');
  static const eventChannel = EventChannel('com.example.tj_tms_mobile/barcode_events');
  
  String _scanResult = '未扫描';
  bool _isScanning = false;
  String _errorMessage = '';
  StreamSubscription? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _setupEventChannel();
    if (widget.autoStart) {
      _startNewScan();
    }
  }

  void _setupEventChannel() {
    _eventSubscription = eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (mounted) {
          setState(() {
            _scanResult = event.toString();
            _errorMessage = '';
            _isScanning = false;
          });
          // 调用回调函数
          widget.onScanResult(_scanResult);
          // 如果设置了自动重启，则开始新的扫描
          if (widget.autoRestart) {
            _startNewScan();
          }
        } else {
          developer.log('组件未挂载，忽略更新', name: 'BarcodeScanner');
        }
      },
      onError: (dynamic error) {
        if (mounted) {
          setState(() {
            _errorMessage = "事件通道错误: $error";
            _isScanning = false;
          });
          widget.onScanError?.call(_errorMessage);
        }
      },
      cancelOnError: false,
    );
  }

  Future<void> _startNewScan() async {
    if (!mounted || _isScanning) return;
    
    try {
      // final result = await platform.invokeMethod('startScan');
      if (mounted) {
        setState(() {
          _isScanning = true;
          _errorMessage = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "开始扫描失败: $e";
          _isScanning = false;
        });
        widget.onScanError?.call(_errorMessage);
      }
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleScan() async {
    try {
      if (_isScanning) {
        // final result = await platform.invokeMethod('stopScan');
        if (mounted) {
          setState(() {
            _isScanning = false;
            _errorMessage = '';
          });
        }
      } else {
        await _startNewScan();
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "扫描错误: ${e.message}";
          _isScanning = false;
        });
        widget.onScanError?.call(_errorMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "未知错误: $e";
          _isScanning = false;
        });
        widget.onScanError?.call(_errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isScanning && widget.loadingBuilder != null)
          widget.loadingBuilder!
        else if (_errorMessage.isNotEmpty && widget.errorBuilder != null)
          widget.errorBuilder!(_errorMessage)
        else if (widget.resultBuilder != null)
          widget.resultBuilder!(_scanResult)
        else
          Text(
            _scanResult,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        if (widget.scanButton != null)
          widget.scanButton!
        else
          FloatingActionButton(
            onPressed: _toggleScan,
            tooltip: _isScanning ? '停止扫描' : '开始扫描',
            child: Icon(_isScanning ? Icons.stop : Icons.qr_code_scanner),
          ),
      ],
    );
  }
} 