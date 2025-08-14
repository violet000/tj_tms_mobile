import 'package:flutter/material.dart';

class LineInfoProvider extends ChangeNotifier {
  // 线路信息数据
  Map<String, dynamic>? _lineInfo;
  String? _orgNo;
  String? _lineName;
  String? _carNo;
  String? _escortName;
  List<dynamic>? _items;
  String? _orgName;

  // Getters
  Map<String, dynamic>? get lineInfo => _lineInfo;
  String? get orgNo => _orgNo;
  String? get lineName => _lineName;
  String? get carNo => _carNo;
  String? get escortName => _escortName;
  List<dynamic>? get items => _items;
  String? get orgName => _orgName;

  // 设置完整的线路信息
  void setLineInfo(Map<String, dynamic> lineInfo) {
    _lineInfo = lineInfo;
    _orgNo = lineInfo['orgNo']?.toString();
    _lineName = lineInfo['lineName']?.toString();
    _carNo = lineInfo['carNo']?.toString();
    _escortName = lineInfo['escortName']?.toString();
    _items = lineInfo['items'] as List<dynamic>?;
    _orgName = lineInfo['orgName']?.toString();
    notifyListeners();
  }

  // 设置网点编号
  void setOrgNo(String orgNo) {
    _orgNo = orgNo;
    notifyListeners();
  }

  // 设置线路名称
  void setLineName(String lineName) {
    _lineName = lineName;
    notifyListeners();
  }

  // 设置车辆信息
  void setCarNo(String carNo) {
    _carNo = carNo;
    notifyListeners();
  }

  // 设置押运员信息
  void setEscortName(String escortName) {
    _escortName = escortName;
    notifyListeners();
  }

  // 设置款箱列表
  void setItems(List<dynamic> items) {
    _items = items;
    notifyListeners();
  }

  // 根据网点编号查找线路信息
  Map<String, dynamic>? findLineByOrgNo(String orgNo) {
    if (_lineInfo != null && _orgNo == orgNo) {
      return _lineInfo;
    }
    return null;
  }

  // 获取款箱数量
  int get itemsCount => _items?.length ?? 0;

  // 获取款箱数量字符串
  String get itemsCountString => '${itemsCount}个';

  // 获取网点名称
  String get getOrgName => _lineInfo?['orgName']?.toString() ?? '';

  // 清空所有数据
  void clearData() {
    _lineInfo = null;
    _orgNo = null;
    _lineName = null;
    _carNo = null;
    _escortName = null;
    _items = null;
    _orgName = null;
    notifyListeners();
  }

  // 检查是否有数据
  bool get hasData => _lineInfo != null;

  // 获取所有数据的Map
  Map<String, dynamic> getAllData() {
    return <String, dynamic>{
      'lineInfo': _lineInfo,
      'orgNo': _orgNo,
      'lineName': _lineName,
      'carNo': _carNo,
      'escortName': _escortName,
      'items': _items,
      'itemsCount': itemsCount,
    };
  }

} 