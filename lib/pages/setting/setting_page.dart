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
          width: 24,
          height: 24,
          fit: BoxFit.contain,
        ),
        title: "Settings",
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfile(),
          const SizedBox(height: 12),
          _buildCouponCard(),
          const SizedBox(height: 12),
          _buildSupportTile(),
          const SizedBox(height: 20),

          /// Device Section
          _buildSectionTitle('Device'),
          _buildSectionContainer([
            _buildRowTile(
              'Firmware update',
              leading: Assets.setting.images.appVersionSetting.image(
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              ),
              trailing: 'V1.0.1',
              onTap: () {},
            ),
            _buildRowTile(
              'Unit switching',
              leading: Assets.setting.images.temperatureUnitSetting.image(
                width: 22,
                height: 22,
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

          const SizedBox(height: 20),

          /// Info Section
          _buildSectionTitle('Info'),
          _buildSectionContainer([
            _buildRowTile(
              'Privacy Policy',
              leading: Assets.setting.images.privacyPolicySetting.image(
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
            _buildRowTile(
              'Terms & Conditions',
              leading: Assets.setting.images.termsSetting.image(
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
          ]),

          const SizedBox(height: 20),

          /// App Section
          _buildSectionTitle('App'),
          _buildSectionContainer([
            _buildRowTile(
              'Share App',
              leading: Assets.setting.images.shareSetting.image(
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
            _buildRowTile(
              'Feedback',
              leading: Assets.setting.images.feedbackSetting.image(
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
            _buildSwitchTile(
              title: "Allow Notifications",
              leading: Assets.setting.images.feedbackSetting.image(
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              ),
              value: allowNotifications,
              onChanged: (value) {
                setState(() => allowNotifications = value);
              },
            ),
          ]),

          const SizedBox(height: 24),

          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------- Components ----------------------------

  Widget _buildProfile() => Row(
        children: const [
          CircleAvatar(radius: 24, backgroundColor: Colors.black12),
          SizedBox(width: 12),
          Text(
            'HotRice',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
        ],
      );

  Widget _buildCouponCard() => Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: const [
            SizedBox(width: 16),
            Expanded(
              child: Text(
                '🎁 Coupons\nGet more food helpers',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(width: 16),
          ],
        ),
      );

  Widget _buildSupportTile() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const ListTile(
          title: Text('Support'),
          subtitle: Text('Help and Troubleshooting'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
        ),
      );

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
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
        borderRadius: BorderRadius.circular(16),
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
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            )
          : const Icon(Icons.arrow_forward_ios, size: 16),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.orange,

      // 左侧图片
      secondary: leading,
    );
  }
}
