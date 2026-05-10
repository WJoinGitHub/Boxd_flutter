// ignore_for_file: lines_longer_than_80_chars
//
// 仅 Android FCM 使用，字段来自 android/app/google-services.json。

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Android FCM 使用的 [FirebaseOptions]。
class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAQlZ1YFp2cYrK3qWzskb9hcMz7RfMPs3Y',
    appId: '1:897183983293:android:3b32cc2eda2d51a6cfb9d4',
    messagingSenderId: '897183983293',
    projectId: 'heatlink-fb3b0',
    storageBucket: 'heatlink-fb3b0.firebasestorage.app',
  );
}
