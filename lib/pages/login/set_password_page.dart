import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/services/api_client.dart';
import 'package:flutter_boxd_app_flow/services/user_service.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:flutter_boxd_app_flow/widgets/app_text_field.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';

class SetPasswordPage extends StatefulWidget {
  final bool isForReset;
  final String email;
  final String verifyCode;
  final String? nickname;
  const SetPasswordPage({
    super.key,
    required this.isForReset,
    required this.email,
    required this.verifyCode,
    this.nickname,
  });
  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final _pwdCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    final l10n = AppLocalizations.of(context);
    if (!validate(_pwdCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('password_requirements_detail'))),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      if (widget.isForReset) {
        final result = await ApiClient.resetPassword(
          widget.email,
          widget.verifyCode,
          _pwdCtrl.text,
        );
        if (result['code'] == 200 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.t('password_reset_success'))),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? l10n.t('reset_failed'))),
          );
        }
      } else {
        final result = await ApiClient.register(
          email: widget.email,
          password: _pwdCtrl.text,
          nickname: widget.nickname!,
          verifyToken: widget.verifyCode,
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
            }
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.t('registration_success'))),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? l10n.t('registration_failed'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.t('request_error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool validate(String p) {
    final lenOk = p.length >= 8 && p.length <= 20;
    final hasLetter = p.contains(RegExp(r'[A-Za-z]'));
    final hasDigit = p.contains(RegExp(r'\d')); // ✅ 修正这里
    return lenOk && hasLetter && hasDigit;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = widget.isForReset ? l10n.t('reset_password') : l10n.t('create_password');
    final desc = l10n.t('please_enter_six_or_more_characters');
    return Scaffold(
        appBar: const BxAppBar(title: ""),
        backgroundColor: AppColors.pageBg,
        body: Padding(
            padding: const EdgeInsets.all(13.0),
            child: Column(children: [
              const SizedBox(height: 13),
              Center(
                child: SizedBox(
                  height: 58,
                  child: Assets.login.images.logo.image(fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 27,
                  fontFamily: 'SF Pro',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                desc,
                style: TextStyle(
                  fontFamily: 'SF Pro',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  height: 1.0,
                  color: AppColors.gray3,
                ),
              ),
              const SizedBox(height: 25),
              AppTextField(
                  controller: _pwdCtrl,
                  labelText: l10n.t('password'),
                  obscureText: _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  onChanged: (_) => setState(() {})), // ✅ 确保每次输入都会重建按钮),
              if (!widget.isForReset) ...[
                const SizedBox(height: 7),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('enter_six_or_more_characters'),
                        style: TextStyle(
                          fontFamily: 'SF Pro',
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          height: 1.0,
                          letterSpacing: 0,
                          color: Color(0xFF131313),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        l10n.t('eight_to_twenty_characters'),
                        style: TextStyle(
                          fontFamily: 'SF Pro',
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          height: 1.0,
                          letterSpacing: 0,
                          color: Color(0xFF131313),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        l10n.t('letters_numbers_special_characters'),
                        style: TextStyle(
                          fontFamily: 'SF Pro',
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          height: 1.0,
                          letterSpacing: 0,
                          color: Color(0xFF131313),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: validate(_pwdCtrl.text) && !_loading
                      ? _savePassword
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: validate(_pwdCtrl.text)
                        ? AppColors.orange
                        : AppColors.gray2,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
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
                          l10n.t('save'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ])));
  }
}
