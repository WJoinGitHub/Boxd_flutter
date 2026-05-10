import 'dart:io';

import 'fcm_push_init.dart';
import 'ios_apns_push.dart';
import 'push_region.dart';
import 'umeng_push_init.dart';

/// - **Android**：中国大陆友盟推送，其他地区 FCM。
/// - **iOS**：仅 APNs（原生注册 + device token），不使用友盟 / FCM。
Future<void> initPushByRegion() async {
  if (Platform.isIOS) {
    await initIosApnsPush();
    return;
  }
  if (!Platform.isAndroid) return;

  if (useUmengPushForCurrentDeviceLocale()) {
    await initUmengPush();
  } else {
    await initFcmPush();
  }
}
