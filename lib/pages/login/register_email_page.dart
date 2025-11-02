import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:flutter_boxd_app_flow/widgets/app_text_field.dart';
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

  void _openTerms() {
    // TODO: 打开 Terms of Service 页面
    debugPrint("Tapped Terms of Service");
  }

  void _openPrivacy() {
    // TODO: 打开 Privacy Policy 页面
    debugPrint("Tapped Privacy Policy");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BxAppBar(title: ""),
      backgroundColor: AppColors.pageBg,
      body: Padding(
        padding: const EdgeInsets.all(13.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // ✅ 左对齐
          children: [
            const SizedBox(height: 13),
            Center(
              child: SizedBox(
                height: 58,
                child: Assets.login.images.logo.image(fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                "Sign In",
                style: TextStyle(color: AppColors.black, fontSize: 27),
              ),
            ),
            const SizedBox(height: 25),
            AppTextField(
              controller: _emailCtrl,
              labelText: 'Email',
              keyboardType: TextInputType.emailAddress,
              suffixIcon: _emailCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _emailCtrl.clear()),
                    )
                  : null,
              onChanged: (_) => setState(() => {}),
            ),

            const SizedBox(height: 10),

            // ✅ 左对齐 + 整体段落 + 16 边距
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 0), // 已有外层16 padding
              child: RichText(
                textAlign: TextAlign.left,
                text: TextSpan(
                  style: TextStyle(
                    color: AppColors.gray3,
                    fontSize: 10,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                      text: 'By continuing, you agree to HotRice’s ',
                    ),
                    TextSpan(
                      text: 'Terms of Service',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = _openTerms,
                    ),
                    const TextSpan(
                      text: ' and confirm that you have read TikTok’s ',
                    ),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = _openPrivacy,
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: _emailCtrl.text.isNotEmpty
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VerificationPage(
                              codeLength: 4,
                              isForReset: false,
                              email: _emailCtrl.text,
                            ),
                          ),
                        )
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
