import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/models/welcome_popup.dart';
import 'package:flutter_boxd_app_flow/services/api_client.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/utils/contact_support_email.dart';

/// 首页欢迎 / 联系客服弹窗（`GET /popups/welcome`）
class HomeWelcomeConnectPopup {
  HomeWelcomeConnectPopup._();

  static bool _inFlight = false;

  /// 拉取接口；`should_show` 为 true 时展示，并在展示后 `POST /popups/welcome/ack`
  static Future<void> fetchAndShowIfNeeded(BuildContext context) async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      if (!context.mounted) return;
      final language = _apiLanguage(Localizations.localeOf(context));
      final result = await ApiClient.getWelcomePopup(language: language);
      if (!context.mounted) return;
      final data = WelcomePopup.fromApiResponse(result);
      if (data == null) return;
      await show(context, data, language: language);
    } catch (_) {
      // 静默失败
    } finally {
      _inFlight = false;
    }
  }

  static String _apiLanguage(Locale locale) {
    if (locale.languageCode == 'zh') {
      final c = locale.countryCode?.toUpperCase();
      if (c == 'TW' || c == 'HK' || c == 'MO') return 'zh-$c';
      return 'zh-CN';
    }
    return locale.languageCode;
  }

  static Future<void> show(
    BuildContext context,
    WelcomePopup data, {
    required String language,
  }) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => _WelcomeConnectDialog(data: data, language: language),
    );
  }
}

class _WelcomeConnectDialog extends StatefulWidget {
  final WelcomePopup data;
  final String language;

  const _WelcomeConnectDialog({
    required this.data,
    required this.language,
  });

  @override
  State<_WelcomeConnectDialog> createState() => _WelcomeConnectDialogState();
}

class _WelcomeConnectDialogState extends State<_WelcomeConnectDialog> {
  bool _dontRemind = false;
  bool _dismissHandled = false;
  bool _ackedDisplay = false;

  @override
  void initState() {
    super.initState();
    // 弹窗实际展示后上报 action=shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_ackDisplayed());
    });
  }

  Future<void> _ackDisplayed() async {
    if (_ackedDisplay) return;
    _ackedDisplay = true;
    try {
      await ApiClient.ackWelcomePopup(
        action: 'shown',
        language: widget.language,
      );
    } catch (_) {}
  }

  Future<void> _handleDismiss() async {
    if (_dismissHandled) return;
    _dismissHandled = true;
    // 勾选「不再提醒」时再上报 action=snooze
    if (_dontRemind && widget.data.showSnooze) {
      try {
        await ApiClient.ackWelcomePopup(
          action: 'snooze',
          language: widget.language,
        );
      } catch (_) {}
    }
  }

  Future<void> _close() async {
    await _handleDismiss();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _onContactSupport() async {
    await ContactSupportEmail.open(
      context,
      emailOverride: widget.data.email,
    );
    if (!mounted) return;
    await _close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = widget.data;
    final title = data.title.trim();
    final content = data.content.trim();
    final buttonText = data.buttonText.trim().isNotEmpty
        ? data.buttonText.trim()
        : l10n.t('welcome_connect_popup_button');
    final snoozeLabel = l10n
        .t('welcome_connect_popup_dont_remind_15d')
        .replaceAll('{days}', '${data.snoozeDays}');

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(_handleDismiss());
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, right: 8),
                        child: title.isEmpty
                            ? const SizedBox.shrink()
                            : Text(
                                title,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.black1,
                                  height: 1.25,
                                ),
                              ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.close,
                        color: AppColors.gray4,
                        size: 22,
                      ),
                      onPressed: () => unawaited(_close()),
                    ),
                  ],
                ),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      content,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: AppColors.black1,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: () => unawaited(_onContactSupport()),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.orange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              buttonText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => unawaited(_close()),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.black1,
                              side: BorderSide(color: AppColors.gray4),
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              l10n.t('welcome_connect_popup_got_it'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (data.showSnooze) ...[
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() => _dontRemind = !_dontRemind);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _dontRemind,
                              activeColor: AppColors.orange,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              onChanged: (v) {
                                setState(() => _dontRemind = v ?? false);
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              snoozeLabel,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.gray3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
