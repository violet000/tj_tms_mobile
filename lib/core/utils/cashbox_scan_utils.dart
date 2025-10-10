import 'package:flutter/material.dart';

/// 款箱扫描工具类
/// 提供款箱状态更新、UHF扫描处理、取消匹配等公共功能
class CashBoxScanUtils {
  /// 更新款箱状态
  /// 
  /// [items] 款箱列表
  /// [boxCode] 款箱编码（可能是完整 boxCode、boxCode 前段、rfId、或 boxCode-rfId）
  /// [scanStatus] 扫描状态：0-已扫描，1-取消扫描
  /// [uhfScannedTags] UHF扫描标签列表
  /// [scannedBoxes] 已扫描款箱列表
  /// 
  /// 返回更新后的状态信息
  static Map<String, dynamic> updateCashBoxStatus({
    required List<Map<String, dynamic>> items,
    required String boxCode,
    required int scanStatus,
    required List<String> uhfScannedTags,
    required List<Map<String, String>> scannedBoxes,
  }) {
    try {
      // 依据传入 code（可能是完整 boxCode、boxCode 前段、rfId、或 boxCode-rfId）匹配 items
      final List<String> parts = boxCode.split('-');
      final String requestFront = parts.isNotEmpty ? parts.first : boxCode;
      final String requestBack = parts.length > 1 ? parts.last : boxCode; // 兼容直接传 RFID 的情况

      Map<String, dynamic>? matchedItem;
      for (var item in items) {
        final String itemBoxCode = item['boxCode']?.toString() ?? '';
        if (itemBoxCode.isEmpty) continue;
        final String itemFront = itemBoxCode.split('-').first;
        final String itemRfId = item['rfId']?.toString() ?? '';
        final bool matchByFull = itemBoxCode == boxCode;
        final bool matchByFront = itemFront == requestFront;
        final bool matchByRfId = itemRfId.isNotEmpty && itemRfId == requestBack;
        if (matchByFull || matchByFront || matchByRfId) {
          matchedItem = item;
          break;
        }
      }

      if (matchedItem == null) {
        throw '未找到匹配的款箱：$boxCode';
      }

      final String fullBoxCode = matchedItem['boxCode']?.toString() ?? boxCode;
      final String? matchedRfId = matchedItem['rfId']?.toString();
      matchedItem['scanStatus'] = scanStatus;

      final String combinedBoxNo = (matchedRfId == null || matchedRfId.isEmpty)
          ? fullBoxCode
          : "$fullBoxCode-$matchedRfId";

      // 更新UHF扫描标签和已扫描款箱列表
      List<String> updatedUhfScannedTags = List.from(uhfScannedTags);
      List<Map<String, String>> updatedScannedBoxes = List.from(scannedBoxes);

      if (scanStatus == 0 && !updatedUhfScannedTags.contains(fullBoxCode)) {
        updatedUhfScannedTags.insert(0, fullBoxCode);
        if (updatedUhfScannedTags.length > 100) {
          updatedUhfScannedTags.removeLast();
        }
        updatedScannedBoxes.add({"boxNo": combinedBoxNo});
      } else if (scanStatus == 1) {
        updatedUhfScannedTags.remove(fullBoxCode);
        updatedScannedBoxes.removeWhere((box) => 
            box['boxNo'] == combinedBoxNo || 
            box['boxNo'] == fullBoxCode || 
            box['boxNo'] == boxCode);
      }

      return <String, dynamic>{
        'success': true,
        'matchedItem': matchedItem,
        'uhfScannedTags': updatedUhfScannedTags,
        'scannedBoxes': updatedScannedBoxes,
        'message': '款箱状态更新成功'
      };
    } catch (e) {
      return <String, dynamic>{
        'success': false,
        'error': e.toString(),
        'message': '更新款箱状态失败: $e'
      };
    }
  }

  /// UHF扫描和手工匹配的统一处理函数
  /// 
  /// [items] 款箱列表
  /// [tag] UHF扫描到的标签
  /// [uhfScannedTags] UHF扫描标签列表
  /// [scannedBoxes] 已扫描款箱列表
  /// 
  /// 返回处理结果
  static Map<String, dynamic> handleUHFTagScanned({
    required List<Map<String, dynamic>> items,
    required String tag,
    required List<String> uhfScannedTags,
    required List<Map<String, String>> scannedBoxes,
  }) {
    try {
      // UHF 扫描优先按 RFID 匹配；若传入是 "boxCode-rfId"，取 '-' 后段
      final String rfidCandidate = tag.contains('-') ? tag.split('-').last : tag;

      final matchedItem = items.firstWhere((item) {
        final String? itemRfId = item['rfId']?.toString();
        final String? itemBoxCode = item['boxCode']?.toString();
        final bool matchByRfId = itemRfId != null && itemRfId == rfidCandidate;
        final bool matchByBoxCodeTail = itemBoxCode != null &&
            itemBoxCode.contains('-') &&
            itemBoxCode.split('-').last == rfidCandidate;
        return matchByRfId || matchByBoxCodeTail;
      }, orElse: () => <String, dynamic>{});

      if (matchedItem.isNotEmpty) {
        final result = updateCashBoxStatus(
          items: items,
          boxCode: matchedItem['boxCode'].toString(),
          scanStatus: 0,
          uhfScannedTags: uhfScannedTags,
          scannedBoxes: scannedBoxes,
        );
        
        return <String, dynamic>{
          'success': result['success'] as bool,
          'matchedItem': matchedItem,
          'uhfScannedTags': result['uhfScannedTags'] as List<String>,
          'scannedBoxes': result['scannedBoxes'] as List<Map<String, String>>,
          'message': result['success'] as bool ? 'UHF扫描匹配成功' : result['message'] as String
        };
      } else {
        return <String, dynamic>{
          'success': false,
          'message': '未找到匹配的款箱'
        };
      }
    } catch (e) {
      return <String, dynamic>{
        'success': false,
        'error': e.toString(),
        'message': 'UHF扫描处理失败: $e'
      };
    }
  }

  /// 取消匹配
  /// 
  /// [item] 要取消匹配的款箱项
  /// [items] 款箱列表
  /// [uhfScannedTags] UHF扫描标签列表
  /// [scannedBoxes] 已扫描款箱列表
  /// 
  /// 返回处理结果
  static Map<String, dynamic> unmatchCashBox({
    required Map<String, dynamic> item,
    required List<Map<String, dynamic>> items,
    required List<String> uhfScannedTags,
    required List<Map<String, String>> scannedBoxes,
  }) {
    return updateCashBoxStatus(
      items: items,
      boxCode: item['boxCode'].toString(),
      scanStatus: 1,
      uhfScannedTags: uhfScannedTags,
      scannedBoxes: scannedBoxes,
    );
  }

  /// 显示错误消息
  /// 
  /// [context] 上下文
  /// [error] 错误信息
  static void showError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  /// 显示UHF错误消息
  /// 
  /// [context] 上下文
  /// [error] 错误信息
  static void showUHFError(BuildContext context, String error) {
    showError(context, 'UHF错误: $error');
  }
}