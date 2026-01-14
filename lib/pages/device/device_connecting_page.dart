import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/services/ble_service.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';

class DeviceConnectingPage extends StatefulWidget {
  final BluetoothDevice device;
  
  const DeviceConnectingPage({super.key, required this.device});

  @override
  State<DeviceConnectingPage> createState() => _DeviceConnectingPageState();
}

class _DeviceConnectingPageState extends State<DeviceConnectingPage> {
  String status = 'connecting';
  final bleService = BleService();

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      // 如果已有设备连接，先断开
      if (bleService.isConnected) {
        print('[CONNECT] 断开已连接的设备...');
        await bleService.disconnect();
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      final success = await bleService.connect(widget.device);
      if (mounted) {
        setState(() => status = success ? 'success' : 'failed');
        if (success) {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => status = 'failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BxAppBar(
        title: 'Connect',
        showBack: false,
        rightWidget: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Assets.device.images.hotRice.image(height: 200),
            const SizedBox(height: 40),
            Text(
              widget.device.platformName.isNotEmpty
                  ? widget.device.platformName
                  : 'HeatLink',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 60),
            if (status == 'connecting')
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  color: Color(0xFFFF7622),
                  strokeWidth: 4,
                ),
              )
            else if (status == 'success')
              const Icon(Icons.check, size: 60, color: Color(0xFFFF7622))
            else
              Column(
                children: [
                  const Icon(Icons.close, size: 60, color: Color(0xFFFF7622)),
                  const SizedBox(height: 24),
                  const Text(
                    'Connect failed.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Please try restarting your phone\'s Bluetooth or power off and then power on the device again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop('retry'),
                    child: Assets.device.images.devRetry.image(height: 50),
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
