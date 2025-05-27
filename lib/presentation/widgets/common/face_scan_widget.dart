import 'package:flutter/material.dart';
import 'dart:convert';

// 人脸扫描组件
class FaceScanWidget extends StatefulWidget {
  final VoidCallback onTap;
  final double width;
  final double height;
  final Color frameColor;
  final Color iconColor;
  final double iconSize;
  final String hintText;
  final TextStyle? hintStyle;
  final String? imageBase64;

  const FaceScanWidget({
    Key? key,
    required this.onTap,
    this.width = 200,
    this.height = 120,
    this.frameColor = Colors.blue,
    this.iconColor = Colors.blue,
    this.iconSize = 70,
    this.hintText = '点击进行人脸识别',
    this.hintStyle,
    this.imageBase64,
  }) : super(key: key);

  @override
  State<FaceScanWidget> createState() => _FaceScanWidgetState();
}

class _FaceScanWidgetState extends State<FaceScanWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 扫描框
            CustomPaint(
              size: Size(widget.width, widget.height),
              painter: ScanFramePainter(
                color: widget.frameColor.withOpacity(0.5),
                lineWidth: 2,
              ),
            ),
            // 扫描线
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Positioned(
                  top: widget.height * _animation.value,
                  child: Container(
                    width: widget.width,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          widget.frameColor.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.frameColor.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // 人脸图标
            Positioned(
              top: 20,
              child: Icon(
                Icons.person,
                size: widget.iconSize,
                color: widget.iconColor.withOpacity(0.3),
              ),
            ),
            // 扫描提示文字
            Positioned(
              bottom: 0,
              child: Text(
                widget.hintText,
                style: widget.hintStyle ?? TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanFramePainter extends CustomPainter {
  final Color color;
  final double lineWidth;
  final double cornerLength;

  ScanFramePainter({
    required this.color,
    this.lineWidth = 2,
    this.cornerLength = 20,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth;

    final width = size.width;
    final height = size.height;

    // 绘制四个角的L形边框
    // 左上角
    canvas.drawLine(Offset(0, cornerLength), Offset(0, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(cornerLength, 0), paint);

    // 右上角
    canvas.drawLine(Offset(width - cornerLength, 0), Offset(width, 0), paint);
    canvas.drawLine(Offset(width, 0), Offset(width, cornerLength), paint);

    // 左下角
    canvas.drawLine(Offset(0, height - cornerLength), Offset(0, height), paint);
    canvas.drawLine(Offset(0, height), Offset(cornerLength, height), paint);

    // 右下角
    canvas.drawLine(Offset(width - cornerLength, height), Offset(width, height), paint);
    canvas.drawLine(Offset(width, height - cornerLength), Offset(width, height), paint);
  }

  @override
  bool shouldRepaint(ScanFramePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.lineWidth != lineWidth;
  }
} 