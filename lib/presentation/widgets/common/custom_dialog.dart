import 'package:flutter/material.dart';

/// 弹窗类型枚举
enum DialogType {
  confirm,    // 确认框
  alert,      // 提示框
  input,      // 输入框
  custom,     // 自定义内容
}

/// 确认框结果
enum ConfirmResult {
  confirm,    // 确认
  cancel,     // 取消
}

/// 通用弹窗控件
class CustomDialog {
  /// 显示确认框
  static Future<ConfirmResult?> showConfirm({
    required BuildContext context,
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    bool barrierDismissible = true,
    Color? confirmColor,
    Color? cancelColor,
  }) async {
    return await showDialog<ConfirmResult>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(ConfirmResult.cancel);
              },
              child: Text(
                cancelText ?? '取消',
                style: TextStyle(
                  color: cancelColor ?? Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(ConfirmResult.confirm);
              },
              child: Text(
                confirmText ?? '确认',
                style: TextStyle(
                  color: confirmColor ?? Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 显示提示框
  static Future<void> showAlert({
    required BuildContext context,
    required String title,
    required String content,
    String? buttonText,
    bool barrierDismissible = true,
    Color? buttonColor,
  }) async {
    return await showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                buttonText ?? '确定',
                style: TextStyle(
                  color: buttonColor ?? Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 显示输入框
  static Future<String?> showInput({
    required BuildContext context,
    required String title,
    String? hintText,
    String? initialValue,
    TextInputType? keyboardType,
    bool barrierDismissible = true,
    String? confirmText,
    String? cancelText,
    Color? confirmColor,
    Color? cancelColor,
    int? maxLines,
    int? maxLength,
  }) async {
    final TextEditingController controller = TextEditingController(text: initialValue);
    
    return await showDialog<String>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            keyboardType: keyboardType,
            maxLines: maxLines ?? 1,
            maxLength: maxLength,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                cancelText ?? '取消',
                style: TextStyle(
                  color: cancelColor ?? Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
              child: Text(
                confirmText ?? '确定',
                style: TextStyle(
                  color: confirmColor ?? Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 显示自定义内容弹窗
  static Future<T?> showCustom<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    Color? barrierColor,
    EdgeInsets? insetPadding,
    Clip? clipBehavior,
    ShapeBorder? shape,
    Color? backgroundColor,
    String? semanticLabel,
    EdgeInsetsGeometry? titlePadding,
    EdgeInsetsGeometry? contentPadding,
    Widget? title,
    List<Widget>? actions,
    List<BoxShadow>? boxShadow,
  }) async {
    return await showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: boxShadow ?? [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.blue.withOpacity(0.10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AlertDialog(
            shape: shape ?? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: backgroundColor,
            title: title,
            titlePadding: titlePadding,
            content: child,
            contentPadding: contentPadding,
            actions: actions,
            clipBehavior: clipBehavior ?? Clip.none,
            insetPadding: insetPadding ?? const EdgeInsets.all(16),
            semanticLabel: semanticLabel,
          ),
        );
      },
    );
  }

  /// 显示底部弹窗
  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = false,
    bool enableDrag = true,
    bool isDismissible = true,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    Color? barrierColor,
  }) async {
    return await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      isDismissible: isDismissible,
      backgroundColor: backgroundColor ?? Colors.white,
      elevation: elevation,
      shape: shape ?? const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      clipBehavior: clipBehavior ?? Clip.antiAlias,
      barrierColor: barrierColor,
      builder: (BuildContext context) {
        return child;
      },
    );
  }

  /// 显示加载弹窗
  static Future<void> showLoading({
    required BuildContext context,
    String? message,
    bool barrierDismissible = false,
  }) async {
    return await showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => barrierDismissible,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 隐藏弹窗
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}

/// 便捷扩展方法
extension CustomDialogExtension on BuildContext {
  /// 显示确认框
  Future<ConfirmResult?> showConfirmDialog({
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    bool barrierDismissible = true,
    Color? confirmColor,
    Color? cancelColor,
  }) {
    return CustomDialog.showConfirm(
      context: this,
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
      barrierDismissible: barrierDismissible,
      confirmColor: confirmColor,
      cancelColor: cancelColor,
    );
  }

  /// 显示提示框
  Future<void> showAlertDialog({
    required String title,
    required String content,
    String? buttonText,
    bool barrierDismissible = true,
    Color? buttonColor,
  }) {
    return CustomDialog.showAlert(
      context: this,
      title: title,
      content: content,
      buttonText: buttonText,
      barrierDismissible: barrierDismissible,
      buttonColor: buttonColor,
    );
  }

  /// 显示输入框
  Future<String?> showInputDialog({
    required String title,
    String? hintText,
    String? initialValue,
    TextInputType? keyboardType,
    bool barrierDismissible = true,
    String? confirmText,
    String? cancelText,
    Color? confirmColor,
    Color? cancelColor,
    int? maxLines,
    int? maxLength,
  }) {
    return CustomDialog.showInput(
      context: this,
      title: title,
      hintText: hintText,
      initialValue: initialValue,
      keyboardType: keyboardType,
      barrierDismissible: barrierDismissible,
      confirmText: confirmText,
      cancelText: cancelText,
      confirmColor: confirmColor,
      cancelColor: cancelColor,
      maxLines: maxLines,
      maxLength: maxLength,
    );
  }

  /// 显示加载弹窗
  Future<void> showLoadingDialog({
    String? message,
    bool barrierDismissible = false,
  }) {
    return CustomDialog.showLoading(
      context: this,
      message: message,
      barrierDismissible: barrierDismissible,
    );
  }

  /// 隐藏弹窗
  void hideDialog() {
    CustomDialog.hide(this);
  }
} 