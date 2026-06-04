import 'dart:io';

import 'package:flutter/foundation.dart';

import 'fcm_push_init.dart';
import 'ios_apns_push.dart';
import 'push_region.dart';
import 'umeng_push_init.dart';

/// - **Android**：大陆或无 GMS → 友盟；否则 FCM。
/// - **iOS**：仅 APNs（原生注册 + device token），不使用友盟 / FCM。
Future<void> initPushByRegion() async {
  if (Platform.isIOS) {
    await initIosApnsPush();
    return;
  }
  if (!Platform.isAndroid) return;

  if (await shouldUseUmengPushOnAndroid()) {
    if (kDebugMode) {
      debugPrint(
        'initPushByRegion: upush (primary locale CN or Google Play services missing)',
      );
    }
    await initUmengPush();
  } else {
    if (kDebugMode) {
      debugPrint('initPushByRegion: fcm');
    }
    await initFcmPush();
  }
}
