import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'user_service.dart';
import '../main.dart';
import '../pages/login/register_email_page.dart';

enum CodeType {
  register,
  login,
  resetPassword;

  String get value {
    switch (this) {
      case CodeType.register:
        return 'register';
      case CodeType.login:
        return 'login';
      case CodeType.resetPassword:
        return 'reset_password';
    }
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  static const String baseUrl = 'https://api.qimitech.com';
  static const String basePath = '/api/v1';
  static const String _appIdIOS = '8ee4a01508aaf380d306c750413f530a';
  static const String _appIdAndroid = 'aceab110a598dc6bff24805d23aab5df';
  static const String _appSecretIOS =
      'd66530267153704b2e86d89204089e6f0aed041b82f2a9729e4779b2cf51cd22';
  static const String _appSecretAndroid =
      '091eee43543d14bfed76282e4a1e3a90cddbef91fb8f6baabe4b61347e8595de';
  static const String userAgent = 'HeatLink/1.0.0';

  static String? _token;

  /// 是否已设置访问令牌（含游客会话），用于推送 token 等需登录态的请求。
  static bool get hasAccessToken => _token != null && _token!.trim().isNotEmpty;

  static String get appId => Platform.isIOS ? _appIdIOS : _appIdAndroid;
  static String get appSecret =>
      Platform.isIOS ? _appSecretIOS : _appSecretAndroid;

  static void setToken(String token) => _token = token;
  static void clearToken() => _token = null;

  /// 每次请求唯一随机串，参与签名并作为 X-Nonce 发送（防重放）
  static String _generateNonce() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// 递归按键名字典序升序排列，再 JSON 编码（与平台签名规则一致）
  static dynamic _deepSortJsonKeys(dynamic value) {
    if (value is Map) {
      final map = Map<String, dynamic>.from(
        value.map((k, v) => MapEntry(k.toString(), v)),
      );
      final keys = map.keys.toList()..sort();
      return <String, dynamic>{
        for (final k in keys) k: _deepSortJsonKeys(map[k]),
      };
    }
    if (value is List) {
      return value.map(_deepSortJsonKeys).toList();
    }
    return value;
  }

  static String _bodyStringForSignature(Map<String, dynamic>? body) {
    if (body == null) return '';
    return jsonEncode(_deepSortJsonKeys(body));
  }

  static const Set<String> _ignore401Paths = {
    '/auth/login',
    '/auth/register',
    '/auth/send-code',
    '/auth/verify-code',
    '/auth/reset-password',
    '/auth/refresh-token',
  };

  /// 生成 HMAC-SHA256 签名（十六进制小写）
  ///
  /// 无 Token 无 Nonce: method + path + timestamp + body + userAgent
  /// 无 Token 有 Nonce: method + path + timestamp + body + userAgent + nonce
  /// 有 Token 无 Nonce: method + path + timestamp + token + body + userAgent
  /// 有 Token 有 Nonce: method + path + timestamp + token + body + userAgent + nonce
  static String _generateSignature(
    String method,
    String path,
    String timestamp,
    String body, {
    bool skipAuth = false,
    String? nonce,
  }) {
    final token = skipAuth ? '' : (_token?.replaceFirst('Bearer ', '') ?? '');
    final buf = StringBuffer()
      ..write(method)
      ..write(path)
      ..write(timestamp);
    if (token.isNotEmpty) {
      buf.write(token);
    }
    buf.write(body);
    buf.write(userAgent);
    if (nonce != null && nonce.isNotEmpty) {
      buf.write(nonce);
    }
    final signString = buf.toString();
    final key = utf8.encode(appSecret);
    final bytes = utf8.encode(signString);
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString();
  }

  /// 统一请求方法
  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    bool skipAuth = false,
  }) async {
    final uri = queryParams != null
        ? Uri.parse('$baseUrl$basePath$path').replace(
            queryParameters:
                queryParams.map((k, v) => MapEntry(k, v.toString())),
          )
        : Uri.parse('$baseUrl$basePath$path');

    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final bodyStr = _bodyStringForSignature(body);
    final nonce = _generateNonce();
    final signature = _generateSignature(
      method,
      basePath + path,
      timestamp,
      bodyStr,
      skipAuth: skipAuth,
      nonce: nonce,
    );

    final headers = {
      'Content-Type': 'application/json',
      'X-App-ID': appId,
      'X-Timestamp': timestamp,
      'X-Nonce': nonce,
      'X-Signature': signature,
      'User-Agent': userAgent,
      if (!skipAuth && _token != null) 'Authorization': 'Bearer $_token',
    };

    print('Request $method: $uri');
    print('Headers: $headers');
    if (body != null) print('Params: $bodyStr');
    if (queryParams != null) print('Query: $queryParams');

    final response = await (() {
      switch (method) {
        case 'GET':
          return http.get(uri, headers: headers);
        case 'POST':
          return http.post(uri, headers: headers, body: bodyStr);
        case 'PUT':
          return http.put(uri, headers: headers, body: bodyStr);
        case 'DELETE':
          return http.delete(uri, headers: headers);
        default:
          throw Exception('Unsupported method: $method');
      }
    })();

    print('Response: $uri');
    _debugLogResponseBody(response.body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      // 清除token
      _token = null;
      clearToken();

      // 如果不在忽略列表中，清除登录状态（避免登录/注册接口触发登出）
      if (!_ignore401Paths.contains(path)) {
        print('[API] 收到401状态码，清除登录状态: $path');
        try {
          await UserService().logout();
        } catch (e) {
          print('[API] 清除登录状态失败: $e');
        }

        // 使用全局 navigatorKey 跳转到注册页面
        if (navigatorKey.currentContext != null) {
          final context = navigatorKey.currentContext!;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const RegisterEmailPage()),
            (route) => false, // 清除所有路由
          );
        }
      }

      throw ApiException(_extractMessage(response.body));
    } else {
      throw ApiException(_extractMessage(response.body));
    }
  }

  /// Logcat / 部分终端对单行长度有限制，长 JSON 分片打印；业务解析仍使用完整 body。
  static void _debugLogResponseBody(String body) {
    const chunk = 1000;
    final len = body.length;
    if (len <= chunk) {
      print('Data: $body');
      return;
    }
    print('Data: (length=$len, ${(len + chunk - 1) ~/ chunk} chunks)');
    for (var i = 0; i < len; i += chunk) {
      final end = min(i + chunk, len);
      print('Data[$i-$end]: ${body.substring(i, end)}');
    }
  }

  static Future<Map<String, dynamic>> post(
          String path, Map<String, dynamic> body) =>
      _request('POST', path, body: body);

  /// 发送 multipart/form-data 请求
  static Future<Map<String, dynamic>> postMultipart(
    String path,
    Map<String, String> fields, {
    Map<String, http.MultipartFile>? files,
  }) async {
    final uri = Uri.parse('$baseUrl$basePath$path');
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

    // 构建 multipart request
    final request = http.MultipartRequest('POST', uri);

    // 添加字段
    request.fields.addAll(fields);

    // 添加文件（如果有）
    if (files != null) {
      request.files.addAll(files.values);
    }

    // 对于 multipart 请求，签名使用 fields 的 JSON（键字典序，与文档一致）
    final sortedFields = Map.fromEntries(
      fields.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final bodyStr = _bodyStringForSignature(sortedFields);
    final nonce = _generateNonce();
    final signature = _generateSignature(
      'POST',
      basePath + path,
      timestamp,
      bodyStr,
      nonce: nonce,
    );

    // 添加 headers
    final headers = {
      'X-App-ID': appId,
      'X-Timestamp': timestamp,
      'X-Nonce': nonce,
      'X-Signature': signature,
      'User-Agent': userAgent,
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    request.headers.addAll(headers);

    print('Request POST (multipart): $uri');
    print('Headers: ${request.headers}');
    print('Fields: ${request.fields}');
    print('[API] Multipart body for signature: $bodyStr');
    if (files != null) print('Files: ${files.keys}');

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('Response: $uri');
    print('Status: ${response.statusCode}');
    _debugLogResponseBody(response.body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      _token = null;
      clearToken();

      if (!_ignore401Paths.contains(path)) {
        print('[API] 收到401状态码，清除登录状态: $path');
        try {
          await UserService().logout();
        } catch (e) {
          print('[API] 清除登录状态失败: $e');
        }

        // 使用全局 navigatorKey 跳转到注册页面
        if (navigatorKey.currentContext != null) {
          final context = navigatorKey.currentContext!;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const RegisterEmailPage()),
            (route) => false, // 清除所有路由
          );
        }
      }

      throw ApiException(_extractMessage(response.body));
    } else {
      throw ApiException(_extractMessage(response.body));
    }
  }

  static String _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
        final data = decoded['data'];
        if (data is String && data.trim().isNotEmpty) {
          return data;
        }
      }
    } catch (_) {
      // ignore parse failure and fallback to raw body
    }
    final raw = body.trim();
    return raw.isEmpty ? 'Request failed' : raw;
  }

  static String extractErrorMessage(Object e) {
    if (e is ApiException) return e.message;
    final text = e.toString().trim();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length).trim();
    }
    return text;
  }

  static Future<Map<String, dynamic>> get(String path,
          {Map<String, dynamic>? queryParams}) =>
      _request('GET', path, queryParams: queryParams);

  static Future<Map<String, dynamic>> put(
          String path, Map<String, dynamic> body) =>
      _request('PUT', path, body: body);

  static Future<Map<String, dynamic>> delete(String path) =>
      _request('DELETE', path);

  // ==================== 用户认证 ====================
  static Future<Map<String, dynamic>> sendCode(String email, CodeType type) =>
      post('/auth/send-code', {'email': email, 'type': type.value});

  /// 发送重置密码验证码（专门的重置密码接口）
  static Future<Map<String, dynamic>> sendResetPasswordCode(String email) =>
      post('/auth/send-code',
          {'email': email, 'type': CodeType.resetPassword.value});

  static Future<Map<String, dynamic>> verifyCode(
          String email, String code, CodeType type) =>
      post('/auth/verify-code',
          {'email': email, 'code': code, 'type': type.value});

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String nickname,
    required String verifyToken,
    String? language,
    String? timezone,
  }) =>
      post('/auth/register', {
        'email': email,
        'password': password,
        'nickname': nickname,
        'verify_token': verifyToken,
        if (language != null) 'language': language,
        if (timezone != null) 'timezone': timezone,
      });

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final result = await post('/auth/login', {
      'email': email,
      'password': password,
    });
    if (result['code'] == 200 &&
        result['data']?['tokens']?['access_token'] != null) {
      setToken(result['data']['tokens']['access_token']);
    }
    return result;
  }

  /// 获取设备信息
  /// device_id 使用设备的 UDID（唯一标识符）
  /// iOS: identifierForVendor (IDFV) - 设备唯一标识符
  /// Android: id (Android ID) - 设备唯一标识符
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();

      String platform = Platform.isIOS ? 'iOS' : 'Android';
      String deviceModel = 'Unknown';
      String deviceName = 'Unknown';
      String deviceId = 'Unknown';

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.model;
        deviceName = iosInfo.name;
        // iOS: 使用 identifierForVendor (IDFV) 作为设备 UDID
        // 注意：苹果已禁止访问真正的 UDID，IDFV 是当前可用的设备唯一标识符
        deviceId = iosInfo.identifierForVendor ?? 'Unknown';
      } else {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = androidInfo.model;
        deviceName = androidInfo.device;
        // Android: 使用 id (Android ID) 作为设备 UDID
        deviceId = androidInfo.id;
      }

      return {
        'app_version': packageInfo.version,
        'device_id': deviceId,
        'device_model': deviceModel,
        'device_name': deviceName,
        'platform': platform,
      };
    } catch (e) {
      print('[API] 获取设备信息失败: $e');
      return {};
    }
  }

  /// 游客登录
  static Future<Map<String, dynamic>> guestLogin() async {
    final deviceInfo = await _getDeviceInfo();
    final result = await post('/auth/guest-login', deviceInfo);
    if (result['code'] == 200 &&
        result['data']?['tokens']?['access_token'] != null) {
      setToken(result['data']['tokens']['access_token']);
    }
    return result;
  }

  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final result = await _request('POST', '/auth/refresh',
        body: {'refresh_token': refreshToken}, skipAuth: true);
    if (result['code'] == 200 &&
        result['data']?['tokens']?['access_token'] != null) {
      setToken(result['data']['tokens']['access_token']);
    }
    return result;
  }

  static Future<Map<String, dynamic>> resetPassword(
          String email, String verifyToken, String password) =>
      post('/auth/reset-password', {
        'email': email,
        'verify_token': verifyToken,
        'new_password': password,
      });

  static Future<Map<String, dynamic>> logout() async {
    final result = await post('/auth/logout', {});
    clearToken();
    return result;
  }

  // ==================== 用户管理 ====================
  static Future<Map<String, dynamic>> getUserProfile() => get('/user/profile');

  static Future<Map<String, dynamic>> updateUserProfile(
          {String? email, String? phone, String? nickname}) =>
      put('/user/profile', {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (nickname != null) 'nickname': nickname,
      });

  static Future<Map<String, dynamic>> changePassword(
          String oldPassword, String newPassword) =>
      put('/user/password',
          {'old_password': oldPassword, 'new_password': newPassword});

  static Future<Map<String, dynamic>> deleteAccount() async {
    final result = await delete('/user/account');
    clearToken();
    return result;
  }

  /// 上报推送 token（需已登录），与 Swagger **POST /api/v1/push/token** 一致。
  ///
  /// Body：`app_version`, `device_id`, `push_env`, `push_type`, `token`。
  ///
  /// - [pushType]：`upush`（友盟）| `fcm` | `apns`
  /// - [pushEnv]：`test`（Debug）| `production`（Release）
  /// - [pushToken]：请求 JSON 字段名为 `token`（FCM / 友盟 registrationId / APNs hex）
  static Future<Map<String, dynamic>> registerPushToken({
    required String pushType,
    required String pushEnv,
    required String pushToken,
  }) async {
    final info = await _getDeviceInfo();
    final appVersion = info['app_version']?.toString() ?? 'unknown';
    final deviceId = info['device_id']?.toString() ?? 'unknown';
    return post('/push/token', {
      'app_version': appVersion,
      'device_id': deviceId,
      'push_env': pushEnv,
      'push_type': pushType,
      'token': pushToken,
    });
  }

  // ==================== 设备管理 ====================
  static Future<Map<String, dynamic>> bindDevice(
    String deviceUuid, {
    String? deviceName,
  }) =>
      post('/devices/bind', {
        'device_uuid': deviceUuid,
        if (deviceName != null) 'device_name': deviceName,
      });

  static Future<Map<String, dynamic>> getDevices(
          {int page = 1, int pageSize = 20}) =>
      get('/devices', queryParams: {'page': page, 'page_size': pageSize});

  static Future<Map<String, dynamic>> getDeviceDetail(String deviceUuid) =>
      get('/devices/$deviceUuid');

  static Future<Map<String, dynamic>> updateDevice(
          String deviceUuid, String deviceName) =>
      put('/devices/$deviceUuid', {'device_name': deviceName});

  static Future<Map<String, dynamic>> unbindDevice(String deviceUuid) =>
      delete('/devices/$deviceUuid');

  // ==================== 产品 ====================
  /// 启用中的产品列表（含首页图 / 连接图 URL，按 product_name 匹配蓝牙名）
  static Future<Map<String, dynamic>> getProducts() => get('/products');


  // ==================== 反馈 ====================
  /// 当前用户品牌信息（反馈目标品牌名 / 邮箱 / 社媒）
  static Future<Map<String, dynamic>> getFeedbackBrand() =>
      get('/feedback/brand');

  static Future<Map<String, dynamic>> getFeedbackCategories({
    int page = 1,
    int limit = 20,
    String isEnabled = 'all',
  }) =>
      get('/feedback/categories', queryParams: {
        'page': page,
        'limit': limit,
        'is_enabled': isEnabled,
      });

  static Future<Map<String, dynamic>> submitFeedback({
    required String category,
    required String content,
    required String appVersion,
    required String deviceInfo,
    required String systemVersion,
    String? attachmentUrl,
  }) =>
      post('/feedback', {
        'category': category,
        'title': 'feedback',
        'content': content,
        'app_version': appVersion,
        'device_info': deviceInfo,
        'system_version': systemVersion,
        if (attachmentUrl != null && attachmentUrl.isNotEmpty)
          'attachment_url': attachmentUrl,
      });

  // ==================== 定时任务 ====================
  static Future<Map<String, dynamic>> createTimer({
    required String deviceUuid,
    required String timerName,
    required String timerType,
    required String executeTime,
    String? executeDate,
    List<int>? weekdays,
    required String action,
    Map<String, dynamic>? actionParams,
    bool isEnabled = true,
  }) =>
      post('/timers', {
        'device_uuid': deviceUuid,
        'timer_name': timerName,
        'timer_type': timerType,
        'execute_time': executeTime,
        if (executeDate != null) 'execute_date': executeDate,
        if (weekdays != null) 'weekdays': weekdays,
        'action': action,
        if (actionParams != null) 'action_params': actionParams,
        'is_enabled': isEnabled,
      });

  static Future<Map<String, dynamic>> getTimers(
          {String? deviceUuid, int page = 1, int pageSize = 20}) =>
      get('/timers', queryParams: {
        if (deviceUuid != null) 'device_uuid': deviceUuid,
        'page': page,
        'page_size': pageSize,
      });

  static Future<Map<String, dynamic>> updateTimer(
          int timerId, Map<String, dynamic> data) =>
      put('/timers/$timerId', data);

  static Future<Map<String, dynamic>> deleteTimer(int timerId) =>
      delete('/timers/$timerId');

  static Future<Map<String, dynamic>> toggleTimer(
          int timerId, bool isEnabled) =>
      put('/timers/$timerId/status', {'is_enabled': isEnabled});

  // ==================== 推送通知 ====================
  static Future<Map<String, dynamic>> getNotifications({
    String? type,
    bool? isRead,
    int page = 1,
    int pageSize = 20,
  }) =>
      get('/notifications', queryParams: {
        if (type != null) 'type': type,
        if (isRead != null) 'is_read': isRead,
        'page': page,
        'page_size': pageSize,
      });

  /// GET `/notifications/unread-count` — 未读通知数量（用于角标）
  static Future<Map<String, dynamic>> getNotificationsUnreadCount() =>
      get('/notifications/unread-count');

  /// GET `/notifications/popup` — 当前未读运营弹窗（首页首次进入可展示）
  static Future<Map<String, dynamic>> getNotificationPopup() =>
      get('/notifications/popup');

  static Future<Map<String, dynamic>> markNotificationRead(
          int notificationId) =>
      put('/notifications/$notificationId/read', {});

  static Future<Map<String, dynamic>> batchMarkRead(
          List<int> notificationIds) =>
      put('/notifications/batch-read', {'notification_ids': notificationIds});

  /// PUT `/notifications/read-all` — 全部标记已读（无请求体）
  static Future<Map<String, dynamic>> markAllNotificationsRead() =>
      put('/notifications/read-all', {});

  /// DELETE `/notifications/{id}` — 删除单条通知
  static Future<Map<String, dynamic>> deleteNotification(int notificationId) =>
      delete('/notifications/$notificationId');

  // ==================== 系统接口 ====================
  static Future<Map<String, dynamic>> getSystemConfig() =>
      get('/system/config');

  static Future<Map<String, dynamic>> getAppConfig() =>
      get('/system/app-config');

  static Future<Map<String, dynamic>> getFeatureFlags() =>
      get('/system/feature-flags');

  static Future<Map<String, dynamic>> checkVersion(
          String platform, int versionCode) =>
      get('/system/version/check',
          queryParams: {'platform': platform, 'version_code': versionCode});

  static Future<Map<String, dynamic>> getPolicies() => get('/system/policies');

  static Future<Map<String, dynamic>> getPolicyContent(String type) =>
      get('/system/policy/$type');
}
