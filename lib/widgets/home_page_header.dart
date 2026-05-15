import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/pages/login/email_login_page.dart';
import 'package:flutter_boxd_app_flow/pages/messages_page.dart';
import 'package:flutter_boxd_app_flow/pages/setting/setting_page.dart';
import 'package:flutter_boxd_app_flow/services/user_service.dart';
import 'package:flutter_boxd_app_flow/models/device_model.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';

/// 首页顶部标题与头像组件
class HomePageHeader extends StatelessWidget {
  final List<DeviceModel> devices;
  final bool isConnecting;
  final bool connected;
  final DeviceModel? currentDevice;
  final Map<String, dynamic>? deviceDetail;
  final VoidCallback? onDeviceSelectorTap;
  final VoidCallback? onSettingsReturn;
  /// 正式登录用户未读通知数（由首页请求 `/notifications/unread-count` 传入）
  final int unreadNotificationCount;

  const HomePageHeader({
    super.key,
    required this.devices,
    required this.isConnecting,
    required this.connected,
    this.currentDevice,
    this.deviceDetail,
    this.unreadNotificationCount = 0,
    this.onDeviceSelectorTap,
    this.onSettingsReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部标题与头像
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "QIMI",
                          style: TextStyle(
                            fontSize: 30,
                            color: AppColors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: " Innovation",
                          style: TextStyle(
                            fontSize: 20,
                            color: AppColors.black,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      // 设备名称显示（游客模式下也显示）
                      GestureDetector(
                        onTap: devices.length > 1 ? onDeviceSelectorTap : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLocalizations.of(context).t('homepage_slogan'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.black1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (UserService().isLoggedIn &&
                      !UserService().isGuestMode) ...[
                    _HomeMessageButton(
                      unreadCount: unreadNotificationCount,
                      onOpenMessages: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const MessagesPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton(
                    onPressed: () async {
                      // 登录用户或游客模式都可以进入设置页面
                      if (UserService().isLoggedIn ||
                          UserService().isGuestMode) {
                        final result = await Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                SettingsPage(deviceDetail: deviceDetail),
                          ),
                        );
                        // 如果从设置页返回时设备列表有变化，刷新设备列表
                        if (result == true && onSettingsReturn != null) {
                          onSettingsReturn!();
                        }
                      } else {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            fullscreenDialog: true,
                            pageBuilder: (_, __, ___) => const EmailLoginPage(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(33, 33),
                      shape: const CircleBorder(),
                    ),
                    child: Center(
                      child: (UserService().isGuestMode
                              ? Assets.home.images.homeAvatarYk
                              : Assets.home.images.homeAvatar)
                          .image(
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 消息入口：`home_message` 与角标；角标几何中心对齐按钮区域右上角
class _HomeMessageButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onOpenMessages;

  const _HomeMessageButton({
    required this.unreadCount,
    required this.onOpenMessages,
  });

  static const double _side = 42;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _side,
      height: _side,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onOpenMessages,
                customBorder: const CircleBorder(),
                child: Center(
                  child: Assets.home.images.homeMessage.image(
                    width: _side,
                    height: _side,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: _UnreadBadgeCenteredOnParentTopRight(count: unreadCount),
            ),
        ],
      ),
    );
  }
}

class _UnreadBadgeCenteredOnParentTopRight extends StatelessWidget {
  final int count;

  const _UnreadBadgeCenteredOnParentTopRight({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    const style = TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      height: 1.0,
    );
    final tp = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    const horizontalPadding = 5.0;
    const verticalPadding = 2.0;
    final w = math.max(16.0, tp.width + horizontalPadding * 2);
    final h = math.max(16.0, tp.height + verticalPadding * 2);
    return Transform.translate(
      offset: Offset(w / 2, -h / 2),
      child: Container(
        width: w,
        height: h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFE53935),
          borderRadius: BorderRadius.circular(h / 2),
        ),
        child: Text(label, style: style),
      ),
    );
  }
}
