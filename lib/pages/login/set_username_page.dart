import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';

class SetUsernamePage extends StatefulWidget {
  const SetUsernamePage({super.key});
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('设置用户名')),
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
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: '用户名'),
                  onChanged: (_) => setState(() => {})),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: _nameCtrl.text.isNotEmpty
                      ? () => Navigator.of(context)
                          .popUntil((route) => route.isFirst)
                      : null,
                  child: const SizedBox(
                      width: double.infinity,
                      child: Center(child: Text('下一步')))),
            ])));
  }
}
