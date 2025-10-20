import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/pages/device/device_connect_page.dart';
import 'package:flutter_boxd_app_flow/pages/setting/setting_page.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/pages/login/email_login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool connected = false;
  int temperature = 29;

  @override
  void initState() {
    super.initState();
    print("HomePage initState start");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
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
                                fontSize: 20,
                                color: AppColors.gray4,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "HotRice",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                fullscreenDialog: true,
                                pageBuilder: (_, __, ___) =>
                                    const SettingsPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(40, 40),
                            shape: const CircleBorder(),
                          ),
                          child: Center(
                            child: Assets.home.images.homeAvatar.image(
                              width: 28,
                              height: 32,
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
                                size: 15,
                              ),
                            const SizedBox(width: 6),
                            Text(
                              connected
                                  ? "Connected"
                                  : "Connect your Lunch box",
                              style: TextStyle(
                                fontSize: connected ? 24 : 15,
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
                            onPressed: () {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) =>
                                      const DeviceConnectPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(35, 32),
                              shape: const CircleBorder(),
                            ),
                            child: Center(
                              child: Assets.home.images.addDevice.image(
                                width: 25,
                                height: 25,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

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
                              width: 140,
                              fit: BoxFit.contain,
                            ),
                            Positioned(
                              top: 65,
                              child: Text(
                                temperature.toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // 右边设备图片
                        Assets.home.images.homeDevice.image(
                          width: 180,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // 三个功能按钮 + banner
                    Column(
                      children: [
                        // 三个功能按钮
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildModeButton(
                              "Ins",
                              Assets.home.images.homeIns
                                  .image(width: 62, height: 36),
                              AppColors.black,
                            ),
                            _buildModeButton(
                              "Heat",
                              Assets.home.images.homeHeat
                                  .image(width: 47, height: 34),
                              AppColors.black,
                            ),
                            _buildModeButton(
                              "Timer",
                              Assets.home.images.homeTime
                                  .image(width: 38, height: 47),
                              AppColors.black,
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // 🔥 新增 banner 图
                        Assets.home.images.homeBanner.image(
                          width: double.infinity,
                          fit: BoxFit.contain,
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
    );
  }

  /// 构建功能按钮（带图片 + 文字）
  Widget _buildModeButton(String label, Widget icon, Color color) {
    return Container(
      width: 70,
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(44),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24), // 顶部固定留白，保证上对齐
          SizedBox(
            height: 70, // 图标区域固定高度
            child: Center(child: icon),
          ),
          const Spacer(), // 自动推下文字
          Padding(
            padding: const EdgeInsets.only(bottom: 34), // 底部固定间距
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
