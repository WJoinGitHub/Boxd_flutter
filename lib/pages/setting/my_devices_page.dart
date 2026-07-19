import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/models/device_model.dart';
import 'package:flutter_boxd_app_flow/pages/device/device_connect_page.dart';
import 'package:flutter_boxd_app_flow/services/api_client.dart';
import 'package:flutter_boxd_app_flow/services/ble_service.dart';
import 'package:flutter_boxd_app_flow/services/user_service.dart';
import 'package:flutter_boxd_app_flow/utils/app_storage.dart';
import 'package:flutter_boxd_app_flow/utils/ble_product_line_assets.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:flutter_boxd_app_flow/utils/app_toast.dart';
import 'package:flutter_boxd_app_flow/utils/dialog_button_styles.dart';

class MyDevicesPage extends StatefulWidget {
  const MyDevicesPage({super.key});

  @override
  State<MyDevicesPage> createState() => _MyDevicesPageState();
}

class _MyDevicesPageState extends State<MyDevicesPage> {
  List<DeviceModel> _devices = [];
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
        final raw = result['data'] as List;
        final userId = UserService().currentUser?.id;
        final devices = <DeviceModel>[];

        for (final item in raw) {
          if (item is! Map) continue;
          final m = Map<String, dynamic>.from(item);
          final deviceUuid = m['device_uuid']?.toString();
          String? localName;
          if (userId != null &&
              userId.isNotEmpty &&
              deviceUuid != null &&
              deviceUuid.isNotEmpty) {
            localName = await AppStorage.loadDeviceLocalName(userId, deviceUuid);
            if (localName != null && localName.isEmpty) {
              localName = null;
            }
          }
          devices.add(DeviceModel.fromJson(m, localName: localName));
        }

        if (mounted) {
          setState(() => _devices = devices);
        }
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
    final wasConnected = _isDeviceConnected(deviceUuid);
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
        // 按需求：先解绑成功，再断开蓝牙连接
        if (wasConnected && bleService.isConnected) {
          try {
            await bleService.disconnect();
          } catch (e) {
            print('[MY_DEVICES] 解绑后断开蓝牙失败: $e');
          }
        }

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

  /// 列表图标用蓝牙广播名（与首页 `connectedPlatformName` / 绑定 `device_name` 一致）
  String? _bleNameForDeviceImage(DeviceModel device) {
    if (_isDeviceConnected(device.deviceUuid) && bleService.isConnected) {
      final platformName = bleService.connectedPlatformName?.trim();
      if (platformName != null && platformName.isNotEmpty) {
        return platformName;
      }
    }
    final name = device.deviceName.trim();
    return name.isEmpty ? null : name;
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
                        final deviceUuid = device.deviceUuid;
                        final deviceName = device.listDisplayName();
                        final isConnected = _isDeviceConnected(deviceUuid);
                        final bleName = _bleNameForDeviceImage(device);

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
                            leading: devConnectImageForBleName(
                              bleName,
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                            ),
                            title: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  deviceName,
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
