import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:flutter_boxd_app_flow/widgets/app_text_field.dart';
import 'set_username_page.dart';

class SetPasswordPage extends StatefulWidget {
  final bool isForReset;
  const SetPasswordPage({super.key, required this.isForReset});
  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final _pwdCtrl = TextEditingController();
  bool _obscure = true;
  @override
  void dispose() {
    _pwdCtrl.dispose();
    super.dispose();
  }

  String getDescription() {
    if (widget.isForReset) return '请输入新密码\n密码要求：1) 6-8 位 2) 包含字母和数字';
    return '设置密码\n密码要求：1) 6-8 位 2) 包含字母和数字';
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
                  onPressed: validate(_pwdCtrl.text)
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SetUsernamePage()),
                          )
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
                  child: const Text(
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
