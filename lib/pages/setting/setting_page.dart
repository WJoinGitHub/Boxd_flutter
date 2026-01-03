import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/pages/setting/unit_switching_page.dart';
import 'package:flutter_boxd_app_flow/pages/setting/feedback_page.dart';
import 'package:flutter_boxd_app_flow/pages/setting/my_devices_page.dart';
import 'package:flutter_boxd_app_flow/services/api_client.dart';
import 'package:flutter_boxd_app_flow/services/user_service.dart';
import 'package:flutter_boxd_app_flow/services/ble_service.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/utils/app_storage.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  final Map<String, dynamic>? deviceDetail;

  const SettingsPage({super.key, this.deviceDetail});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool allowNotifications = true;
  String temperatureUnit = '°C';
  String? privacyPolicyUrl;
  String? termsUrl;
  final bleService = BleService();

  @override
  void initState() {
    super.initState();
    _loadUnit();
    _loadPolicies();
  }

  Future<void> _loadUnit() async {
    final unit = await AppStorage.loadUnit();
    setState(() => temperatureUnit = unit);
  }

  Future<void> _loadPolicies() async {
    try {
      final result = await ApiClient.getPolicies();
      if (result['code'] == 200 && result['data'] != null) {
        setState(() {
          privacyPolicyUrl = result['data']['privacy_policy']?['url'];
          termsUrl = result['data']['terms_of_service']?['url'];
        });
      }
    } catch (e) {
      print('Failed to load policies: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BxAppBar(
        leftIcon: Assets.common.images.deviceBack.image(
          width: 35,
          height: 35,
          fit: BoxFit.contain,
        ),
        title: "Settings",
      ),
      body: ListView(
        padding: const EdgeInsets.all(13),
        children: [
          _buildProfile(),
          const SizedBox(height: 10),
          _buildCouponCard(),
          const SizedBox(height: 10),
          _buildSupportTile(),
          const SizedBox(height: 17),

          /// Device Section
          _buildSectionTitle('Device'),
          _buildSectionContainer([
            _buildRowTile(
              'My Device',
              onTap: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MyDevicesPage(),
                  ),
                );
                // 如果设备列表有变化，返回true通知首页刷新
                if (result == true && mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
            _buildRowTile(
              'Unit switching',
              leading: Assets.setting.images.temperatureUnitSetting.image(
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
              trailing: temperatureUnit,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UnitSwitchingPage(),
                  ),
                );
                // 重新加载单位（因为单位可能已经在UnitSwitchingPage中保存了）
                await _loadUnit();
              },
            ),
          ]),

          const SizedBox(height: 17),

          /// Info Section
          _buildSectionTitle('Info'),
          _buildSectionContainer([
            _buildRowTile(
              'Privacy Policy',
              leading: Assets.setting.images.privacyPolicySetting.image(
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
              onTap: () => _openUrl(privacyPolicyUrl),
            ),
            _buildRowTile(
              'Terms & Conditions',
              leading: Assets.setting.images.termsSetting.image(
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
              onTap: () => _openUrl(termsUrl),
            ),
          ]),

          const SizedBox(height: 17),

          /// App Section
          _buildSectionTitle('App'),
          _buildSectionContainer([
            _buildRowTile(
              'Feedback',
              leading: Assets.setting.images.feedbackSetting.image(
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FeedbackPage(),
                  ),
                );
              },
            ),
            _buildSwitchTile(
              title: "Allow Notifications",
              leading: Assets.setting.images.feedbackSetting.image(
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
              value: allowNotifications,
              onChanged: (value) {
                setState(() => allowNotifications = value);
              },
            ),
          ]),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _handleLogout,
                child: const Text(
                  'Logout',
                  style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 20),
              TextButton(
                onPressed: _handleDeleteAccount,
                child: const Text(
                  'Delete Account',
                  style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------- Components ----------------------------

  Widget _buildProfile() => Row(
        children: [
          Assets.user.images.userAvatar.image(width: 40, height: 40),
          const SizedBox(width: 10),
          const Text(
            'HotRice',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ],
      );

  Widget _buildCouponCard() => Container(
        height: 67,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: const [
            SizedBox(width: 13),
            Expanded(
              child: Text(
                '🎁 Coupons\nGet more food helpers',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(width: 13),
          ],
        ),
      );

  Widget _buildSupportTile() => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8E8).withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          leading: Assets.setting.images.setSupport.image(
            width: 18,
            height: 18,
            fit: BoxFit.contain,
          ),
          title: Text('Support',
              style: TextStyle(
                  color: AppColors.orange, fontWeight: FontWeight.w700)),
          subtitle: const Text('Help and Troubleshooting'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 13),
        ),
      );

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      );

  /// Section Container with grey background & dividers
  Widget _buildSectionContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8), // 浅灰色背景
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: List.generate(
          children.length * 2 - 1,
          (i) => i.isEven
              ? children[i ~/ 2]
              : Divider(height: 1, color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildRowTile(
    String title, {
    String? trailing,
    VoidCallback? onTap,
    Widget? leading, // ✅ 新增：支持传入自定义图片或图标
  }) {
    return ListTile(
      leading: leading, // ✅ 显示左侧图片
      title: Text(title),
      trailing: trailing != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trailing,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.arrow_forward_ios, size: 13),
              ],
            )
          : const Icon(Icons.arrow_forward_ios, size: 13),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required Widget leading,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 13),
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.orange,

      // 左侧图片
      secondary: leading,
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 断开设备连接
        if (bleService.isConnected) {
          await bleService.disconnect();
        }
        // 登出
        await ApiClient.logout();
        await UserService().logout();
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logout failed: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 断开设备连接
        if (bleService.isConnected) {
          await bleService.disconnect();
        }
        // 删除账号
        await ApiClient.deleteAccount();
        await UserService().logout();
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete account failed: $e')),
          );
        }
      }
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null) return;
    final fullUrl = url.startsWith('http') ? url : '${ApiClient.baseUrl}$url';
    final uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }
}
