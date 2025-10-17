import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'set_password_page.dart';

class VerificationPage extends StatefulWidget {
  final int codeLength;
  final bool isForReset;
  final String email;
  const VerificationPage({
    super.key,
    required this.codeLength,
    required this.isForReset,
    required this.email,
  });

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _nodes;
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controllers =
        List.generate(widget.codeLength, (_) => TextEditingController());
    _nodes = List.generate(widget.codeLength, (_) => FocusNode());
    _startTimer();
  }

  void _startTimer() {
    setState(() => _secondsLeft = 59);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var n in _nodes) {
      n.dispose();
    }
    _timer?.cancel();
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isForReset ? 'Reset Password' : 'Sign In';
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                height: 70,
                child: Assets.login.images.logo.image(fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: AppColors.black,
                fontSize: 32,
                fontFamily: 'SF Pro',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // 上方提示文案
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Please enter the 4-digit code sent to your email ',
                      style: TextStyle(
                        fontFamily: 'SF Pro',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        height: 1.0,
                        color: AppColors.gray3,
                      ),
                    ),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        fontFamily: 'SF Pro',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.0,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: ' for verification.',
                      style: TextStyle(
                        fontFamily: 'SF Pro',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        height: 1.0,
                        color: AppColors.gray3,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // 验证码输入框
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
                      LengthLimitingTextInputFormatter(1),
                    ],
                    onChanged: (v) => _onChanged(i, v),
                    decoration: InputDecoration(
                      counterText: '',
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.orange, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // 倒计时 / send again 按钮
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _secondsLeft > 0
                  ? Text(
                      'Request new code in ${_secondsLeft}s',
                      key: const ValueKey('countdown'),
                      style: TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 14,
                        color: AppColors.gray2,
                      ),
                      textAlign: TextAlign.center,
                    )
                  : TextButton(
                      key: const ValueKey('sendagain'),
                      onPressed: _startTimer,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.orange,
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'Send again',
                        style: TextStyle(
                          fontFamily: 'SF Pro',
                          fontSize: 14,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            // 下一步按钮
            ElevatedButton(
              onPressed: _controllers.every((c) => c.text.isNotEmpty)
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              SetPasswordPage(isForReset: widget.isForReset),
                        ),
                      )
                  : null,
              child: const SizedBox(
                width: double.infinity,
                height: 50,
                child: Center(child: Text('VERTICAL')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
