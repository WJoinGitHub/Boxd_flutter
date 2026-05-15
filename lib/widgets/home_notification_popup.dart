import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/models/app_notification.dart';
import 'package:flutter_boxd_app_flow/services/api_client.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 首页通知弹窗（左上角标题，右上角关闭）
class HomeNotificationPopup {
  HomeNotificationPopup._();

  static const double _htmlBlockHeight = 220;

  static Future<void> show(
    BuildContext context,
    AppNotification data, {
    bool markReadWhenShown = false,
    VoidCallback? onMarkedRead,
  }) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        final popupTitle = data.popupTitle;
        final buttonText = (data.actionLabel?.trim().isNotEmpty ?? false)
            ? data.actionLabel!.trim()
            : l10n.t('notification_popup_button');
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: _MarkReadWhenShownHost(
            enabled: markReadWhenShown,
            notificationId: data.id,
            onMarkedRead: onMarkedRead,
            child: Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.none,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: popupTitle != null
                            ? Text(
                                popupTitle,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black1,
                                  height: 1.25,
                                ),
                              )
                            : const SizedBox.shrink(),
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
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.sizeOf(ctx).height * 0.5,
                        ),
                        child: _PopupContentBody(data: data),
                      ),
                      if (data.imageUrl != null &&
                          data.imageUrl!.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 16 / 10,
                            child: Image.network(
                              data.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                              loadingBuilder: (c, child, p) {
                                if (p == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            buttonText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}

/// 弹窗首帧展示后触发单条已读（避免 `builder` 重复重建导致多次请求）
class _MarkReadWhenShownHost extends StatefulWidget {
  final bool enabled;
  final int notificationId;
  final VoidCallback? onMarkedRead;
  final Widget child;

  const _MarkReadWhenShownHost({
    required this.enabled,
    required this.notificationId,
    this.onMarkedRead,
    required this.child,
  });

  @override
  State<_MarkReadWhenShownHost> createState() => _MarkReadWhenShownHostState();
}

class _MarkReadWhenShownHostState extends State<_MarkReadWhenShownHost> {
  @override
  void initState() {
    super.initState();
    if (!widget.enabled || widget.notificationId <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_markRead());
    });
  }

  Future<void> _markRead() async {
    if (!mounted) return;
    try {
      final res = await ApiClient.markNotificationRead(widget.notificationId);
      if (!mounted) return;
      if (res['code'] == 200) {
        widget.onMarkedRead?.call();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _PopupContentBody extends StatelessWidget {
  final AppNotification data;

  const _PopupContentBody({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isHtml && (data.contentHtml?.trim().isNotEmpty ?? false)) {
      return SizedBox(
        height: HomeNotificationPopup._htmlBlockHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _PopupHtmlWebView(html: data.contentHtml!.trim()),
        ),
      );
    }
    return SingleChildScrollView(
      child: Text(
        data.content,
        style: TextStyle(
          fontSize: 15,
          height: 1.45,
          color: AppColors.black1,
        ),
      ),
    );
  }
}

class _PopupHtmlWebView extends StatefulWidget {
  final String html;

  const _PopupHtmlWebView({required this.html});

  @override
  State<_PopupHtmlWebView> createState() => _PopupHtmlWebViewState();
}

class _PopupHtmlWebViewState extends State<_PopupHtmlWebView> {
  late final WebViewController _controller;
  bool _loading = true;
  Timer? _loadingFallbackTimer;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _hideLoading(),
          onWebResourceError: (_) => _hideLoading(),
        ),
      );
    // 弹窗内 WebView 若首帧前 load，部分机型会白屏；onPageFinished 也可能不回调
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        _controller.loadHtmlString(
          widget.html,
          baseUrl: Uri.parse(ApiClient.baseUrl).origin,
        ),
      );
      _loadingFallbackTimer =
          Timer(const Duration(milliseconds: 1200), _hideLoading);
    });
  }

  @override
  void dispose() {
    _loadingFallbackTimer?.cancel();
    super.dispose();
  }

  void _hideLoading() {
    _loadingFallbackTimer?.cancel();
    _loadingFallbackTimer = null;
    if (!mounted) return;
    if (!_loading) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _controller),
        if (_loading)
          const ColoredBox(
            color: Colors.white,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }
}
