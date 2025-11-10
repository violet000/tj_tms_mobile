import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/uhf_plugin_widget.dart';

class UHFScanButton extends StatefulWidget {
  final String? startText;
  final String? stopText;
  final Color? buttonColor;
  final Color? textColor;
  final double? buttonHeight;
  final double? buttonWidth;
  final double? fontSize;
  final EdgeInsets? padding;
  final Widget? loadingIndicator;
  final bool? isAutoRefresh;
  final Function(String tag)? onTagScanned;
  final Function(bool isScanning)? onScanStateChanged;
  final Function(String error)? onError;

  const UHFScanButton({
    super.key,
    this.startText = 'UHF扫描',
    this.stopText = 'UHF停止',
    this.buttonColor,
    this.textColor,
    this.buttonHeight,
    this.buttonWidth,
    this.fontSize,
    this.padding,
    this.loadingIndicator,
    this.isAutoRefresh = false, // 默认是不自动刷新的
    this.onTagScanned,
    this.onScanStateChanged,
    this.onError,
  });

  @override
  State<UHFScanButton> createState() => _UHFScanButtonState();
}

class _UHFScanButtonState extends State<UHFScanButton> {
  bool _isScanning = false;
  final List<String> _scannedTags = [];
  String? _lastProcessedEpc;
  DateTime? _lastProcessedTime;
  bool _isStarting = false;

  List<String> get scannedTags => List.unmodifiable(_scannedTags);

  @override
  Widget build(BuildContext context) {
    return UHFPluginWidget(
      onError: (String error) {
        widget.onError?.call(error);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('错误: $error')),
          );
        }
      },
      onInitialized: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('UHF设备初始化成功'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      onDisposed: () {
        // 移除在 dispose 时显示 SnackBar
        // 因为此时 Widget 树已经不完整了
      },
      builder: (context, controller) {
        return StreamBuilder<Map<String, dynamic>>(
          stream: controller.tagStream,
          builder: (context, snapshot) {
            // 只有当按钮处于扫描状态时才处理标签事件，避免其他扫描按钮的标签被误处理
            // 注意：不自动同步 controller.isScanning，因为多个按钮共享同一个 controller
            // 每个按钮应该只根据自己的点击状态来管理 _isScanning
            if (_isScanning && snapshot.hasData && snapshot.data != null) {
              final tagData = snapshot.data!;
              if (tagData.containsKey('epc')) {
                final epc = tagData['epc'] as String?;
                if (epc != null && epc.isNotEmpty) {
                  // 防抖处理：同一标签在1秒内只处理一次
                  final now = DateTime.now();
                  if (_lastProcessedEpc != epc || _lastProcessedTime == null) {
                    _lastProcessedEpc = epc;
                    _lastProcessedTime = now;
                    Future.microtask(() {
                      widget.onTagScanned?.call(epc);
                    });
                  }
                }
              }
            }

            Widget buttonContent = Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.transparent,
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/scan_cashbox.svg',
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isScanning ? widget.stopText! : widget.startText!,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 2, 121, 212),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            );

            if (snapshot.hasError) {
              return ElevatedButton(
                onPressed: () => _toggleScan(controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      widget.buttonColor ?? Theme.of(context).primaryColor,
                  foregroundColor: widget.textColor ?? Colors.white,
                  minimumSize: Size(
                    widget.buttonWidth ?? 100,
                    widget.buttonHeight ?? 40,
                  ),
                  padding: widget.padding ??
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: TextStyle(
                    fontSize: widget.fontSize ?? 16,
                  ),
                ),
                child: Text('错误: ${snapshot.error}'),
              );
            }

            return InkWell(
              onTap: () {
                if (_isScanning && widget.isAutoRefresh == true) {
                  _stopScan(controller).then((_) {
                    Future.delayed(const Duration(milliseconds: 200), () {
                      _startScan(controller);
                    });
                  });
                } else {
                  _toggleScan(controller);
                }
              },
              child: buttonContent,
            );
          },
        );
      },
    );
  }

  Future<void> _toggleScan(UHFController controller) async {
    if (_isStarting) {
      return;
    }
    // 注意：不自动同步 controller.isScanning，因为多个按钮共享同一个 controller
    // 如果 controller 正在扫描但当前按钮的 _isScanning 为 false，说明是其他按钮在扫描
    // 此时应该先停止其他按钮的扫描，再开始当前按钮的扫描
    if (controller.isScanning && !_isScanning) {
      // 其他按钮正在扫描，先停止
      try {
        await controller.stopScan();
        await Future<void>.delayed(const Duration(milliseconds: 150));
      } catch (e) {
        // 忽略错误
      }
    }
    if (_isScanning) {
      await _stopScan(controller);
    } else {
      await _startScan(controller);
    }
  }

  Future<void> _startScan(UHFController controller) async {
    try {
      if (_isStarting) return;
      _isStarting = true;
      // 先尝试停止一次，确保设备处于可启动状态
      try {
        await controller.stopScan();
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 150));

      _lastProcessedEpc = null;
      _lastProcessedTime = null;

      // 提前设置扫描状态，确保首次点击即可进入扫描态
      if (mounted) {
        setState(() => _isScanning = true);
      } else {
        _isScanning = true;
      }
      widget.onScanStateChanged?.call(true);

      await controller.startScan();

      // 启动后1秒内未收到任何标签，自动重启一次以增强可靠性
      Future<void>.delayed(const Duration(seconds: 1), () async {
        if (!mounted) return;
        if (_isScanning && _lastProcessedEpc == null) {
          try {
            await controller.stopScan();
            await Future<void>.delayed(const Duration(milliseconds: 150));
            await controller.startScan();
          } catch (e) {
            widget.onError?.call(e.toString());
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
      } else {
        _isScanning = false;
      }
      widget.onScanStateChanged?.call(false);
      widget.onError?.call(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('扫描失败: $e')),
        );
      }
    }
    finally {
      _isStarting = false;
    }
  }

  Future<void> _stopScan(UHFController controller) async {
    try {
      await controller.stopScan();
    } catch (e) {
      widget.onError?.call(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      } else {
        _isScanning = false;
      }
      widget.onScanStateChanged?.call(false);
      _lastProcessedEpc = null;
      _lastProcessedTime = null;
    }
  }
}
