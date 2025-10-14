import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class UHFPluginWidget extends StatefulWidget {
  final Widget Function(BuildContext context, UHFController controller) builder;
  final void Function(String error)? onError;
  final void Function()? onInitialized;
  final void Function()? onDisposed;

  const UHFPluginWidget({
    super.key,
    required this.builder,
    this.onError,
    this.onInitialized,
    this.onDisposed,
  });

  @override
  State<UHFPluginWidget> createState() => _UHFPluginWidgetState();
}

class _UHFPluginWidgetState extends State<UHFPluginWidget> {
  final UHFController _controller = UHFController.instance;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeUHF();
  }

  Future<void> _initializeUHF() async {
    try {
      await _controller.init();
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
      widget.onInitialized?.call();
    } catch (e) {
      widget.onError?.call(e.toString());
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.onDisposed?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return widget.builder(context, _controller);
  }
}

class UHFController {
  // 单例模式
  static UHFController? _instance;
  static UHFController get instance {
    _instance ??= UHFController._internal();
    return _instance!;
  }
  
  UHFController._internal();
  
  final MethodChannel _channel =
      const MethodChannel('com.example.uhf_plugin/uhf');
  final EventChannel _eventChannel =
      const EventChannel('com.example.uhf_plugin/uhf_events');
  final StreamController<Map<String, dynamic>> _tagController =
      StreamController<Map<String, dynamic>>.broadcast();
  bool _isInitialized = false;
  bool _isScanning = false;
  StreamSubscription? _eventSubscription;
  final List<String> _scannedTags = [];
  String? _lastProcessedEpc;
  DateTime? _lastProcessedTime;
  int _referenceCount = 0; // 引用计数，用于管理生命周期

  bool get isInitialized => _isInitialized;
  bool get isScanning => _isScanning;
  Stream<Map<String, dynamic>> get tagStream => _tagController.stream;
  List<String> get scannedTags => List.unmodifiable(_scannedTags);

  Future<void> init() async {
    _referenceCount++;
    if (_isInitialized) {
      return;
    }
    
    try {
      final bool? result = await _channel.invokeMethod<bool>('init');
      if (result == true) {
        _isInitialized = true;
        _setupEventChannel();
      } else {
        throw Exception('Failed to initialize UHF device');
      }
    } catch (e) {
      throw Exception('Failed to initialize UHF device: $e');
    }
  }

  void _setupEventChannel() {
    _eventSubscription?.cancel();
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          final Map<String, dynamic> tagData = Map<String, dynamic>.from(event);

          if (tagData.containsKey('epc')) {
            final epc = tagData['epc'] as String?;
            if (epc != null && epc.isNotEmpty) {
              final shortEpc = epc.length > 8 ? epc.substring(0, 8) : epc;
              if (!_scannedTags.contains(shortEpc)) {
                _scannedTags.insert(0, shortEpc);
                if (_scannedTags.length > 100) {
                  _scannedTags.removeLast();
                }
              }
              _tagController.add(tagData);
            }
          }
        }
      },
      onError: (Object error) {
        _tagController.addError(error);
      },
    );
  }

  Future<bool> setPower(int power) async {
    if (!_isInitialized) {
      throw Exception('UHF device not initialized');
    }
    try {
      final bool? result =
          await _channel.invokeMethod<bool>('setPower', {'power': power});
      return result ?? false;
    } catch (e) {
      throw Exception('Failed to set power: $e');
    }
  }

  Future<void> startScan() async {
    if (!_isInitialized) {
      throw Exception('UHF device not initialized');
    }
    try {
      _isScanning = true;
      _lastProcessedEpc = null;
      _lastProcessedTime = null;
      await _channel.invokeMethod<void>('startScan');
    } catch (e) {
      _isScanning = false;
      rethrow;
    }
  }

  Future<void> stopScan() async {
    if (!_isInitialized) {
      throw Exception('UHF device not initialized');
    }
    try {
      await _channel.invokeMethod<void>('stopScan');
    } catch (e) {
      rethrow;
    } finally {
      _isScanning = false;
      _lastProcessedEpc = null;
      _lastProcessedTime = null;
    }
  }

  void clearTags() {
    _scannedTags.clear();
  }

  Future<void> writeTag(String epc) async {
    if (!_isInitialized) {
      throw Exception('UHF device not initialized');
    }
    try {
      await _channel.invokeMethod<void>('writeTag', {'epc': epc});
    } catch (e) {
      throw Exception('Failed to write tag: $e');
    }
  }

  Future<void> lockTag(String epc) async {
    if (!_isInitialized) {
      throw Exception('UHF device not initialized');
    }
    try {
      await _channel.invokeMethod<void>('lockTag', {'epc': epc});
    } catch (e) {
      throw Exception('Failed to lock tag: $e');
    }
  }

  Future<void> killTag(String epc) async {
    if (!_isInitialized) {
      throw Exception('UHF device not initialized');
    }
    try {
      await _channel.invokeMethod<void>('killTag', {'epc': epc});
    } catch (e) {
      throw Exception('Failed to kill tag: $e');
    }
  }

  void dispose() {
    _referenceCount--;
    
    if (_referenceCount <= 0) {
      _eventSubscription?.cancel();
      _tagController.close();
      _isInitialized = false;
      _isScanning = false;
      _referenceCount = 0;
      _instance = null; // 重置单例实例
    }
  }
}
