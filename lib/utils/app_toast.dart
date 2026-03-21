import 'dart:async';
import 'package:flutter/material.dart';

/// 居中显示的半透明 Toast（替代 SnackBar 的提示用法）
class AppToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    double maxWidth = 320,
  }) {
    if (!context.mounted) return;
    if (message.trim().isEmpty) return;

    final overlay = Overlay.of(context, rootOverlay: true);

    _entry?.remove();
    _entry = null;
    _timer?.cancel();
    _timer = null;

    _entry = OverlayEntry(
      builder: (ctx) => IgnorePointer(
        ignoring: true,
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_entry!);

    _timer = Timer(duration, () {
      _entry?.remove();
      _entry = null;
      _timer?.cancel();
      _timer = null;
    });
  }
}

