import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class UserInfo {
  final String id;
  final String email;
  final String? avatarUrl;
  final String nickname;
  final String language;
  final String timezone;
  final String? country;
  final String? region;
  final String? lastLoginIp;
  final String? lastLoginAt;
  final String accountType;
  final String status;
  final bool isEmailVerified;
  final String? emailVerifiedAt;
  final String? lastPasswordChange;
  final int failedLoginAttempts;
  final String? lockedUntil;
  final String createdAt;
  final String updatedAt;

  UserInfo({
    required this.id,
    required this.email,
    this.avatarUrl,
    required this.nickname,
    required this.language,
    required this.timezone,
    this.country,
    this.region,
    this.lastLoginIp,
    this.lastLoginAt,
    required this.accountType,
    required this.status,
    required this.isEmailVerified,
    this.emailVerifiedAt,
    this.lastPasswordChange,
    required this.failedLoginAttempts,
    this.lockedUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'],
      nickname: json['nickname'] ?? '',
      language: json['language'] ?? 'zh-CN',
      timezone: json['timezone'] ?? 'Asia/Shanghai',
      country: json['country'],
      region: json['region'],
      lastLoginIp: json['last_login_ip'],
      lastLoginAt: json['last_login_at'],
      accountType: json['account_type'] ?? 'regular',
      status: json['status'] ?? 'active',
      isEmailVerified: json['is_email_verified'] ?? false,
      emailVerifiedAt: json['email_verified_at'],
      lastPasswordChange: json['last_password_change'],
      failedLoginAttempts: json['failed_login_attempts'] ?? 0,
      lockedUntil: json['locked_until'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'avatar_url': avatarUrl,
      'nickname': nickname,
      'language': language,
      'timezone': timezone,
      'country': country,
      'region': region,
      'last_login_ip': lastLoginIp,
      'last_login_at': lastLoginAt,
      'account_type': accountType,
      'status': status,
      'is_email_verified': isEmailVerified,
      'email_verified_at': emailVerifiedAt,
      'last_password_change': lastPasswordChange,
      'failed_login_attempts': failedLoginAttempts,
      'locked_until': lockedUntil,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // 为了向后兼容，保留 userId getter（从 id 中提取数字部分或使用 id）
  int get userId {
    // 如果 id 包含数字，尝试提取；否则返回 0
    final match = RegExp(r'\d+').firstMatch(id);
    return match != null ? int.tryParse(match.group(0) ?? '0') ?? 0 : 0;
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
  bool _isGuestMode = false; // 是否为游客模式

  // 401错误回调，用于通知UI清空设备列表
  void Function()? onUnauthorized;

  UserInfo? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isLoggedIn => _accessToken != null;
  bool get isGuestMode => _isGuestMode;

  /// 保存 tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? expiresAt,
    int? expiresIn,
    bool isGuest = false, // 是否为游客模式
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _isGuestMode = isGuest;
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

    // 游客模式不保存到本地
    if (!isGuest) {
      final prefs = await SharedPreferences.getInstance();
      final saveAccessToken =
          await prefs.setString('access_token', accessToken);
      final saveRefreshToken =
          await prefs.setString('refresh_token', refreshToken);
      final saveExpiresAt = await prefs.setString('expires_at', expiresAtStr);
      print(
          '[USER] Tokens 已保存: access=$saveAccessToken, refresh=$saveRefreshToken, expires=$saveExpiresAt');
      print('[USER] 保存的 access_token: ${accessToken.substring(0, 20)}...');
      print('[USER] 保存的 refresh_token: ${refreshToken.substring(0, 20)}...');
      print('[USER] 保存的 expires_at: $expiresAtStr');
    } else {
      print('[USER] 游客模式，不保存 tokens 到本地');
    }
  }

  /// 保存用户信息（内存和本地）
  Future<void> saveUserInfo(UserInfo user, {bool isGuest = false}) async {
    _currentUser = user;
    // 游客模式不保存到本地
    if (!isGuest) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_info', jsonEncode(user.toJson()));
      print('[USER] 用户信息已保存: ${user.email}');
    } else {
      print('[USER] 游客模式，用户信息仅保存在内存: ${user.email}');
    }
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
        final expiryDate =
            DateTime(_expiresAt!.year, _expiresAt!.month, _expiresAt!.day);
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
    _isGuestMode = false;
    ApiClient.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('expires_at');
    await prefs.remove('user_info');
    print('[USER] 已登出');

    // 触发401回调，通知UI清空设备列表
    onUnauthorized?.call();
  }
}
