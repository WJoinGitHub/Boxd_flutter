import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:umeng_push_sdk/umeng_push_sdk.dart';

import 'api_client.dart';
import 'ios_apns_push.dart';
import 'push_region.dart';

/// 将当前通道的推送 token 上报 [ApiClient.registerPushToken]（需 [ApiClient.hasAccessToken]）。
///
/// 日志前缀 `[PUSH-TOKEN]`，在 `flutter run` / logcat 里与 `I/flutter` 一并可见。
class PushTokenReport {
  PushTokenReport._();

  static String? _lastSentKey;
  /// 合并并发 [syncIfLoggedIn]（登录、首帧、友盟回调、重试定时器同时触发时只跑一轮）。
  static Future<void>? _inFlight;

  /// 友盟 registrationId 常晚于 `register` 返回才可用，多次延迟重试。
  static int _upushEmptyRetryIndex = 0;
  static const List<int> _upushRetryDelaysSec = [2, 5, 10, 20, 30];

  static void _log(String message) => debugPrint('[PUSH-TOKEN] $message');

  static void clearCache() {
    _lastSentKey = null;
    _upushEmptyRetryIndex = 0;
    // 不取消进行中的上报；完成后 [whenComplete] 会清空 [_inFlight]。
  }

  static void _scheduleUpushRetryIfNeeded() {
    if (_upushEmptyRetryIndex >= _upushRetryDelaysSec.length) return;
    final sec = _upushRetryDelaysSec[_upushEmptyRetryIndex];
    _upushEmptyRetryIndex += 1;
    _log('schedule upush retry in ${sec}s (attempt $_upushEmptyRetryIndex/${_upushRetryDelaysSec.length})');
    Future<void>.delayed(Duration(seconds: sec), syncIfLoggedIn);
  }

  /// 多处可能同时触发；共享同一 [Future]，避免对 `/push/token` 并发重复 POST。
  static Future<void> syncIfLoggedIn() {
    if (_inFlight != null) return _inFlight!;
    _inFlight = _syncIfLoggedInBody().whenComplete(() => _inFlight = null);
    return _inFlight!;
  }

  static Future<void> _syncIfLoggedInBody() async {
    if (!ApiClient.hasAccessToken) {
      _log('skip: no access token');
      return;
    }
    try {
      final resolved = await _resolveLocalToken();
      if (resolved == null) {
        _log('skip: unsupported platform');
        return;
      }
      final (:provider, :token) = resolved;
      if (token == null || token.isEmpty) {
        _log('skip: empty token (push_type=$provider)');
        if (Platform.isAndroid && provider == 'upush') {
          _scheduleUpushRetryIfNeeded();
        }
        return;
      }

      const env = kDebugMode ? 'test' : 'production';
      final key = '$provider:$env:$token';
      if (_lastSentKey == key) {
        _log('skip: already sent same push_type/env/token');
        _upushEmptyRetryIndex = 0;
        return;
      }

      _log(
        'POST /push/token push_type=$provider push_env=$env token_len=${token.length}',
      );
      final result = await ApiClient.registerPushToken(
        pushType: provider,
        pushEnv: env,
        pushToken: token,
      );
      if (result['code'] == 200) {
        _lastSentKey = key;
        _upushEmptyRetryIndex = 0;
        _log('server OK code=200');
      } else {
        _log('rejected code=${result['code']} message=${result['message']}');
      }
    } on ApiException catch (e) {
      _log('failed: ${e.message}');
    } catch (e, st) {
      _log('error: $e\n$st');
    }
  }

  static Future<({String provider, String? token})?> _resolveLocalToken() async {
    if (Platform.isIOS) {
      final t = await getIosApnsDeviceToken();
      return (provider: 'apns', token: t);
    }
    if (!Platform.isAndroid) return null;

    if (useUmengPushForCurrentDeviceLocale()) {
      final t = await UmengPushSdk.getRegisteredId();
      return (provider: 'upush', token: t);
    }

    try {
      final t = await FirebaseMessaging.instance.getToken();
      return (provider: 'fcm', token: t);
    } catch (_) {
      return (provider: 'fcm', token: null);
    }
  }
}
