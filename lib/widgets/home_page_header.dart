import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/pages/login/email_login_page.dart';
import 'package:flutter_boxd_app_flow/pages/setting/setting_page.dart';
import 'package:flutter_boxd_app_flow/services/user_service.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';

/// 首页顶部标题与头像组件
class HomePageHeader extends StatelessWidget {
  final List<Map<String, dynamic>> devices;
  final bool isConnecting;
  final bool connected;
  final Map<String, dynamic>? currentDevice;
  final Map<String, dynamic>? deviceDetail;
  final VoidCallback? onDeviceSelectorTap;
  final VoidCallback? onSettingsReturn;

  const HomePageHeader({
    super.key,
    required this.devices,
    required this.isConnecting,
    required this.connected,
    this.currentDevice,
    this.deviceDetail,
    this.onDeviceSelectorTap,
    this.onSettingsReturn,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              ElevatedButton(
                onPressed: () async {
                  // 登录用户或游客模式都可以进入设置页面
                  if (UserService().isLoggedIn || UserService().isGuestMode) {
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
    );
  }
}
