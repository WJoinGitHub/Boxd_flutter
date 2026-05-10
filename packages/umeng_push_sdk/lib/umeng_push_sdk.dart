library umeng_push_sdk;

import 'dart:async';
import 'package:flutter/services.dart';

///友盟推送SDK接口
class UmengPushSdk {
  static MethodChannel _channel = const MethodChannel('u-push');
  static _Callbacks _callback = _Callbacks(_channel);

  ///日志开关
  static Future<void> setLogEnable(bool enable) async {
    return await _channel.invokeMethod(_METHOD_LOGGABLE, enable);
  }

  ///注册推送
  static Future<void> register(String iOSAppkey, String iOSChannel) async {
    return await _channel.invokeMethod(_METHOD_REGISTER, {'iOSAppkey': iOSAppkey, 'iOSChannel': iOSChannel});
  }

  ///设置deviceToken回调，仅支持Android
  static void setTokenCallback(Callback? callback) {
    _callback._deviceToken = callback;
  }

  ///设置通知消息回调（到达：receive，点击：open）
  static void setNotificationCallback(Callback? receive, Callback? open) {
    _callback._notificationReceive = receive;
    _callback._notificationOpen = open;
  }

  ///设置透传消息回调
  static void setMessageCallback(Callback? callback) {
    _callback._customMessage = callback;
  }

  ///获取deviceToken
  static Future<String?> getRegisteredId() async {
    return await _channel.invokeMethod(_METHOD_DEVICE_TOKEN);
  }

  ///设置推送是否可用，仅支持Android
  static Future<void> setPushEnable(bool enable) async {
    return await _channel.invokeMethod(_METHOD_PUSH_ENABLE, enable);
  }

  ///设置角标，Android仅支持华为、荣耀、VIVO、OPPO（需申请）
  static Future<bool?> setBadge(int number) async {
    return await _channel.invokeMethod(_METHOD_BADGE, number);
  }

  ///设置别名
  static Future<bool?> setAlias(String alias, String type) async {
    return await _channel
        .invokeMethod(_METHOD_SET_ALIAS, {'alias': alias, 'type': type});
  }

  ///增加别名
  static Future<bool?> addAlias(String alias, String type) async {
    return await _channel
        .invokeMethod(_METHOD_ADD_ALIAS, {'alias': alias, 'type': type});
  }

  ///删除别名
  static Future<bool?> removeAlias(String alias, String type) async {
    return await _channel
        .invokeMethod(_METHOD_REMOVE_ALIAS, {'alias': alias, 'type': type});
  }

  ///添加标签
  static Future<bool?> addTags(List<String> tags) async {
    return await _channel.invokeMethod(_METHOD_ADD_TAG, tags);
  }

  ///移除标签
  static Future<bool?> removeTags(List<String> tags) async {
    return await _channel.invokeMethod(_METHOD_REMOVE_TAG, tags);
  }

  ///获取已设置的标签
  static Future<List<dynamic>?> getTags() async {
    return await _channel.invokeMethod(_METHOD_GET_ALL_TAG);
  }
}

///定义回调
typedef Callback = void Function(String result);

const _METHOD_LOGGABLE = 'setLogEnable';
const _METHOD_REGISTER = 'register';
const _METHOD_DEVICE_TOKEN = 'getDeviceToken';
const _METHOD_PUSH_ENABLE = 'enable';
const _METHOD_BADGE = 'setBadge';

const _METHOD_ADD_ALIAS = 'addAlias';
const _METHOD_SET_ALIAS = 'setAlias';
const _METHOD_REMOVE_ALIAS = 'removeAlias';

const _METHOD_ADD_TAG = 'addTag';
const _METHOD_REMOVE_TAG = 'removeTag';
const _METHOD_GET_ALL_TAG = 'getTags';

class _Callbacks {
  Callback? _deviceToken;
  Callback? _notificationReceive;
  Callback? _notificationOpen;
  Callback? _customMessage;

  _Callbacks(MethodChannel channel) {
    channel.setMethodCallHandler((call) async {
      if (call.method == "onToken") {
        var token = call.arguments;
        if (_deviceToken != null) {
          _deviceToken!(token);
        }
        return;
      }
      if (call.method == "onMessage") {
        var message = call.arguments;
        if (_customMessage != null) {
          _customMessage!(message);
        }
        return;
      }
      if (call.method == "onNotificationReceive") {
        var message = call.arguments;
        if (_notificationReceive != null) {
          _notificationReceive!(message);
        }
        return;
      }
      if (call.method == "onNotificationOpen") {
        var message = call.arguments;
        if (_notificationOpen != null) {
          _notificationOpen!(message);
        }
        return;
      }
    });
  }
}
