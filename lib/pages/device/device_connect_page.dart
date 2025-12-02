import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/services/ble_service.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    checkStatus();
  }

  Future<void> checkStatus() async {
    // 蓝牙状态
    try {
      final btState = await FlutterBluePlus.adapterState.first.timeout(
        const Duration(seconds: 2),
        onTimeout: () => BluetoothAdapterState.on,
      );
      bluetoothOn = btState == BluetoothAdapterState.on;
    } catch (e) {
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
      final btStatus = await Permission.bluetooth.status;
      bluetoothGranted = btStatus.isGranted || btStatus.isLimited;
      nearbyGranted = true;
      locationGranted = true;
      locationOn = true;
    }

    setState(() {});
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
    if (!bluetoothOn || !bluetoothGranted) return;

    print('[SCAN] 开始扫描设备...');
    setState(() {
      scanning = true;
      devices.clear();
    });

    try {
      // 先检查已连接的设备
      final connectedDevices = await FlutterBluePlus.connectedSystemDevices;
      print('[SCAN] 已连接设备: ${connectedDevices.length} 个');
      for (var device in connectedDevices) {
        if (device.platformName.isNotEmpty && !devices.contains(device)) {
          print('[SCAN] 已连接: ${device.platformName} (${device.remoteId})');
          setState(() {
            devices.add(device);
          });
        }
      }

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      print('[SCAN] 扫描已启动');

      FlutterBluePlus.scanResults.listen((results) {
        print('[SCAN] 收到扫描结果: ${results.length} 个设备');
        for (var r in results) {
          if (!devices.contains(r.device) && r.device.platformName.isNotEmpty) {
            print(
                '[SCAN] 发现设备: ${r.device.platformName} (${r.device.remoteId})');
            setState(() {
              devices.add(r.device);
            });
          }
        }
      });

      await Future.delayed(const Duration(seconds: 5));
      await FlutterBluePlus.stopScan();
      print('[SCAN] 扫描完成，共发现 ${devices.length} 个设备');
    } catch (e) {
      print('[SCAN] 扫描失败: $e');
    }

    setState(() => scanning = false);
  }

  Future<void> connectDevice(BluetoothDevice device) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ConnectDialog(device: device),
    );
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
        title = "Please allow access to nearby devices";
        desc = "To search for nearby devices for pairing or connection.";
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
      title = "Ready to connect";
      desc = "Scanning for nearby devices...";
      buttonText = scanning ? "Scanning..." : "Scan Devices";
      onPressed = scanning ? null : startScan;
    }

    final showBluetoothIcon = bluetoothOn && bluetoothGranted;
    
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showBluetoothIcon)
                const Icon(Icons.bluetooth, size: 53, color: Colors.blueAccent)
              else
                Assets.device.images.devOpenBle.image(height: 200),
              const SizedBox(height: 17),
              Text(title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 7),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 27),
                child: Text(desc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ),
            ],
          ),
        ),
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child:
              Text("No devices found", style: TextStyle(color: Colors.black45)),
        ),
      );
    }

    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return ListTile(
          title: Text(device.platformName.isNotEmpty
              ? device.platformName
              : "Unknown Device"),
          subtitle: Text(device.remoteId.str),
          trailing: ElevatedButton(
            onPressed: () => connectDevice(device),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7)),
            ),
            child:
                const Text("Connect", style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BxAppBar(
        title: "Connect Device",
        rightWidget: const Text('Help', style: TextStyle(color: Color(0xFF00C389), fontSize: 16, fontWeight: FontWeight.w500)),
        onRightPressed: () {},
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

class _ConnectDialog extends StatefulWidget {
  final BluetoothDevice device;
  const _ConnectDialog({required this.device});

  @override
  State<_ConnectDialog> createState() => _ConnectDialogState();
}

class _ConnectDialogState extends State<_ConnectDialog> {
  String status = 'connecting';
  final bleService = BleService();

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      final success = await bleService.connect(widget.device);
      if (mounted) {
        setState(() => status = success ? 'success' : 'failed');
        if (success) {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.of(context).pop(); // 关闭弹窗
            Navigator.of(context).pop(true); // 返回上一页
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => status = 'failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Connect',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Assets.device.images.hotRice.image(height: 120),
            const SizedBox(height: 16),
            Text('HotRice',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black)),
            const SizedBox(height: 24),
            if (status == 'connecting')
              CircularProgressIndicator(color: AppColors.orange)
            else if (status == 'success')
              Icon(Icons.check_circle, size: 48, color: AppColors.orange)
            else
              Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Connect failed. Please try restarting your phone\'s\nBluetooth or power off and then power on the device',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => status = 'connecting');
                      _connect();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(120, 40),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.refresh, size: 18, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Retry',
                            style:
                                TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (status != 'success') bleService.disconnect();
    super.dispose();
  }
}
