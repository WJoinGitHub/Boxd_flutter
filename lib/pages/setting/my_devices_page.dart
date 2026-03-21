import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/pages/device/device_connect_page.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/services/api_client.dart';
import 'package:flutter_boxd_app_flow/services/ble_service.dart';
import 'package:flutter_boxd_app_flow/services/user_service.dart';
import 'package:flutter_boxd_app_flow/utils/app_storage.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:flutter_boxd_app_flow/utils/app_toast.dart';
import 'package:flutter_boxd_app_flow/utils/dialog_button_styles.dart';

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
        final devices = List<Map<String, dynamic>>.from(result['data']);
        
        // 从本地匹配保存的设备名称
        final userId = UserService().currentUser?.id;
        if (userId != null && userId.isNotEmpty) {
          for (var device in devices) {
            final deviceUuid = device['device_uuid'] as String?;
            if (deviceUuid != null) {
              final localName = await AppStorage.loadDeviceLocalName(userId, deviceUuid);
              if (localName != null && localName.isNotEmpty) {
                device['local_name'] = localName;
              }
            }
          }
        }
        
        setState(() {
          _devices = devices;
        });
      }
    } catch (e) {
      print('[MY_DEVICES] 加载设备列表失败: $e');
      if (mounted) {
        AppToast.show(context, ApiClient.extractErrorMessage(e));
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
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('unbind_device')),
        content: Text('${l10n.t('unbind_device_confirm')} "$deviceName"?'),
        actions: [
          TextButton(
            style: DialogButtonStyles.cancel,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.t('cancel')),
          ),
          TextButton(
            style: DialogButtonStyles.primaryAction,
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.t('unbind')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await ApiClient.unbindDevice(deviceUuid);
      if (result['code'] == 200) {
        if (mounted) {
          AppToast.show(
            context,
            AppLocalizations.of(context).t('device_unbound_successfully'),
          );
        }
        // 刷新设备列表
        await _loadDevices();
        await _checkConnectedDevices();
        _deviceListChanged = true; // 标记列表已变化
      } else {
        if (mounted) {
          AppToast.show(
            context,
            result['message'] ?? l10n.t('failed_to_unbind_device'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, ApiClient.extractErrorMessage(e));
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
    final l10n = AppLocalizations.of(context);
    return WillPopScope(
      onWillPop: () async {
        // 返回时传递设备列表是否变化的标志
        Navigator.of(context).pop(_deviceListChanged);
        return false; // 阻止默认返回行为，因为我们手动pop了
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: BxAppBar(
        title: l10n.t('my_devices'),
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
                      Text(
                        l10n.t('no_devices'),
                        style: const TextStyle(
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
                        child: Text(l10n.t('add_device')),
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
                      // 优先使用本地保存的名称
                      final localName = device['local_name'] as String?;
                      final deviceName = localName ?? (device['device_name'] as String? ?? 'Unknown Device');
                      // 如果有多个设备，添加序列号
                      final displayName = _devices.length > 1
                          ? '$deviceName ${index + 1}'
                          : deviceName;
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
                          title: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isConnected) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.circle,
                                  color: Colors.green,
                                  size: 13,
                                ),
                              ],
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
