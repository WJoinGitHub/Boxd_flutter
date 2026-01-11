import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/pages/device/device_connecting_page.dart';
import 'package:flutter_boxd_app_flow/pages/device/device_help_page.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as loc;
import 'package:device_info_plus/device_info_plus.dart';

class DeviceConnectPage extends StatefulWidget {
  const DeviceConnectPage({super.key});

  @override
  State<DeviceConnectPage> createState() => _DeviceConnectPageState();
}

class _DeviceConnectPageState extends State<DeviceConnectPage> {
  bool bluetoothOn = false;
  bool bluetoothGranted = false;
  bool locationOn = false;
  bool locationGranted = false;
  bool nearbyGranted = false;
  bool isAndroid12OrAbove = false;

  bool scanning = false;
  List<BluetoothDevice> devices = [];
  bool showRetryButton = false;
  bool hasScannedOnce = false;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    checkStatus();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> checkStatus() async {
    print('[SCAN] 开始检查状态...');
    // 蓝牙状态
    try {
      final btState = await FlutterBluePlus.adapterState.first.timeout(
        const Duration(seconds: 2),
        onTimeout: () => BluetoothAdapterState.on,
      );
      bluetoothOn = btState == BluetoothAdapterState.on;
      print('[SCAN] 蓝牙状态: $bluetoothOn');
    } catch (e) {
      print('[SCAN] 检查蓝牙状态失败: $e');
      bluetoothOn = false;
    }

    // Android 12+ 判断
    if (Platform.isAndroid) {
      isAndroid12OrAbove = (await _getAndroidVersion()) >= 12;
    }

    // 权限状态
    if (Platform.isAndroid) {
      if (isAndroid12OrAbove) {
        bluetoothGranted = await Permission.bluetoothScan.isGranted &&
            await Permission.bluetoothConnect.isGranted;
        nearbyGranted = bluetoothGranted;
      } else {
        bluetoothGranted = await Permission.bluetooth.isGranted;
        nearbyGranted = true;
      }
      // 定位状态（仅 Android 需要）
      locationGranted = await Permission.locationWhenInUse.isGranted;
      final locService = loc.Location();
      locationOn = await locService.serviceEnabled();
    } else {
      // iOS 蓝牙权限检查
      // iOS 上蓝牙权限在首次使用时自动请求，不需要通过 permission_handler 检查
      // 只要蓝牙已打开，就认为有权限
      print('[SCAN] iOS 平台，蓝牙已打开即视为有权限');
      bluetoothGranted = bluetoothOn;
      nearbyGranted = true;
      locationGranted = true;
      locationOn = true;
      print('[SCAN] iOS bluetoothGranted: $bluetoothGranted');
    }

    print('[SCAN] 最终状态 - bluetoothOn: $bluetoothOn, bluetoothGranted: $bluetoothGranted, locationOn: $locationOn, locationGranted: $locationGranted');

    if (mounted) {
      setState(() {});
      // 如果所有条件都满足，自动开始扫描
      if (bluetoothOn && bluetoothGranted && (Platform.isIOS || (locationOn && locationGranted))) {
        print('[SCAN] 条件满足，将自动开始扫描');
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) startScan();
        });
      } else {
        print('[SCAN] 条件不满足，不自动扫描');
      }
    }
  }

  Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final version = androidInfo.version.release;
    final major = int.tryParse(version.split(".").first) ?? 0;
    return major;
  }

  Future<void> startScan() async {
    print('[SCAN] startScan 被调用');
    print('[SCAN] bluetoothOn: $bluetoothOn, bluetoothGranted: $bluetoothGranted');
    
    if (!bluetoothOn || !bluetoothGranted) {
      print('[SCAN] 条件不满足，无法扫描');
      return;
    }

    print('[SCAN] 开始扫描设备...');
    if (mounted) {
      setState(() {
        scanning = true;
        devices.clear();
        showRetryButton = false;
      });
    }
    _retryTimer?.cancel();

    try {
      // 先检查已连接的设备
      final connectedDevices = await FlutterBluePlus.connectedSystemDevices;
      print('[SCAN] 已连接设备: ${connectedDevices.length} 个');
      for (var device in connectedDevices) {
        if (device.platformName.isNotEmpty && !devices.contains(device)) {
          print('[SCAN] 已连接: ${device.platformName} (${device.remoteId})');
          if (mounted) {
            setState(() {
              devices.add(device);
            });
          }
        }
      }

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      print('[SCAN] 扫描已启动');

      FlutterBluePlus.scanResults.listen((results) {
        if (!mounted) return;
        print('[SCAN] 收到扫描结果: ${results.length} 个设备');
        for (var r in results) {
          if (!devices.contains(r.device) && r.device.platformName.isNotEmpty) {
            print(
                '[SCAN] 发现设备: ${r.device.platformName} (${r.device.remoteId})');
            if (mounted) {
              setState(() {
                devices.add(r.device);
              });
            }
          }
        }
      });

      await Future.delayed(const Duration(seconds: 5));
      await FlutterBluePlus.stopScan();
      print('[SCAN] 扫描完成，共发现 ${devices.length} 个设备');
    } catch (e) {
      print('[SCAN] 扫描失败: $e');
    }

    if (mounted) {
      setState(() {
        scanning = false;
        hasScannedOnce = true;
      });
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => showRetryButton = true);
      });
    }
  }

  Future<void> connectDevice(BluetoothDevice device) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceConnectingPage(device: device),
      ),
    );
    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    } else if (result == 'retry' && mounted) {
      startScan();
    }
  }

  Widget _buildStatusSection() {
    String title = "";
    String desc = "";
    String buttonText = "";
    VoidCallback? onPressed;

    if (!bluetoothOn) {
      title = "Please turn on Bluetooth";
      desc = "Your phone’s Bluetooth is turned off. Please turn it on.";
      buttonText = "Open Settings";
      onPressed = () => openAppSettings();
    } else if (Platform.isAndroid && !bluetoothGranted) {
      if (isAndroid12OrAbove) {
        title = "Please enable Bluetooth permission";
        desc = "MEDCURSOR needs permission to access the Bluetooth pairing hardware.";
        buttonText = "Grant Permission";
        onPressed = () async {
          await Permission.bluetoothScan.request();
          await Permission.bluetoothConnect.request();
          checkStatus();
        };
      } else {
        title = "Please enable Bluetooth permission";
        desc = "MEDCURSOR needs permission to access the Bluetooth pairing hardware.";
        buttonText = "Grant Permission";
        onPressed = () async {
          await Permission.bluetooth.request();
          checkStatus();
        };
      }
    } else if (Platform.isAndroid && (!locationGranted || !locationOn)) {
      title = "Please turn on Location";
      desc = "To find nearby Bluetooth devices.";
      buttonText = "Turn on";
      onPressed = () async {
        final locService = loc.Location();
        await locService.requestService();
        await Permission.locationWhenInUse.request();
        checkStatus();
      };
    } else {
      title = "Auto-detecting";
      desc = "Nearby devices...";
      buttonText = scanning ? "Scanning..." : "Scan Devices";
      onPressed = scanning ? null : startScan;
    }

    final showBluetoothIcon = bluetoothOn && bluetoothGranted && (Platform.isIOS || (locationOn && locationGranted));
    
    return Column(
      children: [
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 6),
              if (!showBluetoothIcon) ...[
                Text(title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 7),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 27),
                child: Text(desc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ),
              const SizedBox(height: 50),
              if (showBluetoothIcon) ...[
                Center(child: Assets.device.images.devEye.image(height: 133)),
                if (!scanning && hasScannedOnce) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 27),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Assets.device.images.devHelpMsg.image(width: 20, height: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: const TextStyle(fontSize: 12, color: Colors.black),
                              children: [
                                const TextSpan(text: 'Having trouble finding your device. Is it turned on? or Manually add.Or click on '),
                                TextSpan(
                                  text: 'Help',
                                  style: TextStyle(color: Color(0xFFFF7622)),
                                ),
                                const TextSpan(text: ' to troubleshoot andresolve'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showRetryButton) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => showRetryButton = false);
                          startScan();
                        },
                        child: Assets.device.images.devRetry.image(height: 50),
                      ),
                    ),
                  ],
                ],
              ] else
                Center(
                  child: (Platform.isAndroid && (!locationGranted || !locationOn))
                      ? Assets.device.images.devOpenLocation.image(height: 400)
                      : Assets.device.images.devOpenBle.image(height: 400),
                ),
            ],
          ),
        ),
        if (!showBluetoothIcon)
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(double.infinity, 47),
              ),
              child: Text(buttonText,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ),
      ],
    );
  }

  Widget _buildDeviceList() {
    if (!bluetoothOn) {
      return const SizedBox.shrink();
    }
    if (Platform.isAndroid &&
        (!bluetoothGranted || !locationOn || !locationGranted)) {
      return const SizedBox.shrink();
    }

    if (scanning) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (devices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 10, bottom: 10),
          child: Text(
            'Manually adding',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return Container(
                height: 60,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: Assets.device.images.hotRice.image(width: 40, height: 40),
                  title: Text(
                    device.platformName.isNotEmpty
                        ? device.platformName
                        : "Unknown Device",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                  onTap: () => connectDevice(device),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BxAppBar(
        title: bluetoothOn && bluetoothGranted ? "Auto-detecting" : "Connect Device",
        rightWidget: const Text('Help', style: TextStyle(color: Color(0xFFFF7622), fontSize: 16, fontWeight: FontWeight.w500)),
        onRightPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DeviceHelpPage()),
          );
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildStatusSection(),
          ),
          if (bluetoothOn && bluetoothGranted && (Platform.isIOS || (locationOn && locationGranted)))
            Expanded(
              child: _buildDeviceList(),
            ),
        ],
      ),
    );
  }
}


