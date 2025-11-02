import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';

/// 通用自定义 AppBar
/// 支持：
/// ✅ 自定义左侧返回按钮图片（或隐藏）
/// ✅ 自定义标题（文字居中）
/// ✅ 自定义右侧按钮（图标或文字）
/// ✅ 默认返回逻辑（maybePop）
///
/// 示例：
/// ```dart
/// appBar: BxAppBar(
///   title: "Settings",
///   rightWidget: Icon(Icons.help_outline, color: Colors.black),
///   onRightPressed: () { ... },
/// )
/// ```
class BxAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? leftIcon; // 自定义返回图标
  final VoidCallback? onLeftPressed;
  final bool showBack; // 是否显示返回按钮

  final Widget? rightWidget;
  final VoidCallback? onRightPressed;

  final Color backgroundColor;
  final Color titleColor;

  const BxAppBar({
    super.key,
    this.title,
    this.leftIcon,
    this.onLeftPressed,
    this.showBack = true,
    this.rightWidget,
    this.onRightPressed,
    this.backgroundColor = Colors.white,
    this.titleColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: true,
      leadingWidth: 47, // 保证左边留白一致
      automaticallyImplyLeading: false, // 防止系统自动添加返回箭头

      leading: showBack
          ? IconButton(
              onPressed:
                  onLeftPressed ?? () => Navigator.of(context).maybePop(),
              icon: leftIcon ??
                  Assets.common.images.back.image(
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
            )
          : null,

      title: title != null
          ? Text(
              title!,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: titleColor,
              ),
            )
          : null,

      actions: [
        if (rightWidget != null)
          InkWell(
            onTap: onRightPressed,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.only(right: 13, left: 7),
              child: Center(child: rightWidget!),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
