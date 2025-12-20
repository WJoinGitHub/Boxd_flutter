import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

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

class ApiClient {
  static const String baseUrl = 'https://api.qimitech.com';
  static const String basePath = '/api/v1';
  static const String _appIdIOS = '8ee4a01508aaf380d306c750413f530a';
  static const String _appIdAndroid = 'aceab110a598dc6bff24805d23aab5df';
  static const String _appSecretIOS =
      'd66530267153704b2e86d89204089e6f0aed041b82f2a9729e4779b2cf51cd22';
  static const String _appSecretAndroid =
      '091eee43543d14bfed76282e4a1e3a90cddbef91fb8f6baabe4b61347e8595de';
  static const String userAgent = 'HotRice/1.0.0';

  static String? _token;

  static String get appId => Platform.isIOS ? _appIdIOS : _appIdAndroid;
  static String get appSecret =>
      Platform.isIOS ? _appSecretIOS : _appSecretAndroid;

  static void setToken(String token) => _token = token;
  static void clearToken() => _token = null;

  /// 生成签名
  static String _generateSignature(
    String method,
    String path,
    String timestamp,
    String body,
  ) {
    final token = _token?.replaceFirst('Bearer ', '') ?? '';
    final signString = token.isEmpty
        ? method + path + timestamp + body + userAgent
        : method + path + timestamp + token + body + userAgent;
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
  }) async {
    final uri = queryParams != null
        ? Uri.parse('$baseUrl$basePath$path').replace(
            queryParameters:
                queryParams.map((k, v) => MapEntry(k, v.toString())),
          )
        : Uri.parse('$baseUrl$basePath$path');

    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final bodyStr = body != null ? jsonEncode(body) : '';
    final signature =
        _generateSignature(method, basePath + path, timestamp, bodyStr);

    final headers = {
      'Content-Type': 'application/json',
      'X-App-ID': appId,
      'X-Timestamp': timestamp,
      'X-Signature': signature,
      'User-Agent': userAgent,
      if (_token != null) 'Authorization': 'Bearer $_token',
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
    print('Data: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> post(
          String path, Map<String, dynamic> body) =>
      _request('POST', path, body: body);

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

  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final result =
        await post('/auth/refresh-token', {'refresh_token': refreshToken});
    if (result['code'] == 200 &&
        result['data']?['tokens']?['access_token'] != null) {
      setToken(result['data']['tokens']['access_token']);
    }
    return result;
  }

  static Future<Map<String, dynamic>> resetPassword(
          String email, String code, String newPassword) =>
      post('/auth/reset-password',
          {'email': email, 'code': code, 'new_password': newPassword});

  static Future<Map<String, dynamic>> logout() async {
    final result = await post('/auth/logout', {});
    clearToken();
    return result;
  }

  // ==================== 用户管理 ====================
  static Future<Map<String, dynamic>> getUserProfile() =>
      put('/user/profile', {});

  static Future<Map<String, dynamic>> updateUserProfile(
          {String? email, String? phone}) =>
      put('/user/profile', {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone
      });

  static Future<Map<String, dynamic>> changePassword(
          String oldPassword, String newPassword) =>
      put('/user/password',
          {'old_password': oldPassword, 'new_password': newPassword});

  // ==================== 设备管理 ====================
  static Future<Map<String, dynamic>> bindDevice(String deviceUuid,
          {String? deviceName}) =>
      post('/devices/bind', {
        'device_uuid': deviceUuid,
        if (deviceName != null) 'device_name': deviceName
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

  static Future<Map<String, dynamic>> markNotificationRead(
          int notificationId) =>
      put('/notifications/$notificationId/read', {});

  static Future<Map<String, dynamic>> batchMarkRead(
          List<int> notificationIds) =>
      put('/notifications/batch-read', {'notification_ids': notificationIds});

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
