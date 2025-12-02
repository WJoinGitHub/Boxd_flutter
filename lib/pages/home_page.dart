import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/pages/device/device_connect_page.dart';
import 'package:flutter_boxd_app_flow/pages/setting/setting_page.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/pages/login/email_login_page.dart';
import 'dart:io';
import 'package:flutter_boxd_app_flow/services/ble_service.dart';
import 'package:flutter_boxd_app_flow/services/ble_protocol.dart';
import 'package:flutter_boxd_app_flow/services/user_service.dart';
import 'package:flutter_boxd_app_flow/services/api_client.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_boxd_app_flow/pages/keep_warm_page.dart';
import 'package:flutter_boxd_app_flow/pages/heating_page.dart';

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
    _init();
  }

  Future<void> _init() async {
    await _autoLogin();
    await _autoConnect();
  }

  Future<void> _autoLogin() async {
    final hasToken = await UserService().loadFromLocal();
    if (hasToken && mounted) {
      setState(() {});
    }
  }

  Future<void> _autoConnect() async {
    print('[HOME] 尝试自动连接...');
    try {
      final result = await ApiClient.getDevices(page: 1, pageSize: 1);
      if (result['code'] == 200 && result['data'] != null) {
        final devices = result['data'] as List;
        if (devices.isNotEmpty) {
          final deviceUuid = devices[0]['device_uuid'];
          print('[HOME] 找到绑定设备: $deviceUuid');

          final connectedDevices = await FlutterBluePlus.connectedSystemDevices;
          BluetoothDevice? targetDevice;

          for (var device in connectedDevices) {
            final currentUuid = Platform.isAndroid
                ? device.remoteId.str.replaceAll(':', '').toUpperCase()
                : device.remoteId.str.replaceAll('-', '').toUpperCase();
            if (currentUuid == deviceUuid) {
              targetDevice = device;
              break;
            }
          }

          if (targetDevice == null) {
            print('[HOME] 开始扫描设备...');
            await FlutterBluePlus.startScan(
                timeout: const Duration(seconds: 5));
            await for (var results in FlutterBluePlus.scanResults) {
              for (var r in results) {
                final currentUuid = Platform.isAndroid
                    ? r.device.remoteId.str.replaceAll(':', '').toUpperCase()
                    : r.device.remoteId.str.replaceAll('-', '').toUpperCase();
                print(
                    '[HOME] 扫描到设备: ${r.device.platformName} UUID: $currentUuid');
                if (currentUuid == deviceUuid) {
                  targetDevice = r.device;
                  break;
                }
              }
              if (targetDevice != null) break;
            }
            await FlutterBluePlus.stopScan();
          }

          if (targetDevice != null && mounted) {
            final success =
                await bleService.connect(targetDevice, skipBind: true);
            if (success && mounted) {
              setState(() => connected = true);
              print('[HOME] 自动连接成功');
            }
          }
        }
      }
    } catch (e) {
      print('[HOME] 自动连接失败: $e');
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
                                      setState(() =>
                                          connected = bleService.isConnected);
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
    return GestureDetector(
      onTap: () async {
        if (!connected) return;

        if (label == "Ins") {
          final success = await bleService.setWork(
            mode: WorkMode.keepWarm,
            temperature: 60,
            heatingTime: 0,
            mealTime: 0,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(success ? '指令发送成功' : '发送指令失败，请稍后重试')),
            );
          }
        } else if (label == "Heat") {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HeatingPage()),
          );
        }
      },
      child: Container(
        width: 64,
        height: 145,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(37),
          border: Border.all(color: color, width: 1),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            SizedBox(
              height: 58,
              child: Center(child: icon),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
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
      ),
    );
  }
}
