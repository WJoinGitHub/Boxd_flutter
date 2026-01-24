import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/pages/login/set_password_page.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';

class SetUsernamePage extends StatefulWidget {
  final String email;
  final String verifyCode;
  const SetUsernamePage({
    super.key,
    required this.email,
    required this.verifyCode,
  });
  @override
  State<SetUsernamePage> createState() => _SetUsernamePageState();
}

class _SetUsernamePageState extends State<SetUsernamePage> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _next() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SetPasswordPage(
          isForReset: false,
          email: widget.email,
          verifyCode: widget.verifyCode,
          nickname: _nameCtrl.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
        appBar: const BxAppBar(title: ""),
        body: Padding(
            padding: const EdgeInsets.all(13.0),
            child: Column(children: [
              Flexible(
                child: Assets.login.images.logo.image(fit: BoxFit.contain),
              ),
              const SizedBox(height: 17),
              TextField(
                  controller: _nameCtrl,
                  decoration:
                      InputDecoration(labelText: l10n.t('username_label')),
                  onChanged: (_) => setState(() => {})),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _nameCtrl.text.isNotEmpty ? _next : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ).copyWith(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.disabled)) {
                          return Colors.black.withOpacity(0.1);
                        }
                        return AppColors.orange; // 可点击时使用主题橙色
                      },
                    ),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                  ),
                  child: Text(l10n.t('next'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w400)),
                ),
              ),
            ])));
  }
}
