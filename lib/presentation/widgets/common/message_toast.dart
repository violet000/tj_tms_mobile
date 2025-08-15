import 'package:flutter/material.dart';

/// 消息提示类型枚举
enum MessageType {
  success, // 成功
  error,   // 错误
  warning, // 警告
  info,    // 信息
}

/// 消息提示控件封装
/// 不同类型的消息提示，使用不同的颜色和图标，可以对其进行扩展
class MessageToast {
  static const Duration _defaultDuration = Duration(seconds: 1);
  
  /// 成功
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration? duration,
    SnackBarAction? action,
  }) {
    _showMessage(
      context,
      message: message,
      type: MessageType.success,
      duration: duration,
      action: action,
    );
  }

  /// 错误
  static void showError(
    BuildContext context, {
    required String message,
    Duration? duration,
    SnackBarAction? action,
  }) {
    _showMessage(
      context,
      message: message,
      type: MessageType.error,
      duration: duration,
      action: action,
    );
  }

  /// 警告
  static void showWarning(
    BuildContext context, {
    required String message,
    Duration? duration,
    SnackBarAction? action,
  }) {
    _showMessage(
      context,
      message: message,
      type: MessageType.warning,
      duration: duration,
      action: action,
    );
  }

  /// 信息
  static void showInfo(
    BuildContext context, {
    required String message,
    Duration? duration,
    SnackBarAction? action,
  }) {
    _showMessage(
      context,
      message: message,
      type: MessageType.info,
      duration: duration,
      action: action,
    );
  }

  /// 自定义
  static void show(
    BuildContext context, {
    required String message,
    MessageType type = MessageType.info,
    Duration? duration,
    SnackBarAction? action,
    Color? backgroundColor,
    Color? textColor,
  }) {
    _showMessage(
      context,
      message: message,
      type: type,
      duration: duration,
      action: action,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }

  /// 相关消息的一些常用方法抽离
  /// 隐藏当前显示的消息
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// 清除所有消息
  static void clear(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  /// 内部显示消息方法
  static void _showMessage(
    BuildContext context, {
    required String message,
    required MessageType type,
    Duration? duration,
    SnackBarAction? action,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final Color bgColor = backgroundColor ?? _getBackgroundColor(type);
    final Color txtColor = textColor ?? _getTextColor(type);
    final IconData icon = _getIcon(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: txtColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: txtColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        duration: duration ?? _defaultDuration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        action: action,
      ),
    );
  }

  /// 获取背景颜色
  static Color _getBackgroundColor(MessageType type) {
    switch (type) {
      case MessageType.success:
        return const Color(0xFF4CAF50);
      case MessageType.error:
        return const Color(0xFFF44336); 
      case MessageType.warning:
        return const Color(0xFFFF9800);
      case MessageType.info:
        return const Color(0xFF2196F3);
    }
  }

  /// 获取文字颜色
  static Color _getTextColor(MessageType type) {
    return Colors.white;
  }

  /// 获取图标
  static IconData _getIcon(MessageType type) {
    switch (type) {
      case MessageType.success:
        return Icons.check_circle;
      case MessageType.error:
        return Icons.error;
      case MessageType.warning:
        return Icons.warning;
      case MessageType.info:
        return Icons.info;
    }
  }
}

/// 扩展方法
extension MessageToastExtension on BuildContext {
  /// 显示成功消息
  void showSuccessMessage(String message, {Duration? duration}) {
    MessageToast.showSuccess(this, message: message, duration: duration);
  }

  /// 显示错误消息
  void showErrorMessage(String message, {Duration? duration}) {
    MessageToast.showError(this, message: message, duration: duration);
  }

  /// 显示警告消息
  void showWarningMessage(String message, {Duration? duration}) {
    MessageToast.showWarning(this, message: message, duration: duration);
  }

  /// 显示信息消息
  void showInfoMessage(String message, {Duration? duration}) {
    MessageToast.showInfo(this, message: message, duration: duration);
  }

  /// 隐藏消息
  void hideMessage() {
    MessageToast.hide(this);
  }

  /// 清除所有消息
  void clearMessages() {
    MessageToast.clear(this);
  }
} 