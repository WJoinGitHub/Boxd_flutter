import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/pages/setting/unit_switching_page.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/utils/app_storage.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool allowNotifications = true;
  String temperatureUnit = '°C';

  @override
  void initState() {
    super.initState();
    _loadUnit();
  }

  Future<void> _loadUnit() async {
    final unit = await AppStorage.loadUnit();
    setState(() => temperatureUnit = unit);
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
              'Firmware update',
              leading: Assets.setting.images.appVersionSetting.image(
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
              trailing: 'V1.0.1',
              onTap: () {},
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
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UnitSwitchingPage(),
                  ),
                );
                if (result != null) {
                  setState(() => temperatureUnit = result);
                  await AppStorage.saveUnit(result);
                }
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
            ),
            _buildRowTile(
              'Terms & Conditions',
              leading: Assets.setting.images.termsSetting.image(
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
            ),
          ]),

          const SizedBox(height: 17),

          /// App Section
          _buildSectionTitle('App'),
          _buildSectionContainer([
            _buildRowTile(
              'Share App',
              leading: Assets.setting.images.shareSetting.image(
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
            ),
            _buildRowTile(
              'Feedback',
              leading: Assets.setting.images.feedbackSetting.image(
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
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

          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          leading: Assets.setting.images.setSupport.image(
            width: 18,
            height: 18,
            fit: BoxFit.contain,
          ),
          title: Text('Support', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700)),
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
}
