import 'dart:ui';

import 'package:flutter/cupertino.dart';

class MenuModel {
  final String name; // 菜单名称
  final String? imagePath; // 图片路径
  final String? iconPath; // 图标路径
  final IconData? icon; // 图标数据
  final List<MenuModel>? children; // 菜单列表
  final String? route; // 路由地址
  final Color? color; // 颜色
  final int? mode; // 模式

  MenuModel({
    required this.name,
    this.imagePath,
    this.iconPath,
    this.icon,
    this.children,
    this.route,
    this.color,
    this.mode,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      name: json['name']?.toString() ?? '',
      imagePath: json['imagePath']?.toString() ?? '',
      iconPath: json['iconPath']?.toString() ?? '',
      icon: null,
      children: json['children'] != null 
          ? (json['children'] as List<dynamic>).map<MenuModel>((dynamic x) => MenuModel.fromJson(x as Map<String, dynamic>)).toList()
          : null,
      route: json['route']?.toString() ?? '',
      color: json['color'] != null ? Color(json['color'] as int) : null,
      mode: json['mode'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'imagePath': imagePath,
      'iconPath': iconPath,
      'route': route,
      'color': color?.value,
      'mode': mode,
      'children': children?.map((x) => x.toJson()).toList(),
    };
  }
}