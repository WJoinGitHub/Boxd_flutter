import 'package:shared_preferences/shared_preferences.dart';

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
  bool get isLoggedIn => _accessToken != null && _currentUser != null;

  /// 保存 tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String expiresAt,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _expiresAt = DateTime.parse(expiresAt);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setString('expires_at', expiresAt);
    print('[USER] Tokens 已保存');
  }

  /// 保存用户信息
  Future<void> saveUserInfo(UserInfo user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user.userId);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_nickname', user.nickname);
    await prefs.setString('user_language', user.language);
    await prefs.setString('user_timezone', user.timezone);
    await prefs.setString('user_created_at', user.createdAt);
    print('[USER] 用户信息已保存: ${user.email}');
  }

  /// 从本地加载 token 和用户信息
  Future<bool> loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      _refreshToken = prefs.getString('refresh_token');
      final expiresAtStr = prefs.getString('expires_at');

      if (_accessToken == null) {
        print('[USER] 未找到本地 token');
        return false;
      }

      if (expiresAtStr != null) {
        _expiresAt = DateTime.parse(expiresAtStr);

        // 检查是否需要刷新 token
        final now = DateTime.now();
        final daysUntilExpiry = _expiresAt!.difference(now).inDays;

        if (daysUntilExpiry <= 3 && _refreshToken != null) {
          print('[USER] Token 将在 $daysUntilExpiry 天后过期，刷新 token...');
          await refreshAccessToken();
        }
      }

      final userId = prefs.getInt('user_id');
      final userEmail = prefs.getString('user_email');

      if (userId != null && userEmail != null) {
        _currentUser = UserInfo(
          userId: userId,
          email: userEmail,
          nickname: prefs.getString('user_nickname') ?? '',
          language: prefs.getString('user_language') ?? 'zh-CN',
          timezone: prefs.getString('user_timezone') ?? 'Asia/Shanghai',
          createdAt: prefs.getString('user_created_at') ?? '',
        );
        print('[USER] 已加载本地用户信息: $userEmail');
        return true;
      }

      return false;
    } catch (e) {
      print('[USER] 加载本地数据失败: $e');
      return false;
    }
  }

  /// 刷新 access token
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      // TODO: 调用实际的 API
      // final response = await http.post(
      //   Uri.parse('YOUR_API_URL/auth/refresh-token'),
      //   body: {'refresh_token': _refreshToken},
      // );
      // final data = jsonDecode(response.body);

      print('[USER] 刷新 token 成功');
      // await saveTokens(
      //   accessToken: data['access_token'],
      //   refreshToken: data['refresh_token'],
      //   expiresAt: data['expires_at'],
      // );
      return true;
    } catch (e) {
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('expires_at');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_nickname');
    await prefs.remove('user_language');
    await prefs.remove('user_timezone');
    await prefs.remove('user_created_at');
    print('[USER] 已登出');
  }
}
