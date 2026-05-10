import 'dart:ui' as ui;

/// 是否使用**友盟推送**（仅 **Android** 国内通道）。
///
/// 依据系统 [Locale.countryCode]：`CN` 视为中国大陆，走友盟。
/// 港（HK）、澳（MO）、台（TW）为独立区域码，默认走 **FCM**；若要改为友盟，在此调整判断即可。
bool useUmengPushForCurrentDeviceLocale() {
  for (final ui.Locale l in ui.PlatformDispatcher.instance.locales) {
    final c = l.countryCode?.toUpperCase();
    if (c == 'CN') return true;
  }
  return false;
}
