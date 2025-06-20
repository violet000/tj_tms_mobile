import 'package:flutter/material.dart';

class BlankItemCard extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  const BlankItemCard({
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
        color: Colors.white, // 只保留白色底色
      ),
      child: child, // 只显示前景内容
    );
  }
}
