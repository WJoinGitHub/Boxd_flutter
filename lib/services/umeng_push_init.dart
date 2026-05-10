import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:umeng_push_sdk/umeng_push_sdk.dart';

import '../config/umeng_push_keys.dart';
import 'push_token_report.dart';

/// 友盟统计 + 推送：**仅 Android**（国内分支调用）。
///
/// [UmengCommonSdk.initCommon] 在部分机型上会长时间不返回，导致外层
/// [initPushByRegion] 一直卡住；对关键 `await` 加 [Future.timeout] 以便
/// 尽快进入 [PushTokenReport.syncIfLoggedIn]，实际 registrationId 仍依赖
/// 友盟异步回调 + [PushTokenReport] 的重试。
Future<void> initUmengPush() async {
  if (!Platform.isAndroid) return;

  try {
    await UmengCommonSdk.initCommon(
      UmengPushKeys.appKey,
      UmengPushKeys.appKey,
      UmengPushKeys.channel,
      UmengPushKeys.messageSecret,
    ).timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        if (kDebugMode) {
          debugPrint(
            'Umeng initCommon: timed out after 12s (native may still finish)',
          );
        }
      },
    );

    if (kDebugMode) {
      await UmengPushSdk.setLogEnable(true).timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );
    }

    UmengPushSdk.setTokenCallback((_) {
      unawaited(PushTokenReport.syncIfLoggedIn());
    });

    await UmengPushSdk.register(
      UmengPushKeys.appKey,
      UmengPushKeys.channel,
    ).timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        if (kDebugMode) {
          debugPrint(
            'Umeng register: timed out after 8s (native may still complete)',
          );
        }
      },
    );

    unawaited(PushTokenReport.syncIfLoggedIn());
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('Umeng push init failed: $e\n$st');
    }
  }
}
