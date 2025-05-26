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
  final UHFController _controller = UHFController();
  final MethodChannel _channel = const MethodChannel('com.example.uhf_plugin/uhf');
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeUHF();
  }

  Future<void> _initializeUHF() async {
    try {
      print('Starting UHF initialization...');
      await _controller.init();
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
      print('UHF initialized successfully');
      widget.onInitialized?.call();
    } catch (e) {
      print('UHF initialization error: $e');
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
  final MethodChannel _channel = const MethodChannel('com.example.uhf_plugin/uhf');
  final EventChannel _eventChannel = const EventChannel('com.example.uhf_plugin/uhf_events');
  final StreamController<Map<String, dynamic>> _tagController = StreamController<Map<String, dynamic>>.broadcast();
  bool _isInitialized = false;
  bool _isScanning = false;
  StreamSubscription? _eventSubscription;
  final List<String> _scannedTags = [];
  String? _lastProcessedEpc;
  DateTime? _lastProcessedTime;

  bool get isInitialized => _isInitialized;
  bool get isScanning => _isScanning;
  Stream<Map<String, dynamic>> get tagStream => _tagController.stream;
  List<String> get scannedTags => List.unmodifiable(_scannedTags);

  Future<void> init() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('init');
      if (result == true) {
        _isInitialized = true;
        _setupEventChannel();
        print('UHF controller initialized');
      } else {
        throw Exception('Failed to initialize UHF device');
      }
    } catch (e) {
      throw Exception('Failed to initialize UHF device: $e');
    }
  }

  void _setupEventChannel() {
    print('Setting up event channel');
    _eventSubscription?.cancel();
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        print('Received raw event: $event');
        if (event is Map) {
          final Map<String, dynamic> tagData = Map<String, dynamic>.from(event);
          print('Processing tag data: $tagData');
          
          if (tagData.containsKey('epc')) {
            final epc = tagData['epc'] as String?;
            if (epc != null && epc.isNotEmpty) {
              final now = DateTime.now();
              if (_lastProcessedEpc != epc || 
                  _lastProcessedTime == null || 
                  now.difference(_lastProcessedTime!).inMilliseconds > 1000) {
                print('Processing new tag: $epc');
                _lastProcessedEpc = epc;
                _lastProcessedTime = now;
                
                if (!_scannedTags.contains(epc)) {
                  _scannedTags.insert(0, epc);
                  if (_scannedTags.length > 100) {
                    _scannedTags.removeLast();
                  }
                  print('Added new tag to list: $epc');
                }
                _tagController.add(tagData);
              } else {
                print('Skipping duplicate tag: $epc');
              }
            }
          }
        }
      },
      onError: (Object error) {
        print('Event channel error: $error');
        _tagController.addError(error);
      },
    );
  }

  Future<bool> setPower(int power) async {
    if (!_isInitialized) {
      throw Exception('UHF device not initialized');
    }
    try {
      final bool? result = await _channel.invokeMethod<bool>('setPower', {'power': power});
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
      print('Starting scan...');
      await _channel.invokeMethod<void>('startScan');
      print('Scan started successfully');
    } catch (e) {
      _isScanning = false;
      print('Error starting scan: $e');
      rethrow;
    }
  }

  Future<void> stopScan() async {
    if (!_isInitialized) {
      throw Exception('UHF device not initialized');
    }
    try {
      print('Stopping scan...');
      await _channel.invokeMethod<void>('stopScan');
      print('Scan stopped successfully');
    } catch (e) {
      print('Error stopping scan: $e');
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
    _eventSubscription?.cancel();
    _tagController.close();
  }
}