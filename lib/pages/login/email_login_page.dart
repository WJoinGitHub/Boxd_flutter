import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _pwdCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  bool get _canLogin => _emailCtrl.text.isNotEmpty && _pwdCtrl.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('邮箱登录')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Flexible(
              child: Assets.login.images.logo.image(
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: '邮箱',
                suffixIcon: _emailCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _emailCtrl.clear()),
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pwdCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '密码',
                suffixIcon: _pwdCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _pwdCtrl.clear()),
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _canLogin
                  ? () {
                      // TODO: 这里可以加实际登录逻辑
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('模拟登录成功')),
                      );
                    }
                  : null,
              child: const SizedBox(
                  width: double.infinity, child: Center(child: Text('确认登录'))),
            ),
          ],
        ),
      ),
    );
  }
}
