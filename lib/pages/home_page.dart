import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/pages/device/device_connect_page.dart';
import 'package:flutter_boxd_app_flow/pages/setting/setting_page.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/pages/login/email_login_page.dart';
import 'package:flutter_boxd_app_flow/services/ble_service.dart';
import 'package:flutter_boxd_app_flow/services/user_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool connected = false;
  int temperature = 29;

  final bleService = BleService();

  @override
  void initState() {
    super.initState();
    print("HomePage initState start");
    _autoLogin();
    _autoConnect();
  }

  Future<void> _autoLogin() async {
    final hasToken = await UserService().loadFromLocal();
    if (hasToken && mounted) {
      setState(() {});
    }
  }

  Future<void> _autoConnect() async {
    print('[HOME] 尝试自动连接...');
    final device = await BleService.getFirstBoundDevice();
    if (device != null) {
      print('[HOME] 找到绑定设备，开始连接...');
      final success = await bleService.connect(device);
      if (success && mounted) {
        setState(() => connected = true);
        print('[HOME] 自动连接成功');
      }
    } else {
      print('[HOME] 未找到绑定设备');
    }
  }

  @override
  void dispose() {
    bleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 0, vertical: 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 顶部标题与头像
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "QIMI",
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: AppColors.gray4,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    "HotRice",
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (UserService().isLoggedIn) {
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder: (_, __, ___) =>
                                            const SettingsPage(),
                                      ),
                                    );
                                  } else {
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        fullscreenDialog: true,
                                        pageBuilder: (_, __, ___) =>
                                            const EmailLoginPage(),
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
                                  child: UserService().isLoggedIn
                                      ? CircleAvatar(
                                          radius: 16.5,
                                          backgroundColor: AppColors.orange,
                                          child: Text(
                                            UserService()
                                                    .currentUser
                                                    ?.nickname
                                                    .substring(0, 1)
                                                    .toUpperCase() ??
                                                'U',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        )
                                      : Assets.home.images.homeAvatar.image(
                                          width: 23,
                                          height: 27,
                                          fit: BoxFit.contain,
                                        ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 2),

                          // 连接状态
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  if (connected)
                                    Icon(
                                      Icons.circle,
                                      color: AppColors.green,
                                      size: 13,
                                    ),
                                  const SizedBox(width: 5),
                                  Text(
                                    connected
                                        ? "Connected"
                                        : "Connect your Lunch box",
                                    style: TextStyle(
                                      fontSize: connected ? 20 : 13,
                                      color: connected
                                          ? AppColors.green
                                          : Colors.black54,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ],
                              ),
                              if (!connected)
                                ElevatedButton(
                                  onPressed: () async {
                                    final result =
                                        await Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder: (_, __, ___) =>
                                            const DeviceConnectPage(),
                                      ),
                                    );
                                    if (result == true && mounted) {
                                      setState(() => connected = true);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(29, 27),
                                    shape: const CircleBorder(),
                                  ),
                                  child: Center(
                                    child: Assets.home.images.addDevice.image(
                                      width: 21,
                                      height: 21,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // 🔥 新增：左右图片区域
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 左边温度仪表 + 文案
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Assets.home.images.devTemperatureF.image(
                                    width: 117,
                                    fit: BoxFit.contain,
                                  ),
                                  Positioned(
                                    top: 54,
                                    child: Text(
                                      temperature.toString(),
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // 右边设备图片
                              Assets.home.images.homeDevice.image(
                                width: 150,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),

                          const SizedBox(height: 33),

                          // 三个功能按钮
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildModeButton(
                                "Ins",
                                Assets.home.images.homeIns
                                    .image(width: 52, height: 30),
                                AppColors.black,
                              ),
                              _buildModeButton(
                                "Heat",
                                Assets.home.images.homeHeat
                                    .image(width: 39, height: 28),
                                AppColors.black,
                              ),
                              _buildModeButton(
                                "Timer",
                                Assets.home.images.homeTime
                                    .image(width: 32, height: 39),
                                AppColors.black,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Banner 贴底
            Assets.home.images.homeBanner.image(
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建功能按钮（带图片 + 文字）
  Widget _buildModeButton(String label, Widget icon, Color color) {
    return Container(
      width: 64,
      height: 145,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(37),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20), // 顶部固定留白，保证上对齐
          SizedBox(
            height: 58, // 图标区域固定高度
            child: Center(child: icon),
          ),
          const Spacer(), // 自动推下文字
          Padding(
            padding: const EdgeInsets.only(bottom: 28), // 底部固定间距
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
