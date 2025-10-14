import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart' as facebook;
import 'package:flutter_boxd_app_flow/models/auth_state.dart';

class FacebookSignInService {
  FacebookSignInService._();

  static Future<void> signIn(BuildContext context) async {
    final authManager = AuthStateManager();
    authManager.setLoading();

    try {
      final facebook.LoginResult result =
          await facebook.FacebookAuth.instance.login();

      if (result.status == facebook.LoginStatus.success) {
        final userData = await getUserData();
        if (userData != null) {
          final user = AuthUser(
            id: userData['id'] ?? '',
            email: userData['email'],
            name: userData['name'],
            photoUrl: userData['picture']?['data']?['url'],
            loginType: 'facebook',
          );
          authManager.setSuccess(user);
          authManager.showMessage(
              context, 'Facebook 登录成功：${user.name ?? '未知用户'}');
        } else {
          authManager.setFailed('无法获取用户信息');
        }
      } else if (result.status == facebook.LoginStatus.cancelled) {
        authManager.setCancelled();
      } else {
        authManager.setFailed('登录失败');
      }
    } on Exception catch (e) {
      authManager.setFailed('Facebook 登录失败：$e');
      authManager.showMessage(context, 'Facebook 登录失败：$e');
    }
  }

  static Future<void> signOut() async {
    await facebook.FacebookAuth.instance.logOut();
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userData = await facebook.FacebookAuth.instance.getUserData();
      return userData;
    } on Exception {
      return null;
    }
  }
}
