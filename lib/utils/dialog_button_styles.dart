import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';

/// 屏幕居中 [AlertDialog] 底部按钮样式（左侧灰 / 右侧主题橙）
abstract class DialogButtonStyles {
  /// 左侧取消：灰色（与删除账号等弹窗取消常见样式一致），字号 16
  static ButtonStyle get cancel {
    return TextButton.styleFrom(
      foregroundColor: AppColors.gray5,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    );
  }

  /// 右侧确定 / 保存 / 确认 / 删除 / 解绑 等：主题橙色，字号 16
  static ButtonStyle get primaryAction {
    return TextButton.styleFrom(
      foregroundColor: AppColors.orange,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    );
  }
}
