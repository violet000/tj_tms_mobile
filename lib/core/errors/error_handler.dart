import 'package:flutter/material.dart';
import 'exceptions.dart';

/// 错误处理器
class ErrorHandler {
  /// 处理异常并显示错误信息
  static void handleError(BuildContext context, dynamic error) {
    String errorMessage = '发生未知错误';
    
    if (error is Map) {
      if (error['data'] != null && error['data']['retMsg'] != null) {
        errorMessage = error['data']['retMsg'].toString();
      } else if (error['retMsg'] != null) {
        errorMessage = error['retMsg'].toString();
      }
    } else if (error is Exception) {
      errorMessage = error.toString();
    }

    // 显示错误提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Color.fromARGB(255, 236, 4, 4),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}