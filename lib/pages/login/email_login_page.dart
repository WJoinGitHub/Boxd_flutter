import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/pages/login/register_email_page.dart';
import 'package:flutter_boxd_app_flow/pages/login/verification_page.dart';
import 'package:flutter_boxd_app_flow/pages/home_page.dart';
import 'package:flutter_boxd_app_flow/services/api_client.dart';
import 'package:flutter_boxd_app_flow/services/user_service.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/widgets/app_text_field.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _pwdCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  bool get _canLogin => _isEmail(_emailCtrl.text) && _pwdCtrl.text.isNotEmpty;

  bool _isEmail(String v) {
    if (v.isEmpty) return false;
    final emailReg =
        RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    return emailReg.hasMatch(v);
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
              isGuest: true, // 标记为游客模式
            );

            final userInfo = UserInfo.fromJson(user);
            await UserService().saveUserInfo(userInfo, isGuest: true);

            // 游客登录成功后调用 user/profile 接口刷新用户信息
            try {
              await UserService().fetchUserInfo();
              print(
                  '[GUEST_LOGIN] 用户信息已刷新: ${UserService().currentUser?.nickname}');
            } catch (e) {
              print('[GUEST_LOGIN] 刷新用户信息失败: $e');
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.t('guest_login_success'))),
          );
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

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      final result = await ApiClient.login(
        email: _emailCtrl.text,
        password: _pwdCtrl.text,
      );

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
            );

            final userInfo = UserInfo.fromJson(user);
            await UserService().saveUserInfo(userInfo);

            // 登录成功后调用 user/profile 接口刷新用户信息
            try {
              await UserService().fetchUserInfo();
              print('[LOGIN] 用户信息已刷新: ${UserService().currentUser?.nickname}');
            } catch (e) {
              print('[LOGIN] 刷新用户信息失败: $e');
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.t('login_success'))),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? l10n.t('login_failed'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.t('login_failed')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('sign_in')),
        automaticallyImplyLeading: false, // 不显示返回按钮
      ),
      backgroundColor: AppColors.pageBg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 13),
              Center(
                child: SizedBox(
                  height: 58,
                  child: Assets.login.images.logo.image(fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 25),
              AppTextField(
                controller: _emailCtrl,
                labelText: l10n.t('enter_email'),
                keyboardType: TextInputType.emailAddress,
                suffixIcon: _emailCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _emailCtrl.clear()),
                      )
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 13),
              AppTextField(
                controller: _pwdCtrl,
                labelText: l10n.t('password'),
                obscureText: _obscure,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_pwdCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _pwdCtrl.clear()),
                      ),
                    IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ],
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => VerificationPage(
                              codeLength: 4,
                              isForReset: true,
                              email: _emailCtrl.text,
                            )));
                  },
                  child: Text(
                    l10n.t('forgot_password'),
                    style: TextStyle(color: AppColors.orange, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _canLogin && !_loading ? _login : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ).copyWith(
                  foregroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.disabled)) {
                        return Colors.black.withOpacity(0.3);
                      }
                      return Colors.white;
                    },
                  ),
                ),
                child: Center(
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
                          l10n.t('sign_in'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w400),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${l10n.t('dont_have_account')} '),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const RegisterEmailPage()));
                        },
                        child: Text(
                          l10n.t('sign_up'),
                          style:
                              TextStyle(color: AppColors.orange, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _loading ? null : _guestLogin,
                    child: Text(
                      l10n.t('guest_login'),
                      style: TextStyle(
                        color: AppColors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
