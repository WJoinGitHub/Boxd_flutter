import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// 将十六进制颜色（0xRRGGBB）转换为 Color，可指定透明度 [opacity] 0~1
  static Color fromHex(int hex, [double opacity = 1.0]) {
    final r = (hex >> 16) & 0xFF;
    final g = (hex >> 8) & 0xFF;
    final b = hex & 0xFF;
    return Color.fromRGBO(r, g, b, opacity);
  }

  // 🎨 颜色定义（不含 FF 前缀）
  static final Color pageBg = fromHex(0xF8F8F8);
  static final Color orange = fromHex(0xFF7622);
  static final Color black = fromHex(0x000000);
  static final Color black1 = fromHex(0x101820);
  static final Color gray1 = fromHex(0x000000, 0.2);
  static final Color gray2 = fromHex(0x000000, 0.3);
  static final Color gray3 = fromHex(0x000000, 0.54);
  static final Color gray4 = fromHex(0x7F8489);
  static final Color white = fromHex(0xFFFFFF);
  static final Color green = fromHex(0x3EC032);
  static final Color blue = fromHex(0xFFFFFF);
  static final Color gray5 = fromHex(0x979797); // 未连接状态颜色
}
