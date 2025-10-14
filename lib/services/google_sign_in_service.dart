import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_boxd_app_flow/models/auth_state.dart';

class GoogleSignInService {
  GoogleSignInService._();

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
    ],
  );

  static Future<void> signIn(BuildContext context) async {
    final authManager = AuthStateManager();
    authManager.setLoading();

    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        final user = AuthUser(
          id: account.id,
          email: account.email,
          name: account.displayName,
          photoUrl: account.photoUrl,
          loginType: 'google',
        );
        authManager.setSuccess(user);
        authManager.showMessage(context, 'Google 登录成功：${user.email}');
      } else {
        authManager.setCancelled();
      }
    } on Exception catch (e) {
      authManager.setFailed('Google 登录失败：$e');
      authManager.showMessage(context, 'Google 登录失败：$e');
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
