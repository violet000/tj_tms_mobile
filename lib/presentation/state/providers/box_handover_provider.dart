import 'package:flutter/material.dart';

class BoxHandoverProvider extends ChangeNotifier {
  // 款箱数据
  List<Map<String, dynamic>> _boxItems = [];
  List<Map<String, dynamic>> _implBoxDetails = [];
  
  // 选中的网点数据
  List<Map<String, dynamic>> _selectedPoints = [];

  // 操作类型
  String _operationType = '';

  // 选中的线路数据
  Map<String, dynamic> _selectedRoute = <String, dynamic>{};

  // 线路数据
  List<Map<String, dynamic>> _lines = [];

  // 处理状态
  bool _isProcessing = false;
  String? _errorMessage;

  // Getters
  List<Map<String, dynamic>> get boxItems => _boxItems;
  List<Map<String, dynamic>> get implBoxDetails => _implBoxDetails;
  List<Map<String, dynamic>> get selectedPoints => _selectedPoints;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;

  // 获取款箱数量
  int get boxItemsCount => _boxItems.length;
  
  // 获取实现款箱详情数量
  int get implBoxDetailsCount => _implBoxDetails.length;

  // 设置款箱数据
  void setBoxItems(List<Map<String, dynamic>> boxItems) {
    _boxItems = boxItems;
    notifyListeners();
  }

  // 设置实现款箱详情数据
  void setImplBoxDetails(List<Map<String, dynamic>> implBoxDetails) {
    _implBoxDetails = implBoxDetails;
    notifyListeners();
  }

  // 设置选中的网点数据
  void setSelectedPoints(List<Map<String, dynamic>> selectedPoints) {
    _selectedPoints = selectedPoints;
    notifyListeners();
  }

  // 设置完整的box交接数据
  void setBoxHandoverData(Map<String, dynamic> data) {
    if (data.containsKey('boxItems')) {
      _boxItems = List<Map<String, dynamic>>.from((data['boxItems'] as List?) ?? <Map<String, dynamic>>[]);
    }
    if (data.containsKey('implBoxDetails')) {
      _implBoxDetails = List<Map<String, dynamic>>.from((data['implBoxDetails'] as List?) ?? <Map<String, dynamic>>[]);
    }
    notifyListeners();
  }

  // 添加款箱数据
  void addBoxItem(Map<String, dynamic> boxItem) {
    _boxItems.add(boxItem);
    notifyListeners();
  }

  // 添加实现款箱详情数据
  void addImplBoxDetail(Map<String, dynamic> implBoxDetail) {
    _implBoxDetails.add(implBoxDetail);
    notifyListeners();
  }

  // 移除款箱数据
  void removeBoxItem(String boxCode) {
    _boxItems.removeWhere((item) => item['boxCode'] == boxCode);
    notifyListeners();
  }

  // 移除实现款箱详情数据
  void removeImplBoxDetail(String implNo) {
    _implBoxDetails.removeWhere((item) => item['implNo'] == implNo);
    notifyListeners();
  }

  // 设置操作类型
  void setOperationType(String operationType) {
    _operationType = operationType;
    notifyListeners();
  }

  // 获取操作类型
  String get operationType => _operationType;

  // 设置处理状态
  void setProcessing(bool isProcessing) {
    _isProcessing = isProcessing;
    notifyListeners();
  }

  // 设置线路数据
  void setLines(List<Map<String, dynamic>> lines) {
    _lines = lines;
    notifyListeners();
  }

  // 获取线路数据
  List<Map<String, dynamic>> get lines => _lines;

  // 设置选中的线路数据
  void setSelectedRoute(Map<String, dynamic> selectedRoute) {
    _selectedRoute = selectedRoute;
    notifyListeners();
  }

  // 获取选中的线路数据
  Map<String, dynamic> get selectedRoute => _selectedRoute;

  // 设置错误信息
  void setErrorMessage(String? errorMessage) {
    _errorMessage = errorMessage;
    notifyListeners();
  }

  // 清空所有数据
  void clearData() {
    _boxItems.clear();
    _implBoxDetails.clear();
    _selectedPoints.clear();
    _isProcessing = false;
    _errorMessage = null;
    notifyListeners();
  }

  // 检查是否有数据
  bool get hasData => _boxItems.isNotEmpty || _implBoxDetails.isNotEmpty;

  // 获取所有数据的Map
  Map<String, dynamic> getAllData() {
    return <String, dynamic>{
      'boxItems': _boxItems,
      'implBoxDetails': _implBoxDetails,
      'selectedPoints': _selectedPoints,
      'boxItemsCount': boxItemsCount,
      'implBoxDetailsCount': implBoxDetailsCount,
      'isProcessing': _isProcessing,
      'errorMessage': _errorMessage,
    };
  }

  // 根据款箱编码查找款箱
  Map<String, dynamic>? findBoxByCode(String boxCode) {
    try {
      return _boxItems.firstWhere((item) => item['boxCode'] == boxCode);
    } catch (e) {
      return null;
    }
  }

  // 根据实现编号查找实现款箱详情
  Map<String, dynamic>? findImplBoxByNo(String implNo) {
    try {
      return _implBoxDetails.firstWhere((item) => item['implNo'] == implNo);
    } catch (e) {
      return null;
    }
  }
} 