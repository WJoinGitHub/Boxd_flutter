import 'dart:io';
import 'dart:ui' as ui;

import 'android_play_services.dart';

/// 是否使用**友盟推送**（仅 **Android** 国内通道）。
///
/// 依据**首选**系统 [Locale.countryCode]：仅当首位为 `CN`（中国大陆）时走友盟。
/// 语言列表里后续项含 CN 不算；港（HK）、澳（MO）、台（TW）默认走 **FCM**。
bool useUmengPushForCurrentDeviceLocale() {
  final locales = ui.PlatformDispatcher.instance.locales;
  if (locales.isEmpty) return false;
  return locales.first.countryCode?.toUpperCase() == 'CN';
}

/// Android 实际走友盟：大陆 **或** 未安装 Google Play 服务（无 GMS 时 FCM 无法拿 token）。
Future<bool> shouldUseUmengPushOnAndroid() async {
  if (!Platform.isAndroid) return false;
  if (useUmengPushForCurrentDeviceLocale()) return true;
  return !(await AndroidPlayServices.isAvailable);
}
