import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/pages/login/email_login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool connected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      // 点击事件
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          fullscreenDialog: true,
                          pageBuilder: (_, __, ___) => const EmailLoginPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, // 无背景
                      shadowColor: Colors.transparent, // 无阴影
                      elevation: 0, // 去掉立体感
                      padding: EdgeInsets.zero, // 去掉内部留白
                      minimumSize: const Size(40, 40), // 点击区域
                      shape: const CircleBorder(), // 可选，圆形区域
                    ),
                    child: Center(
                      child: Assets.home.images.homeAvatar.image(
                        width: 28, // 图片实际宽度（自定义）
                        height: 32, // 图片实际高度（自定义）
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
                        connected ? "Connected" : "Connect your Lunch box",
                        style: TextStyle(
                          fontSize: connected ? 24 : 15,
                          color: connected ? AppColors.green : Colors.black54,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                  if (!connected)
                    ElevatedButton(
                      onPressed: () {
                        // 点击事件
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            fullscreenDialog: true,
                            pageBuilder: (_, __, ___) => const EmailLoginPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, // 无背景
                        shadowColor: Colors.transparent, // 无阴影
                        elevation: 0, // 去掉立体感
                        padding: EdgeInsets.zero, // 去掉内部留白
                        minimumSize: const Size(35, 32), // 点击区域
                        shape: const CircleBorder(), // 可选，圆形区域
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
              const SizedBox(height: 16),
              // 三个按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildModeButton("Ins", AppColors.orange),
                  _buildModeButton("Heat", AppColors.orange),
                  _buildModeButton("Timer", AppColors.orange),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
