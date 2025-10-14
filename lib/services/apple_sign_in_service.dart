import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_boxd_app_flow/models/auth_state.dart';

class AppleSignInService {
  AppleSignInService._();

  static Future<void> signIn(BuildContext context) async {
    final authManager = AuthStateManager();
    authManager.setLoading();

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final name = credential.givenName != null && credential.familyName != null
          ? '${credential.givenName} ${credential.familyName}'
          : 'Apple 用户';

      final user = AuthUser(
        id: credential.userIdentifier ?? '',
        email: credential.email,
        name: name,
        photoUrl: null,
        loginType: 'apple',
      );

      authManager.setSuccess(user);
      authManager.showMessage(context, 'Apple 登录成功：$name');
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        authManager.setCancelled();
      } else {
        authManager.setFailed('Apple 登录失败：${e.message}');
        authManager.showMessage(context, 'Apple 登录失败：${e.message}');
      }
    } on Exception catch (e) {
      authManager.setFailed('Apple 登录失败：$e');
      authManager.showMessage(context, 'Apple 登录失败：$e');
    }
  }
}
