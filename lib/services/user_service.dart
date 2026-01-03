import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class UserInfo {
  final int userId;
  final String email;
  final String nickname;
  final String language;
  final String timezone;
  final String createdAt;

  UserInfo({
    required this.userId,
    required this.email,
    required this.nickname,
    required this.language,
    required this.timezone,
    required this.createdAt,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['user_id'] ?? 0,
      email: json['email'] ?? '',
      nickname: json['nickname'] ?? '',
      language: json['language'] ?? 'zh-CN',
      timezone: json['timezone'] ?? 'Asia/Shanghai',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'nickname': nickname,
      'language': language,
      'timezone': timezone,
      'created_at': createdAt,
    };
  }
}

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  UserInfo? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;

  UserInfo? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isLoggedIn => _accessToken != null;

  /// 保存 tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? expiresAt,
    int? expiresIn,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    ApiClient.setToken(accessToken);

    String expiresAtStr = '';
    if (expiresAt != null && expiresAt.isNotEmpty) {
      expiresAtStr = expiresAt;
      try {
        _expiresAt = DateTime.parse(expiresAt);
      } catch (e) {
        print('[USER] 解析过期时间失败: $e');
      }
    } else if (expiresIn != null) {
      _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
      expiresAtStr = _expiresAt!.toIso8601String();
    }

    final prefs = await SharedPreferences.getInstance();
    final saveAccessToken = await prefs.setString('access_token', accessToken);
    final saveRefreshToken =
        await prefs.setString('refresh_token', refreshToken);
    final saveExpiresAt = await prefs.setString('expires_at', expiresAtStr);
    print(
        '[USER] Tokens 已保存: access=$saveAccessToken, refresh=$saveRefreshToken, expires=$saveExpiresAt');
    print('[USER] 保存的 access_token: ${accessToken.substring(0, 20)}...');
    print('[USER] 保存的 refresh_token: ${refreshToken.substring(0, 20)}...');
    print('[USER] 保存的 expires_at: $expiresAtStr');
  }

  /// 保存用户信息（内存和本地）
  Future<void> saveUserInfo(UserInfo user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_info', jsonEncode(user.toJson()));
    print('[USER] 用户信息已保存: ${user.email}');
  }

  /// 从本地加载 token 和用户信息
  Future<bool> loadFromLocal() async {
    try {
      print('[USER] 开始从本地加载 token...');
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      _refreshToken = prefs.getString('refresh_token');
      final expiresAtStr = prefs.getString('expires_at');
      final userInfoStr = prefs.getString('user_info');

      print(
          '[USER] 读取的 access_token: ${_accessToken != null ? "${_accessToken!.substring(0, 20)}..." : "null"}');
      print(
          '[USER] 读取的 refresh_token: ${_refreshToken != null ? "${_refreshToken!.substring(0, 20)}..." : "null"}');
      print('[USER] 读取的 expires_at: $expiresAtStr');

      if (_accessToken == null) {
        print('[USER] 未找到本地 token');
        return false;
      }

      ApiClient.setToken(_accessToken!);
      print('[USER] 已更新 ApiClient token');

      if (userInfoStr != null) {
        try {
          final userJson = jsonDecode(userInfoStr);
          _currentUser = UserInfo.fromJson(userJson);
          print('[USER] 从本地加载用户信息: ${_currentUser?.email}');
        } catch (e) {
          print('[USER] 解析用户信息失败: $e');
        }
      }

      if (expiresAtStr != null) {
        _expiresAt = DateTime.parse(expiresAtStr);

        // 检查是否需要刷新 token：只有当今天过期或已过期时才刷新
        final now = DateTime.now();
        final expiryDate = DateTime(_expiresAt!.year, _expiresAt!.month, _expiresAt!.day);
        final today = DateTime(now.year, now.month, now.day);
        
        // 如果过期日期是今天或更早，则刷新token
        if (expiryDate.isBefore(today) || expiryDate.isAtSameMomentAs(today)) {
          if (_refreshToken != null) {
            print('[USER] Token 今天过期或已过期，刷新 token...');
            await refreshAccessToken();
          }
        } else {
          final daysUntilExpiry = expiryDate.difference(today).inDays;
          print('[USER] Token 将在 $daysUntilExpiry 天后过期，无需刷新');
        }
      }

      // 不在这里调用fetchUserInfo，让调用方决定是否需要获取用户信息
      return true;
    } catch (e) {
      print('[USER] 加载本地数据失败: $e');
      return false;
    }
  }

  /// 获取用户信息
  Future<UserInfo?> fetchUserInfo() async {
    if (_accessToken == null) return null;

    try {
      final result = await ApiClient.getUserProfile();
      if (result['code'] == 200) {
        final userData = result['data'];
        if (userData != null) {
          final userInfo = UserInfo.fromJson(userData);
          saveUserInfo(userInfo);
          print('[USER] 获取用户信息成功');
          return userInfo;
        }
      }
      print('[USER] 获取用户信息失败: ${result['message']}');
      return null;
    } catch (e) {
      print('[USER] 获取用户信息失败: $e');
      return null;
    }
  }

  /// 刷新 access token
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final result = await ApiClient.refreshToken(_refreshToken!);
      if (result['code'] == 200) {
        final tokens = result['data']?['tokens'];
        if (tokens != null) {
          await saveTokens(
            accessToken: tokens['access_token'],
            refreshToken: tokens['refresh_token'],
            expiresAt: tokens['expires_at'],
            expiresIn: tokens['expires_in'],
          );
          print('[USER] 刷新 token 成功');
          return true;
        }
      }
      ApiClient.clearToken();
      print('[USER] 刷新 token 失败: ${result['message']}');
      return false;
    } catch (e) {
      ApiClient.clearToken();
      print('[USER] 刷新 token 失败: $e');
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    _currentUser = null;
    ApiClient.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('expires_at');
    await prefs.remove('user_info');
    print('[USER] 已登出');
  }
}
