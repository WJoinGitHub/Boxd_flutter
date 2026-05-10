import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _apnsChannel = MethodChannel('com.qimi.heatlink/apns');

/// iOS：仅走系统 APNs（device token 交给你们服务端直连 `api.push.apple.com`）。
/// 不在此集成友盟推送 / FCM。
Future<void> initIosApnsPush() async {
  if (!Platform.isIOS) return;
  try {
    await _apnsChannel.invokeMethod<void>('register');
    if (kDebugMode) {
      for (var i = 0; i < 15; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        final t = await _apnsChannel.invokeMethod<String?>('getDeviceToken');
        if (t != null && t.isNotEmpty) {
          debugPrint('APNs device token (hex): $t');
          break;
        }
      }
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('APNs init failed: $e\n$st');
    }
  }
}

/// 当前缓存的 APNs device token（hex），未注册成功时为 `null`。可在登录后上报服务端。
Future<String?> getIosApnsDeviceToken() async {
  if (!Platform.isIOS) return null;
  try {
    return await _apnsChannel.invokeMethod<String?>('getDeviceToken');
  } catch (_) {
    return null;
  }
}
