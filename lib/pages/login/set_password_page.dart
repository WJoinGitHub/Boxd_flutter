import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/services/api_client.dart';
import 'package:flutter_boxd_app_flow/services/user_service.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:flutter_boxd_app_flow/widgets/app_text_field.dart';

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
    if (!validate(_pwdCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码要求：8-20位，包含字母和数字')),
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
            const SnackBar(content: Text('密码重置成功')),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? '重置失败')),
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
              const SnackBar(content: Text('注册成功！')),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? '注册失败')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('request error: $e')),
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
    final title = widget.isForReset ? 'Reset Password' : 'Create Password';
    final desc = widget.isForReset
        ? 'Pleas enter six or more characters'
        : 'Pleas enter six or more characters';
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
                  labelText: 'Password',
                  obscureText: _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  onChanged: (_) => setState(() {})), // ✅ 确保每次输入都会重建按钮),
              if (!widget.isForReset) ...[
                const SizedBox(height: 7),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter six or more characters',
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
                        '8 to 20 characters',
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
                        'Letters, number, and special characters',
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
                height: 42,
                child: ElevatedButton(
                  onPressed: validate(_pwdCtrl.text) && !_loading
                      ? _savePassword
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: validate(_pwdCtrl.text)
                        ? AppColors.orange
                        : AppColors.gray2, // 灰色禁用状态
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontFamily: 'SF Pro',
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            height: 1.0,
                            letterSpacing: 0,
                          ),
                        ),
                ),
              ),
            ])));
  }
}
