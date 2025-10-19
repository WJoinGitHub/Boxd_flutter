import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';

/// 自定义通用 AppBar
/// 支持：
/// - 左侧可选自定义返回按钮图片（默认提供）
/// - 中间标题
/// - 右侧可选按钮（图标或文字）
///
/// 用法示例：
/// ```dart
/// appBar: CustomAppBar(
///   title: "Settings",
///   rightIcon: Icons.help_outline,
///   onRightPressed: () { ... },
/// )
/// ```
class BxAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? leftIcon; // 可自定义返回按钮图片
  final VoidCallback? onLeftPressed;

  final Widget? rightWidget; // 允许自定义 widget
  final VoidCallback? onRightPressed;

  final Color backgroundColor;

  const BxAppBar({
    super.key,
    this.title,
    this.leftIcon,
    this.onLeftPressed,
    this.rightWidget,
    this.onRightPressed,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: true,

      // ✅ 左侧返回按钮
      leading: IconButton(
        onPressed: onLeftPressed ?? () => Navigator.pop(context),
        icon: leftIcon ??
            Assets.common.images.back.image(
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
      ),

      // ✅ 中间标题
      title: title != null
          ? Text(
              title!,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.black,
              ),
            )
          : null,

      // ✅ 右侧按钮（支持文字、图标或自定义 Widget）
      actions: [
        if (rightWidget != null)
          GestureDetector(
            onTap: onRightPressed,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: rightWidget!,
            ),
          )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
