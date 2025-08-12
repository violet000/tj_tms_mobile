import 'package:flutter/material.dart';

class GridCell {
  final double x;
  final double y;
  final String id;
  final Color color;
  final String? shelfId; 
  final String? areaId;
  final int locationType;
  final int status; // 新增：库位状态 0-禁用 1-空闲 2-锁定 3-占用

  GridCell({
    required this.x,
    required this.y,
    required this.id,
    required this.color,
    this.shelfId,
    this.areaId,
    required this.locationType,
    required this.status,
  });
}