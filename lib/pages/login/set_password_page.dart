import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
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
    final lenOk = p.length >= 6 && p.length <= 8;
    final hasLetter = p.contains(RegExp(r'[A-Za-z]'));
    final hasDigit = p.contains(RegExp(r'\\d'));
    return lenOk && hasLetter && hasDigit;
  }

  @override
  Widget build(BuildContext context) {
    final desc = getDescription();
    return Scaffold(
        appBar: AppBar(title: const Text('设置密码')),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [
              Flexible(
                child: Assets.login.images.logo.image(
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              Text(desc),
              const SizedBox(height: 12),
              TextField(
                  controller: _pwdCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                      labelText: '密码',
                      suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure))),
                  onChanged: (_) => setState(() => {})),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: validate(_pwdCtrl.text)
                      ? () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const SetUsernamePage()))
                      : null,
                  child: const SizedBox(
                      width: double.infinity,
                      child: Center(child: Text('下一步')))),
            ])));
  }
}
