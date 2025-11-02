import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
    final btState = await FlutterBluePlus.adapterState.first;
    bluetoothOn = btState == BluetoothAdapterState.on;

    // 权限状态
    bluetoothGranted = await Permission.bluetooth.isGranted ||
        await Permission.bluetoothScan.isGranted ||
        await Permission.bluetoothConnect.isGranted;

    // Android 12+ 判断
    if (Platform.isAndroid) {
      isAndroid12OrAbove = (await _getAndroidVersion()) >= 12;
    }

    // 定位状态
    locationGranted = await Permission.locationWhenInUse.isGranted;
    final locService = loc.Location();
    locationOn =
        await locService.serviceEnabled() || await locService.requestService();

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

    setState(() {
      scanning = true;
      devices.clear();
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      for (var r in results) {
        if (!devices.contains(r.device)) {
          setState(() {
            devices.add(r.device);
          });
        }
      }
    });

    await Future.delayed(const Duration(seconds: 5));
    await FlutterBluePlus.stopScan();

    setState(() => scanning = false);
  }

  Widget _buildStatusSection() {
    String title = "";
    String desc = "";
    String buttonText = "";
    VoidCallback? onPressed;

    if (!bluetoothGranted) {
      title = "Please enable Bluetooth permission";
      desc = "App needs permission to access Bluetooth hardware.";
      buttonText = "Open Settings";
      onPressed = () => openAppSettings();
    } else if (!bluetoothOn) {
      title = "Please turn on Bluetooth";
      desc = "Your phone’s Bluetooth is turned off. Please turn it on.";
      buttonText = "Turn on";
      onPressed = () async {
        await FlutterBluePlus.turnOn();
        checkStatus();
      };
    } else if (Platform.isAndroid && isAndroid12OrAbove && !nearbyGranted) {
      title = "Please allow access to nearby devices";
      desc = "To search for nearby devices for pairing or connection.";
      buttonText = "Open Settings";
      onPressed = () => openAppSettings();
    } else if (!locationGranted || !locationOn) {
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

    return Column(
      children: [
        const SizedBox(height: 33),
        const Icon(Icons.bluetooth, size: 53, color: Colors.blueAccent),
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
        const SizedBox(height: 27),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            minimumSize: const Size(267, 47),
          ),
          child: Text(buttonText,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildDeviceList() {
    if (!bluetoothOn || !bluetoothGranted || !locationOn || !locationGranted) {
      return const SizedBox.shrink();
    }

    if (scanning) {
      return const Padding(
        padding: EdgeInsets.only(top: 33),
        child: CircularProgressIndicator(),
      );
    }

    if (devices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 33),
        child:
            Text("No devices found", style: TextStyle(color: Colors.black45)),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final device = devices[index];
          return ListTile(
            title: Text(device.platformName.isNotEmpty
                ? device.platformName
                : "Unknown Device"),
            subtitle: Text(device.remoteId.str),
            trailing: ElevatedButton(
              onPressed: () async {
                await device.connect();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text("Connected to ${device.platformName}")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7)),
              ),
              child:
                  const Text("Connect", style: TextStyle(color: Colors.white)),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const BxAppBar(title: "Connect Device"),
      body: Column(
        children: [
          _buildStatusSection(),
          const SizedBox(height: 20),
          _buildDeviceList(),
        ],
      ),
    );
  }
}
