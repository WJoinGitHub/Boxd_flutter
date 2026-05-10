import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:umeng_push_sdk/umeng_push_sdk.dart';

import '../config/umeng_push_keys.dart';

/// 友盟统计 + 推送：**仅 Android**（国内分支调用）。
Future<void> initUmengPush() async {
  if (!Platform.isAndroid) return;

  try {
    await UmengCommonSdk.initCommon(
      UmengPushKeys.appKey,
      UmengPushKeys.appKey,
      UmengPushKeys.channel,
      UmengPushKeys.messageSecret,
    );

    if (kDebugMode) {
      await UmengPushSdk.setLogEnable(true);
    }

    await UmengPushSdk.register(UmengPushKeys.appKey, UmengPushKeys.channel);
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('Umeng push init failed: $e\n$st');
    }
  }
}
