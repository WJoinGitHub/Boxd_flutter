import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/services/google_sign_in_service.dart';
import 'package:flutter_boxd_app_flow/services/apple_sign_in_service.dart';
import 'package:flutter_boxd_app_flow/services/facebook_sign_in_service.dart';
import 'package:flutter_boxd_app_flow/pages/login/email_login_page.dart';
import 'package:flutter_boxd_app_flow/widgets/social_button.dart';
import 'register_email_page.dart';

class LoginOptionsPage extends StatelessWidget {
  const LoginOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // 去掉右边 ❌
      ),
      body: _LoginRoot(),
    );
  }
}

class _LoginRoot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Assets.login.images.logo.image(
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const EmailLoginPage(),
                // 不要 AppBar 重复
                fullscreenDialog: false,
              ));
            },
            child: const SizedBox(
              width: double.infinity,
              child: Center(child: Text('邮箱登录')),
            ),
          ),
          const SizedBox(height: 12),
          SocialButton(
            text: 'Facebook 登录',
            icon: Icons.facebook,
            onPressed: () async {
              await FacebookSignInService.signIn(context);
            },
          ),
          const SizedBox(height: 12),
          if (Platform.isAndroid)
            SocialButton(
              text: 'Google 登录',
              icon: Icons.g_mobiledata,
              onPressed: () async {
                await GoogleSignInService.signIn(context);
              },
            ),
          if (Platform.isIOS)
            SocialButton(
              text: 'Apple 登录',
              icon: Icons.apple,
              onPressed: () async {
                await AppleSignInService.signIn(context);
              },
            ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const RegisterEmailPage(),
                fullscreenDialog: false,
              ));
            },
            child: const Text('注册'),
          ),
        ],
      ),
    );
  }
}
