import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'set_password_page.dart';
import 'package:flutter/services.dart';

class VerificationPage extends StatefulWidget {
  final int codeLength;
  final bool isForReset;
  const VerificationPage(
      {super.key, required this.codeLength, required this.isForReset});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _nodes;
  @override
  void initState() {
    super.initState();
    _controllers =
        List.generate(widget.codeLength, (_) => TextEditingController());
    _nodes = List.generate(widget.codeLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String v) {
    if (v.isEmpty) return;
    if (v.length > 1) {
      v = v.substring(v.length - 1);
      _controllers[index].text = v;
    }
    if (index + 1 < _nodes.length) {
      _nodes[index + 1].requestFocus();
    } else {
      bool all = _controllers.every((c) => c.text.isNotEmpty);
      if (all) FocusScope.of(context).unfocus();
    }
    setState(() => {});
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isForReset ? '重置密码 - 输入验证码' : '注册 - 输入验证码';
    return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [
              Flexible(
                child: Assets.login.images.logo.image(
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              Text(title),
              const SizedBox(height: 24),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.codeLength, (i) {
                    return Container(
                      width: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _nodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(1)
                        ],
                        onChanged: (v) => _onChanged(i, v),
                        decoration: const InputDecoration(counterText: ''),
                      ),
                    );
                  })),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: _controllers.every((c) => c.text.isNotEmpty)
                      ? () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              const SetPasswordPage(isForReset: false)))
                      : null,
                  child: const SizedBox(
                      width: double.infinity,
                      child: Center(child: Text('下一步')))),
            ])));
  }
}
