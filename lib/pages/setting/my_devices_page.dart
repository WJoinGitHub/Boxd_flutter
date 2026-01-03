import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/pages/device/device_connect_page.dart';
import 'package:flutter_boxd_app_flow/services/api_client.dart';
import 'package:flutter_boxd_app_flow/services/ble_service.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';

class MyDevicesPage extends StatefulWidget {
  const MyDevicesPage({super.key});

  @override
  State<MyDevicesPage> createState() => _MyDevicesPageState();
}

class _MyDevicesPageState extends State<MyDevicesPage> {
  List<Map<String, dynamic>> _devices = [];
  bool _loading = false;
  final bleService = BleService();
  Set<String> _connectedDeviceUuids = {};
  bool _deviceListChanged = false; // 标记设备列表是否有变化

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _checkConnectedDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _loading = true);
    try {
      final result = await ApiClient.getDevices(page: 1, pageSize: 100);
      if (result['code'] == 200 && result['data'] != null) {
        setState(() {
          _devices = List<Map<String, dynamic>>.from(result['data']);
        });
      }
    } catch (e) {
      print('[MY_DEVICES] 加载设备列表失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load devices: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _checkConnectedDevices() async {
    try {
      final connectedUuids = <String>{};

      // 只检查BleService的真实连接状态，不依赖系统连接列表
      // 因为系统可能保留多个设备的连接状态，但只有通过BleService连接的才是真正活跃的
      if (bleService.isConnected) {
        try {
          // 从BleService获取当前连接的设备UUID
          final deviceUuid = await bleService.getDeviceUuid();
          if (deviceUuid != null && deviceUuid.isNotEmpty) {
            print('[MY_DEVICES] 当前连接的设备UUID: $deviceUuid');
            connectedUuids.add(deviceUuid);
            // 也添加大写版本
            connectedUuids.add(deviceUuid.toUpperCase());
          }
        } catch (e) {
          print('[MY_DEVICES] 获取设备UUID失败: $e');
        }
      }

      setState(() => _connectedDeviceUuids = connectedUuids);
    } catch (e) {
      print('[MY_DEVICES] 检查连接状态失败: $e');
    }
  }

  Future<void> _unbindDevice(String deviceUuid, String deviceName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unbind Device'),
        content: Text('Are you sure you want to unbind "$deviceName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unbind', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await ApiClient.unbindDevice(deviceUuid);
      if (result['code'] == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Device unbound successfully')),
          );
        }
        // 刷新设备列表
        await _loadDevices();
        await _checkConnectedDevices();
        _deviceListChanged = true; // 标记列表已变化
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result['message'] ?? 'Failed to unbind device')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unbind device: $e')),
        );
      }
    }
  }

  Future<void> _addDevice() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DeviceConnectPage(),
      ),
    );

    // 如果连接成功，刷新列表和连接状态
    if (result == true && mounted) {
      await _loadDevices();
      await _checkConnectedDevices();
      _deviceListChanged = true; // 标记列表已变化
    }
  }

  bool _isDeviceConnected(String deviceUuid) {
    // 检查设备是否在连接列表中
    return _connectedDeviceUuids.contains(deviceUuid) ||
        _connectedDeviceUuids.contains(deviceUuid.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 返回时传递设备列表是否变化的标志
        Navigator.of(context).pop(_deviceListChanged);
        return false; // 阻止默认返回行为，因为我们手动pop了
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: BxAppBar(
        title: 'My Devices',
        rightWidget: IconButton(
          icon: const Icon(Icons.add, color: Colors.black),
          onPressed: _addDevice,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No devices',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _addDevice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add Device'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadDevices();
                    await _checkConnectedDevices();
                    _deviceListChanged = true; // 标记列表已变化
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final deviceUuid = device['device_uuid'] as String? ?? '';
                      final deviceName =
                          device['device_name'] as String? ?? 'Unknown Device';
                      final isConnected = _isDeviceConnected(deviceUuid);

                      return Container(
                        height: 60,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          leading: Assets.device.images.hotRice
                              .image(width: 40, height: 40),
                          title: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Text(
                                deviceName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isConnected)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () =>
                                _unbindDevice(deviceUuid, deviceName),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      ),
    );
  }
}
