import 'package:flutter/material.dart';
import 'package:flutter/material.dart' show NoSplash;
import 'package:flutter_svg/flutter_svg.dart';

/// 通用页面脚手架组件
/// 提供统一的渐变背景和基础布局结构
class PageScaffold extends StatelessWidget {
  /// 页面标题
  final String? title;

  /// 页面主体内容
  final Widget child;

  /// 是否显示返回按钮
  final bool showBackButton;

  /// 返回按钮点击回调
  final VoidCallback? onBackPressed;

  /// 返回按钮点击回调
  final VoidCallback? onWillPop;

  /// 自定义标题组件
  final Widget? titleWidget;

  /// 页面底部组件
  final Widget? bottomWidget;

  /// 自定义背景装饰
  final BoxDecoration? backgroundDecoration;

  /// 右侧自定义内容
  final Widget? rightWidget;

  const PageScaffold({
    Key? key,
    this.title,
    required this.child,
    this.showBackButton = false,
    this.onBackPressed,
    this.titleWidget,
    this.bottomWidget,
    this.onWillPop,
    this.backgroundDecoration,
    this.rightWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 添加键盘弹起时的处理
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: backgroundDecoration ?? _getDefaultBackgroundDecoration(),
        child: Column(
          children: [
            // 标题区域
            if (title != null || titleWidget != null) _buildHeader(),

            // 主体内容
            Expanded(
              child: child,
            ),

            // 底部组件
            if (bottomWidget != null) bottomWidget!,
          ],
        ),
      ),
    );
  }

  /// 构建标题区域
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 左侧按钮
          if (showBackButton || onWillPop != null)
            Positioned(
              left: 0,
              child: Row(
                children: [
                  if (showBackButton)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onBackPressed,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color.fromARGB(255, 60, 80, 120),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  if (onWillPop != null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onWillPop,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color.fromARGB(255, 60, 80, 120),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          // 居中的标题
          Center(
            child: titleWidget ??
                Text(
                  title ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 60, 80, 120),
                  ),
                ),
          ),
          // 右侧组件
          if (rightWidget != null)
            Positioned(
              right: 0,
              child: rightWidget!,
            ),
        ],
      ),
    );
  }

  /// 获取默认背景装饰
  BoxDecoration _getDefaultBackgroundDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFD4E1F4), // 0% 顶部
          const Color(0xFFF4F5F7).withOpacity(0.0), // 30% 渐变到透明
          const Color(0xFFF4F5F7).withOpacity(0.0), // 30%~100% 纯色
          const Color(0xFFF3F5F9), // 100%
        ],
        stops: const [
          0.0, // #D4E1F4
          0.3, // #F4F5F7 透明
          0.3, // #F3F5F9
          1.0, // #F3F5F9
        ],
      ),
    );
  }
}

/// 带标题的页面脚手架
class TitledPageScaffold extends StatelessWidget {
  /// 页面标题
  final String title;

  /// 页面主体内容
  final Widget child;

  /// 是否显示返回按钮
  final bool showBackButton;

  /// 返回按钮点击回调
  final VoidCallback? onBackPressed;

  /// 返回按钮点击回调
  final VoidCallback? onWillPop;

  /// 页面底部组件
  final Widget? bottomWidget;

  /// 自定义背景装饰
  final BoxDecoration? backgroundDecoration;

  const TitledPageScaffold({
    Key? key,
    required this.title,
    required this.child,
    this.showBackButton = false,
    this.onBackPressed,
    this.bottomWidget,
    this.onWillPop,
    this.backgroundDecoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: title,
      child: child,
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
      bottomWidget: bottomWidget,
      onWillPop: onWillPop,
      backgroundDecoration: backgroundDecoration,
    );
  }
}
