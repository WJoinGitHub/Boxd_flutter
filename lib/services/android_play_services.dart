import 'dart:io';

import 'package:flutter/services.dart';

/// Android 是否安装 Google Play 服务（FCM 依赖 `com.google.android.gms`）。
class AndroidPlayServices {
  AndroidPlayServices._();

  static const MethodChannel _channel =
      MethodChannel('com.qimi.heatlink/platform');

  static bool? _cachedAvailable;

  static Future<bool> get isAvailable async {
    if (!Platform.isAndroid) return false;
    if (_cachedAvailable != null) return _cachedAvailable!;
    try {
      final v = await _channel.invokeMethod<bool>('hasGooglePlayServices');
      _cachedAvailable = v == true;
    } catch (_) {
      _cachedAvailable = false;
    }
    return _cachedAvailable!;
  }
}
