import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/services/google_sign_in_service.dart';
import 'package:flutter_boxd_app_flow/services/apple_sign_in_service.dart';
import 'package:flutter_boxd_app_flow/services/facebook_sign_in_service.dart';
import 'package:flutter_boxd_app_flow/pages/login/email_login_page.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:flutter_boxd_app_flow/widgets/social_button.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'register_email_page.dart';

class LoginOptionsPage extends StatelessWidget {
  const LoginOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BxAppBar(title: ""),
      body: _LoginRoot(),
    );
  }
}

class _LoginRoot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Assets.login.images.logo.image(
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 17),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const EmailLoginPage(),
                // 不要 AppBar 重复
                fullscreenDialog: false,
              ));
            },
            child: SizedBox(
              width: double.infinity,
              child: Center(child: Text(l10n.t('email_login'))),
            ),
          ),
          const SizedBox(height: 10),
          SocialButton(
            text: l10n.t('facebook_login'),
            icon: Icons.facebook,
            onPressed: () async {
              await FacebookSignInService.signIn(context);
            },
          ),
          const SizedBox(height: 10),
          if (Platform.isAndroid)
            SocialButton(
              text: l10n.t('google_login'),
              icon: Icons.g_mobiledata,
              onPressed: () async {
                await GoogleSignInService.signIn(context);
              },
            ),
          if (Platform.isIOS)
            SocialButton(
              text: l10n.t('apple_login'),
              icon: Icons.apple,
              onPressed: () async {
                await AppleSignInService.signIn(context);
              },
            ),
          const SizedBox(height: 17),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const RegisterEmailPage(),
                fullscreenDialog: false,
              ));
            },
            child: Text(l10n.t('register')),
          ),
        ],
      ),
    );
  }
}
