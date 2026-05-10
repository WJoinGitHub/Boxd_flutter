import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

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

    final token = await messaging.getToken();
    if (kDebugMode) {
      debugPrint('FCM token: $token');
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('FCM init failed: $e\n$st');
    }
  }
}
