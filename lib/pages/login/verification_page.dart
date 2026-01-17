import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/pages/login/set_username_page.dart';
import 'package:flutter_boxd_app_flow/services/api_client.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
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
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controllers =
        List.generate(widget.codeLength, (_) => TextEditingController());
    _nodes = List.generate(widget.codeLength, (_) => FocusNode());
    _sendCode(showLoading: false);
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

  Future<void> _verifyCode() async {
    final l10n = AppLocalizations.of(context);
    final code = _controllers.map((c) => c.text).join();
    try {
      final result = await ApiClient.verifyCode(
        widget.email,
        code,
        widget.isForReset ? CodeType.resetPassword : CodeType.register,
      );
      if (result['code'] == 200 && mounted) {
        final verifyToken = result['data']?['verify_token'] ?? code;
        if (widget.isForReset) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SetPasswordPage(
                isForReset: true,
                email: widget.email,
                verifyCode: verifyToken,
              ),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SetUsernamePage(
                email: widget.email,
                verifyCode: verifyToken,
              ),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(result['message'] ?? l10n.t('verification_failed'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.t('verification_failed')}: $e')),
        );
      }
    }
  }

  Future<void> _sendCode({bool showLoading = true}) async {
    final l10n = AppLocalizations.of(context);
    if (showLoading) setState(() => _loading = true);
    try {
      final result = await ApiClient.sendCode(
        widget.email,
        widget.isForReset ? CodeType.resetPassword : CodeType.register,
      );
      if (result['code'] == 200) {
        _startTimer();
      } else {
        setState(() => _secondsLeft = 0);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? l10n.t('send_failed'))),
          );
        }
      }
    } catch (e) {
      setState(() => _secondsLeft = 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.t('send_failed')}: $e')),
        );
      }
    } finally {
      if (showLoading && mounted) setState(() => _loading = false);
    }
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
    final l10n = AppLocalizations.of(context);
    final title =
        widget.isForReset ? l10n.t('reset_password') : l10n.t('sign_up');
    return Scaffold(
      appBar: const BxAppBar(title: ""),
      body: Padding(
        padding: const EdgeInsets.all(13.0),
        child: Column(
          children: [
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

            // 上方提示文案
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13.0),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: l10n.t('please_enter_code_sent_to_email'),
                      style: TextStyle(
                        fontFamily: 'SF Pro',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        height: 1.0,
                        color: AppColors.gray3,
                      ),
                    ),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        fontFamily: 'SF Pro',
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        height: 1.0,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: l10n.t('for_verification'),
                      style: TextStyle(
                        fontFamily: 'SF Pro',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        height: 1.0,
                        color: AppColors.gray3,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // 验证码输入框
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.codeLength, (i) {
                return Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
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
                        borderRadius: BorderRadius.circular(7),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.orange, width: 1.5),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 13),

            // 倒计时 / send again 按钮
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _secondsLeft > 0
                  ? Text(
                      '${l10n.t('request_new_code_in')}${_secondsLeft}${l10n.t('seconds')}',
                      key: const ValueKey('countdown'),
                      style: TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 12,
                        color: AppColors.gray2,
                      ),
                      textAlign: TextAlign.center,
                    )
                  : TextButton(
                      key: const ValueKey('sendagain'),
                      onPressed: _loading ? null : () => _sendCode(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.orange,
                        padding: EdgeInsets.zero,
                        overlayColor: Colors.transparent,
                      ),
                      child: _loading
                          ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.orange,
                              ),
                            )
                          : Text(
                              l10n.t('send_again'),
                              style: TextStyle(
                                fontFamily: 'SF Pro',
                                fontSize: 12,
                                color: AppColors.orange,
                              ),
                            ),
                    ),
            ),

            const SizedBox(height: 20),

            // 下一步按钮
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _controllers.every((c) => c.text.isNotEmpty)
                    ? _verifyCode
                    : null,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.t('verify_button'),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
