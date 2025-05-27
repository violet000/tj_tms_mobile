import 'package:flutter/material.dart';
import 'exceptions.dart';

/// 错误处理器
class ErrorHandler {
  /// 处理异常并显示错误信息
  static void handleError(BuildContext context, dynamic error) {
    String errorMessage;
    
    if (error is AppException) {
      errorMessage = error.message;
    } else if (error is Exception) {
      errorMessage = error.toString();
    } else {
      errorMessage = '发生未知错误';
    }

    // 显示错误提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 处理网络错误
  static void handleNetworkError(BuildContext context, dynamic error) {
    String message = '网络连接失败，请检查网络设置';
    if (error is NetworkException) {
      message = error.message;
    }
    handleError(context, NetworkException(message: message));
  }

  /// 处理服务器错误
  static void handleServerError(BuildContext context, dynamic error) {
    String message = '服务器错误，请稍后重试';
    if (error is ServerException) {
      message = error.message;
    }
    handleError(context, ServerException(message: message));
  }

  /// 处理认证错误
  static void handleAuthError(BuildContext context, dynamic error) {
    String message = '认证失败，请重新登录';
    if (error is AuthException) {
      message = error.message;
    }
    handleError(context, AuthException(message: message));
  }

  /// 处理业务逻辑错误
  static void handleBusinessError(BuildContext context, dynamic error) {
    String message = '操作失败，请重试';
    if (error is BusinessException) {
      message = error.message;
    }
    handleError(context, BusinessException(message: message));
  }

  /// 处理缓存错误
  static void handleCacheError(BuildContext context, dynamic error) {
    String message = '数据读取失败，请重试';
    if (error is CacheException) {
      message = error.message;
    }
    handleError(context, CacheException(message: message));
  }
} 