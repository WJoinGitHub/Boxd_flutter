import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/utils/app_urls.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:flutter_boxd_app_flow/widgets/app_text_field.dart';
import 'package:flutter_boxd_app_flow/pages/webview_page.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebViewPage(
          url: AppUrls.termsOfService,
          title: l10n.t('terms_of_service'),
        ),
      ),
    );
  }

  void _openPrivacy() {
    final l10n = AppLocalizations.of(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebViewPage(
          url: AppUrls.privacyPolicy,
          title: l10n.t('privacy_policy'),
        ),
      ),
    );
  }

  void _sendCode() {
    final l10n = AppLocalizations.of(context);
    if (!_emailCtrl.text.contains('@') || !_emailCtrl.text.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('invalid_email_message'))),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerificationPage(
          codeLength: 4,
          isForReset: false,
          email: _emailCtrl.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: BxAppBar(title: "", backgroundColor: AppColors.pageBg),
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
                l10n.t('sign_up'),
                style: TextStyle(color: AppColors.black, fontSize: 27),
              ),
            ),
            const SizedBox(height: 25),
            AppTextField(
              controller: _emailCtrl,
              labelText: l10n.t('email'),
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
                    TextSpan(
                      text: l10n.t('agree_to_terms_prefix'),
                    ),
                    TextSpan(
                      text: l10n.t('terms_of_service'),
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = _openTerms,
                    ),
                    TextSpan(
                      text: l10n.t('agree_to_terms_middle'),
                    ),
                    TextSpan(
                      text: l10n.t('privacy_policy'),
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
              height: 44,
              child: ElevatedButton(
                onPressed: _emailCtrl.text.isNotEmpty ? _sendCode : null,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.t('next'),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
