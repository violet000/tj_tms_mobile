import 'package:flutter/material.dart';
import 'dart:math';

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double gap;

  DashedBorderPainter({
    this.color = Colors.black,
    this.strokeWidth = 2,
    this.dashWidth = 6,
    this.gap = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    void drawDashedLine(Offset start, Offset end) {
      double dx = end.dx - start.dx;
      double dy = end.dy - start.dy;
      double distance = sqrt(dx * dx + dy * dy);
      int dashCount = (distance ~/ (dashWidth + gap));
      double dashDx = dx / distance * dashWidth;
      double gapDx = dx / distance * gap;
      double dashDy = dy / distance * dashWidth;
      double gapDy = dy / distance * gap;

      double x = start.dx, y = start.dy;
      for (int i = 0; i < dashCount; i++) {
        canvas.drawLine(Offset(x, y), Offset(x + dashDx, y + dashDy), paint);
        x += dashDx + gapDx;
        y += dashDy + gapDy;
      }
    }

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    drawDashedLine(rect.topLeft, rect.topRight);
    drawDashedLine(rect.topRight, rect.bottomRight);
    drawDashedLine(rect.bottomRight, rect.bottomLeft);
    drawDashedLine(rect.bottomLeft, rect.topLeft);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}