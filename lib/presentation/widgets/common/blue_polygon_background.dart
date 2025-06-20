import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

class BluePolygonBackground extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  const BluePolygonBackground({
    Key? key,
    required this.width,
    required this.height,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FittedBox(
                fit: BoxFit.cover,
                child: Transform.rotate(
                  angle: math.pi / 2,
                  child: Image.asset(
                    'assets/images/result.png',
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
          ),
          child, // 你的前景内容
        ],
      ),
    );
  }
}
