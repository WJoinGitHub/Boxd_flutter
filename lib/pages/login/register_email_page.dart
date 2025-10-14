import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'verification_page.dart';

class RegisterEmailPage extends StatefulWidget {
  const RegisterEmailPage({super.key});
  @override
  State<RegisterEmailPage> createState() => _RegisterEmailPageState();
}

class _RegisterEmailPageState extends State<RegisterEmailPage> {
  final _emailCtrl = TextEditingController();
  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册 - 输入邮箱')),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            Flexible(
              child: Assets.login.images.logo.image(
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                  labelText: '邮箱',
                  suffixIcon: _emailCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _emailCtrl.clear()))
                      : null),
              onChanged: (_) => setState(() => {}),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: _emailCtrl.text.isNotEmpty
                    ? () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const VerificationPage(
                            codeLength: 4, isForReset: false)))
                    : null,
                child: const SizedBox(
                    width: double.infinity, child: Center(child: Text('下一步')))),
          ])),
    );
  }
}
