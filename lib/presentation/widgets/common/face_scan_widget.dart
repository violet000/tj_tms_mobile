import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';

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
  final VoidCallback? onDelete;

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
    this.onDelete,
  }) : super(key: key);

  @override
  State<FaceScanWidget> createState() => _FaceScanWidgetState();
}

class _FaceScanWidgetState extends State<FaceScanWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  void _showImagePreview() {
    if (widget.imageBase64 == null) return;
    
    showDialog<dynamic>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 图片预览
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(widget.imageBase64!),
                fit: BoxFit.contain,
              ),
            ),
            // 关闭按钮
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
  void didUpdateWidget(FaceScanWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.imageBase64 != null ? _showImagePreview : widget.onTap,
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
            if (widget.imageBase64 == null)
              CustomPaint(
                size: Size(widget.width, widget.height),
                painter: ScanFramePainter(
                  color: widget.frameColor.withOpacity(0.5),
                  lineWidth: 2,
                ),
              ),
            // 照片回显或人脸图标
            if (widget.imageBase64 != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  base64Decode(widget.imageBase64!),
                  width: widget.width,
                  height: widget.height,
                  fit: BoxFit.cover,
                  cacheWidth: (widget.width * MediaQuery.of(context).devicePixelRatio).toInt(),
                  cacheHeight: (widget.height * MediaQuery.of(context).devicePixelRatio).toInt(),
                ),
              )
            else
              Positioned(
                top: 20,
                child: SvgPicture.asset(
                  'assets/icons/user_person.svg',
                  width: widget.iconSize,
                  height: widget.iconSize,
                ),
              ),
            // 扫描提示文字
            if (widget.imageBase64 == null)
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
            // 删除按钮
            if (widget.imageBase64 != null)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            // 扫描线 - 放在最上层
            if (widget.imageBase64 == null)
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
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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