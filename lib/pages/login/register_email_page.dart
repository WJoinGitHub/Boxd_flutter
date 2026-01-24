import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/utils/app_urls.dart';
import 'package:flutter_boxd_app_flow/widgets/app_text_field.dart';
import 'package:flutter_boxd_app_flow/pages/webview_page.dart';
import 'package:flutter_boxd_app_flow/pages/login/email_login_page.dart';
import 'package:flutter_boxd_app_flow/pages/login/verification_page.dart';
import 'package:flutter_boxd_app_flow/services/api_client.dart';
import 'package:flutter_boxd_app_flow/services/user_service.dart';
import 'package:flutter_boxd_app_flow/pages/home_page.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';

class RegisterEmailPage extends StatefulWidget {
  const RegisterEmailPage({super.key});
  @override
  State<RegisterEmailPage> createState() => _RegisterEmailPageState();
}

class _RegisterEmailPageState extends State<RegisterEmailPage> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _openTerms() {
    final l10n = AppLocalizations.of(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebViewPage(
          url: AppUrls.termsOfService,
          title: l10n.t('terms_of_service'),
        ),
      ),
    );
  }

  void _openPrivacy() {
    final l10n = AppLocalizations.of(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebViewPage(
          url: AppUrls.privacyPolicy,
          title: l10n.t('privacy_policy'),
        ),
      ),
    );
  }

  Future<void> _guestLogin() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      final result = await ApiClient.guestLogin();

      if (result['code'] == 200 && mounted) {
        final data = result['data'];
        if (data != null) {
          final tokens = data['tokens'];
          final user = data['user'];

          if (tokens != null && user != null) {
            await UserService().saveTokens(
              accessToken: tokens['access_token'] ?? '',
              refreshToken: tokens['refresh_token'] ?? '',
              expiresIn: tokens['expires_in'],
              isGuest: true,
            );

            final userInfo = UserInfo.fromJson(user);
            await UserService().saveUserInfo(userInfo, isGuest: true);

            try {
              await UserService().fetchUserInfo();
            } catch (e) {
              print('[GUEST_LOGIN] 刷新用户信息失败: $e');
            }
          }
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ?? l10n.t('guest_login_failed'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.t('guest_login_failed')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _sendCode() {
    final l10n = AppLocalizations.of(context);
    if (!_emailCtrl.text.contains('@') || !_emailCtrl.text.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('invalid_email_message'))),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerificationPage(
          codeLength: 4,
          isForReset: false,
          email: _emailCtrl.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Logo
                    Center(
                      child: SizedBox(
                        height: 100,
                        child:
                            Assets.login.images.logo.image(fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 50),
                    // 标题：Sign up for HeatLink
                    Center(
                      child: Text(
                        l10n.t('sign_up_for'),
                        style: TextStyle(
                          color: AppColors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SF Pro',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 副标题：Create a profile, manage your device
                    Center(
                      child: Text(
                        l10n.t('create_a_profile'),
                        style: TextStyle(
                          color: AppColors.gray3,
                          fontSize: 15,
                          fontFamily: 'SF Pro',
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Email 输入框
                    AppTextField(
                      controller: _emailCtrl,
                      labelText: l10n.t('email'),
                      placeholderText: l10n.t('enter_email'),
                      keyboardType: TextInputType.emailAddress,
                      suffixIcon: _emailCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setState(() => _emailCtrl.clear()),
                            )
                          : null,
                      onChanged: (_) => setState(() => {}),
                    ),
                    const SizedBox(height: 15),
                    // 法律文本
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: AppColors.gray3,
                          fontSize: 12,
                          height: 1.5,
                          fontFamily: 'SF Pro',
                        ),
                        children: [
                          TextSpan(
                            text: l10n.t('agree_to_terms_prefix'),
                          ),
                          TextSpan(
                            text: l10n.t('terms_of_service'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = _openTerms,
                          ),
                          TextSpan(
                            text: l10n.t('agree_to_terms_middle'),
                          ),
                          TextSpan(
                            text: l10n.t('privacy_policy'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = _openPrivacy,
                          ),
                          TextSpan(
                            text: l10n.t('agree_to_terms_suffix'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Next 按钮
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _emailCtrl.text.isNotEmpty && !_loading
                            ? _sendCode
                            : null,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ).copyWith(
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.disabled)) {
                                return Colors.black.withOpacity(0.1);
                              }
                              return AppColors.orange; // 可点击时使用主题橙色
                            },
                          ),
                          foregroundColor: MaterialStateProperty.all<Color>(
                              Colors.white), // 无论是否可点击，文案都是白色
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n.t('next'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Guest mode 链接 - 在下一步按钮下面，右对齐
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _loading ? null : _guestLogin,
                        child: Text(
                          l10n.t('guest_mode'),
                          style: TextStyle(
                            color: AppColors.orange,
                            fontSize: 14,
                            fontFamily: 'SF Pro',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 底部 footer - 背景色#F6F7F7，高度80，文案距离上边距16
            Container(
              width: double.infinity,
              height: 80,
              padding: const EdgeInsets.only(top: 0, left: 20, right: 20),
              decoration: BoxDecoration(
                color: AppColors.fromHex(0xF6F7F7),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Center(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 16,
                      fontFamily: 'SF Pro',
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      TextSpan(
                        text: '${l10n.t('already_have_account')} ',
                      ),
                      TextSpan(
                        text: l10n.t('sign_in'),
                        style: TextStyle(
                          color: AppColors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const EmailLoginPage(),
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
