import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/services/api_client.dart';
import 'package:flutter_boxd_app_flow/utils/app_toast.dart';
import 'package:url_launcher/url_launcher.dart';

/// 与 FAQ「联系我们 / 邮箱」一致：拉 brand_email，打开 mailto，失败则复制兜底。
class ContactSupportEmail {
  ContactSupportEmail._();

  static const String fallbackEmail = 'support@qimitech.com';

  static Future<String> resolveEmail() async {
    try {
      final result = await ApiClient.getFeedbackBrand();
      if (result['code'] == 200 && result['data'] is Map) {
        final email =
            (result['data'] as Map)['brand_email']?.toString().trim();
        if (email != null && email.isNotEmpty) return email;
      }
    } catch (_) {}
    return fallbackEmail;
  }

  static Future<void> open(
    BuildContext context, {
    String? emailOverride,
  }) async {
    final email = (emailOverride != null && emailOverride.trim().isNotEmpty)
        ? emailOverride.trim()
        : await resolveEmail();
    if (!context.mounted) return;
    final uri = Uri.parse('mailto:$email');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _copyFallback(context, email);
      }
    } catch (_) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
        if (!launched && context.mounted) {
          _copyFallback(context, email);
        }
      } catch (_) {
        if (context.mounted) _copyFallback(context, email);
      }
    }
  }

  static void _copyFallback(BuildContext context, String email) {
    Clipboard.setData(ClipboardData(text: email));
    final l10n = AppLocalizations.of(context);
    AppToast.show(
      context,
      l10n.t('email_address_copied').replaceAll('{email}', email),
      duration: const Duration(seconds: 2),
    );
  }
}
