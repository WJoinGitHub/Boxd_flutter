import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'api_client.dart';
import 'ble_protocol.dart';

class BleService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;

  final _statusController = StreamController<DeviceStatusData>.broadcast();
  Stream<DeviceStatusData> get statusStream => _statusController.stream;

  /// 连接设备
  Future<bool> connect(BluetoothDevice device) async {
    _device = device;
    print('[BLE] 开始连接设备: ${device.platformName} (${device.remoteId})');

    // 检查设备是否已连接
    bool alreadyConnected = false;
    try {
      alreadyConnected = await device.isConnected;
      print('[BLE] 设备已连接: $alreadyConnected');
    } catch (e) {
      print('[BLE] 检查已连接状态失败: $e');
    }

    // 如果未连接，尝试连接设备，最多 3 次
    int connectRetries = 0;
    while (!alreadyConnected && connectRetries < 3) {
      try {
        print('[BLE] 正在连接... (尝试 ${connectRetries + 1}/3)');
        await device.connect(timeout: const Duration(seconds: 30));
        alreadyConnected = true;
        print('[BLE] 连接成功');
      } catch (e) {
        connectRetries++;
        print('[BLE] 连接失败: $e');
        if (connectRetries >= 3) return false;
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    // 发现服务，最多重试 3 次
    List<BluetoothService> services = [];
    int serviceRetries = 0;
    while (services.isEmpty && serviceRetries < 3) {
      try {
        print('[BLE] 开始发现服务... (尝试 ${serviceRetries + 1}/3)');
        services = await device
            .discoverServices()
            .timeout(const Duration(seconds: 30));
      } catch (e) {
        serviceRetries++;
        print('[BLE] 发现服务失败: $e');
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    if (services.isEmpty) {
      print('[BLE] 发现服务失败，无法继续');
      return false;
    }

    print('[BLE] 发现 ${services.length} 个服务');

    // 查找写特征和通知特征
    for (var service in services) {
      final serviceUuid = service.uuid.toString().toUpperCase();
      if (!serviceUuid.contains(BleProtocol.serviceUUID)) continue;

      print('[BLE] 找到目标服务: $serviceUuid');

      for (var characteristic in service.characteristics) {
        final uuid = characteristic.uuid.toString().toUpperCase();
        if (uuid.contains(BleProtocol.writeUUID)) {
          _writeCharacteristic = characteristic;
          print('[BLE] 找到写特征: $uuid');
        } else if (uuid.contains(BleProtocol.notifyUUID)) {
          _notifyCharacteristic = characteristic;
          print('[BLE] 找到通知特征: $uuid');

          // 确保通知成功订阅，最多重试 3 次
          bool notifySet = false;
          int notifyRetries = 0;
          while (!notifySet && notifyRetries < 3) {
            try {
              await characteristic.setNotifyValue(true);
              characteristic.value.listen(_onDataReceived);
              notifySet = true;
              print('[BLE] 通知已开启');
            } catch (e) {
              notifyRetries++;
              print('[BLE] 开启通知失败: $e (尝试 ${notifyRetries}/3)');
              await Future.delayed(const Duration(milliseconds: 500));
            }
          }
        }
      }
    }

    final success =
        _writeCharacteristic != null && _notifyCharacteristic != null;
    print('[BLE] 连接结果: ${success ? "成功" : "失败"} '
        '(写特征: ${_writeCharacteristic != null}, 通知特征: ${_notifyCharacteristic != null})');
    
    if (success) {
      try {
        final result = await ApiClient.bindDevice(device.remoteId.str);
        if (result['code'] == 200) {
          print('[BLE] 设备绑定成功');
        }
      } catch (e) {
        print('[BLE] 设备绑定失败: $e');
      }
    }
    
    return success;
  }

  /// 断开连接
  Future<void> disconnect() async {
    try {
      if (_device != null) {
        print('[BLE] 断开连接...');
        await _device!.disconnect();
        print('[BLE] 已断开');
      }
    } catch (e) {
      print('[BLE] 断开失败: $e');
    } finally {
      _device = null;
      _writeCharacteristic = null;
      _notifyCharacteristic = null;
    }
  }

  /// 发送数据
  Future<void> _write(List<int> data) async {
    if (_writeCharacteristic == null) throw Exception('未连接设备');
    try {
      await _writeCharacteristic!.write(data, withoutResponse: false);
      print('[BLE] 数据已发送: $data');
    } catch (e) {
      print('[BLE] 发送数据失败: $e');
    }
  }

  /// 接收数据
  void _onDataReceived(List<int> data) {
    print('[BLE] 收到数据: $data');
    final status = BleProtocolHelper.parseDeviceStatus(data);
    if (status != null) {
      _statusController.add(status);
    }
  }

  /// 获取设备信息
  Future<void> getDeviceInfo() async {
    await _write(BleProtocolHelper.getDeviceInfoCommand());
  }

  /// 获取设备状态
  Future<void> getDeviceStatus() async {
    await _write(BleProtocolHelper.getDeviceStatusCommand());
  }

  /// 设置工作模式
  Future<void> setWork({
    required WorkMode mode,
    required int temperature,
    required int heatingTime,
    required int mealTime,
  }) async {
    await _write(BleProtocolHelper.setWorkCommand(
      mode: mode,
      temperature: temperature,
      heatingTime: heatingTime,
      mealTime: mealTime,
    ));
  }

  /// 停止设备
  Future<void> stopDevice() async {
    await _write(BleProtocolHelper.stopDeviceCommand());
  }

  /// 获取第一个绑定的设备
  static Future<BluetoothDevice?> getFirstBoundDevice() async {
    try {
      final result = await ApiClient.getDevices(page: 1, pageSize: 1);
      if (result['code'] == 200 && result['data'] != null) {
        final devices = result['data'] as List;
        if (devices.isNotEmpty) {
          final deviceUuid = devices[0]['device_uuid'];
          print('[BLE] 找到绑定设备: $deviceUuid');
          
          final connectedDevices = await FlutterBluePlus.connectedSystemDevices;
          for (var device in connectedDevices) {
            if (device.remoteId.str == deviceUuid) {
              print('[BLE] 设备已连接');
              return device;
            }
          }
          
          print('[BLE] 开始扫描设备...');
          await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
          
          BluetoothDevice? foundDevice;
          final subscription = FlutterBluePlus.scanResults.listen((results) {
            for (var r in results) {
              if (r.device.remoteId.str == deviceUuid) {
                foundDevice = r.device;
                break;
              }
            }
          });
          
          await Future.delayed(const Duration(seconds: 5));
          await FlutterBluePlus.stopScan();
          await subscription.cancel();
          
          return foundDevice;
        }
      }
      print('[BLE] 未找到绑定设备');
      return null;
    } catch (e) {
      print('[BLE] 获取设备失败: $e');
      return null;
    }
  }

  /// 释放资源
  void dispose() {
    _statusController.close();
  }
}
