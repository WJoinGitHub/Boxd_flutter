import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/utils/api_client.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart'; // ✅ 新增导入

class SetUsernamePage extends StatefulWidget {
  const SetUsernamePage({super.key});
  @override
  State<SetUsernamePage> createState() => _SetUsernamePageState();
}

class _SetUsernamePageState extends State<SetUsernamePage> {
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final body = {
        "username": _nameCtrl.text,
        "password": "Test1234", // ⚠️ 这里可以改成前面页面传入的真实密码
        "email": "test@example.com",
        "agree_privacy_policy": true,
        "agree_terms_of_service": true,
        "policy_version": "1.0",
      };

      final res = await ApiClient.post('/auth/register', body);

      if (res['code'] == 200) {
        setState(() {
          _message = '注册成功！';
        });
        // 注册成功后跳转到首页
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        setState(() {
          _message = res['message'] ?? '注册失败';
        });
      }
    } catch (e) {
      setState(() {
        _message = '请求出错：$e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  decoration: const InputDecoration(labelText: 'UserName'),
                  onChanged: (_) => setState(() => {})),
              const SizedBox(height: 20),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text(_message!,
                      style: const TextStyle(color: Colors.red)),
                ),
              ElevatedButton(
                  onPressed:
                      !_loading && _nameCtrl.text.isNotEmpty ? _register : null,
                  child: SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: Center(
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)
                              : const Text('下一步')))),
            ])));
  }
}
