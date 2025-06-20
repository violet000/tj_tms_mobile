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
            const SnackBar(content: Text('UHF设备初始化成功')),
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
            if (snapshot.hasData && snapshot.data != null) {
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

            // Widget buttonContent = Row(
            //   mainAxisSize: MainAxisSize.min,
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     Text(_isScanning ? widget.stopText! : widget.startText!),
            //     if (_isScanning) ...[
            //       const SizedBox(width: 8),
            //       widget.loadingIndicator ?? const SizedBox(
            //         width: 16,
            //         height: 16,
            //         child: CircularProgressIndicator(
            //           strokeWidth: 2,
            //           valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            //         ),
            //       ),
            //     ],
            //   ],
            // );

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
              onTap: () => _toggleScan(controller),
              // style: ElevatedButton.styleFrom(
              //   backgroundColor:
              //       widget.buttonColor ?? Theme.of(context).primaryColor,
              //   foregroundColor: widget.textColor ?? Colors.white,
              //   minimumSize: Size(
              //     widget.buttonWidth ?? 100,
              //     widget.buttonHeight ?? 40,
              //   ),
              //   padding: widget.padding ??
              //       const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              //   textStyle: TextStyle(
              //     fontSize: widget.fontSize ?? 16,
              //   ),
              // ),
              child: buttonContent,
            );
          },
        );
      },
    );
  }

  Future<void> _toggleScan(UHFController controller) async {
    if (_isScanning) {
      await _stopScan(controller);
    } else {
      await _startScan(controller);
    }
  }

  Future<void> _startScan(UHFController controller) async {
    try {
      setState(() => _isScanning = true);
      widget.onScanStateChanged?.call(true);
      _lastProcessedEpc = null;
      _lastProcessedTime = null;
      await controller.startScan();
    } catch (e) {
      setState(() => _isScanning = false);
      widget.onScanStateChanged?.call(false);
      widget.onError?.call(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('扫描失败: $e')),
        );
      }
    }
  }

  Future<void> _stopScan(UHFController controller) async {
    try {
      await controller.stopScan();
    } catch (e) {
      widget.onError?.call(e.toString());
    } finally {
      setState(() => _isScanning = false);
      widget.onScanStateChanged?.call(false);
      _lastProcessedEpc = null;
      _lastProcessedTime = null;
    }
  }
}
