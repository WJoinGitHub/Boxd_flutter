import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'push_token_report.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
}

/// 非中国区、**仅 Android**：Firebase + FCM。
Future<void> initFcmPush() async {
  if (!Platform.isAndroid) return;

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (kDebugMode) {
      debugPrint('FCM permission: ${settings.authorizationStatus}');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage m) {
      if (kDebugMode) {
        debugPrint('FCM foreground: ${m.messageId} ${m.notification?.title}');
      }
    });

    String? token;
    String? tokenError;
    try {
      token = await messaging
          .getToken()
          .timeout(const Duration(seconds: 12));
    } on TimeoutException {
      tokenError =
          'getToken 超时（12s）。常见于未安装/未启用 Google Play 服务或网络不可用。';
      if (kDebugMode) {
        debugPrint('FCM getToken timed out (common without Google Play services)');
      }
    } catch (e, st) {
      tokenError = e.toString();
      if (kDebugMode) {
        debugPrint('FCM getToken failed: $e\n$st');
      }
    }

    if (token != null && token.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('FCM token: $token');
      }
    } else if (kDebugMode) {
      final reason = tokenError ??
          'token 为空（通知权限: ${settings.authorizationStatus.name}）';
      debugPrint('FCM getToken: $reason');
    }

    unawaited(PushTokenReport.syncIfLoggedIn());

    FirebaseMessaging.instance.onTokenRefresh.listen((_) {
      unawaited(PushTokenReport.syncIfLoggedIn());
    });
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('FCM init failed: $e\n$st');
    }
  }
}
