import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'api_client.dart';
import 'ble_protocol.dart';
import '../utils/app_storage.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  String? _deviceMacAddress;

  final _statusController = StreamController<DeviceStatusData>.broadcast();
  Stream<DeviceStatusData> get statusStream => _statusController.stream;

  DeviceStatusData? _lastStatus;
  DeviceStatusData? get lastStatus => _lastStatus;

  bool get isConnected =>
      _writeCharacteristic != null && _notifyCharacteristic != null;

  Timer? _heartbeatTimer;
  int _missedHeartbeats = 0;
  DateTime? _lastHeartbeatTime;

  Completer<bool>? _commandCompleter;
  int? _pendingCommand;
  int? _pendingSubCommand;

  Completer<String>? _uuidCompleter;

  /// 获取设备 MAC 地址（已废弃，现在使用UUID绑定）
  @Deprecated('使用 getDeviceUuid() 获取设备UUID进行绑定')
  String _getDeviceMacAddress(BluetoothDevice device) {
    if (Platform.isAndroid) {
      return device.remoteId.str.replaceAll(':', '').toUpperCase();
    } else {
      // iOS: 从缓存的 MAC 地址返回，如果没有则使用 remoteId
      return _deviceMacAddress ??
          device.remoteId.str.replaceAll('-', '').toUpperCase();
    }
  }

  /// 连接设备
  Future<bool> connect(BluetoothDevice device, {bool skipBind = false}) async {
    // 在连接新设备前，先停止旧的心跳定时器
    _stopHeartbeatMonitor();

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
      if (!skipBind) {
        // 先创建 UUID completer，以便接收设备主动发送的 UUID 数据
        _uuidCompleter = Completer<String>();
        
        // 等待一下，让设备有机会发送数据
        await Future.delayed(const Duration(milliseconds: 500));
        
        // 获取设备UUID
        print('[BLE] 开始获取设备UUID...');
        final deviceUuid = await getDeviceUuid();

        if (deviceUuid == null || deviceUuid.isEmpty) {
          print('[BLE] 获取设备UUID失败，断开连接');
          await disconnect();
          return false;
        }

        final deviceName = device.platformName.isNotEmpty
            ? device.platformName
            : 'Boxd-${deviceUuid.substring(deviceUuid.length - 4)}';
        print('[BLE] 绑定设备 UUID: $deviceUuid, 名称: $deviceName');

        bool bindSuccess = false;
        for (int i = 0; i < 3; i++) {
          try {
            final result = await ApiClient.bindDevice(
              deviceUuid,
              deviceName: deviceName,
            );
            if (result['code'] == 200) {
              print('[BLE] 设备绑定成功');
              bindSuccess = true;
              break;
            }
          } catch (e) {
            print('[BLE] 设备绑定失败 (尝试 ${i + 1}/3): $e');
            if (i < 2) await Future.delayed(const Duration(seconds: 1));
          }
        }

        if (!bindSuccess) {
          print('[BLE] 设备绑定失败，断开连接');
          await disconnect();
          return false;
        }
      }

      // _startHeartbeatMonitor();
      _startHeartbeatMonitor();
      await syncTime();
      await getDeviceStatus();
    }

    return success;
  }

  /// 断开连接
  Future<void> disconnect() async {
    _stopHeartbeatMonitor();
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

  /// 发送数据并等待响应
  Future<bool> _writeWithResponse(
      List<int> data, int command, int subCommand) async {
    if (_writeCharacteristic == null) throw Exception('未连接设备');

    _commandCompleter = Completer<bool>();
    _pendingCommand = command;
    _pendingSubCommand = subCommand;

    try {
      await _writeCharacteristic!.write(data, withoutResponse: false);
      print('[BLE] 数据已发送: $data');

      return await _commandCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _commandCompleter = null;
          _pendingCommand = null;
          _pendingSubCommand = null;
          return false;
        },
      );
    } catch (e) {
      print('[BLE] 发送数据失败: $e');
      _commandCompleter = null;
      _pendingCommand = null;
      _pendingSubCommand = null;
      return false;
    }
  }

  /// 接收数据
  void _onDataReceived(List<int> data) {
    print('[BLE] 收到数据: $data');
    _lastHeartbeatTime = DateTime.now();
    _missedHeartbeats = 0;

    // 处理UUID数据响应 (0x02, 0x50, 0x02, ...)
    // 协议格式：0x02, 0x50, 0x02, [UUID 11字节], 校验码, 0x03
    // UUID组成：字节3-6(4字节批次随机码) + 字节7-11(5字节递增序号) + 字节12-13(2字节防伪校验码)
    if (data.length >= 16 &&
        data[0] == 0x02 &&
        data[1] == 0x50 &&
        data[2] == 0x02 &&
        data[data.length - 1] == 0x03) {
      // 解析UUID：字节3-11 (共9字节)，每个字节代表一个ASCII字符
      // 字节3-6: 4字节批次随机码（ASCII字符）
      // 字节7-11: 5字节递增序号（ASCII字符）
      if (data.length >= 12) {
        final uuidBytes = data.sublist(3, 12); // 9字节: 索引3到11
        // 将每个字节转换为ASCII字符
        final uuid = String.fromCharCodes(uuidBytes);
        print('[BLE] 解析到UUID: $uuid (长度: ${uuid.length}, 原始字节: $uuidBytes)');
        print('[BLE] UUID字节详情 - 字节3-11: ${data.sublist(3, 12)}');
        
        // 只有当 completer 存在且未完成时才 complete
        if (_uuidCompleter != null && !_uuidCompleter!.isCompleted) {
          _uuidCompleter!.complete(uuid);
          _uuidCompleter = null;
        } else {
          print('[BLE] UUID completer 不存在或已完成，忽略此 UUID 数据');
        }
        return;
      }
    }

    if (data.length >= 5 && data[0] == 0x02 && data[data.length - 1] == 0x03) {
      final command = data[1];
      final subCommand = data[2];
      if (_pendingCommand == command &&
          _pendingSubCommand == subCommand &&
          _commandCompleter != null) {
        final result = data.length >= 4 ? data[3] : 0;
        _commandCompleter!.complete(result == 1);
        _commandCompleter = null;
        _pendingCommand = null;
        _pendingSubCommand = null;
      }
    }

    final status = BleProtocolHelper.parseDeviceStatus(data);
    if (status != null) {
      _lastStatus = status;
      _statusController.add(status);
    }
  }

  /// 启动心跳检测
  void _startHeartbeatMonitor() {
    _heartbeatTimer?.cancel();
    _missedHeartbeats = 0;
    _lastHeartbeatTime = DateTime.now();

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      print('[BLE] 发送心跳指令...');
      try {
        await getDeviceStatus();
      } catch (e) {
        print('[BLE] 心跳指令发送失败: $e');
      }

      if (_lastHeartbeatTime != null) {
        final elapsed =
            DateTime.now().difference(_lastHeartbeatTime!).inSeconds;
        if (elapsed > 30) {
          _missedHeartbeats++;
          print('[BLE] 心跳超时: $_missedHeartbeats/3');

          if (_missedHeartbeats >= 3) {
            print('[BLE] 心跳失败，断开连接...');
            timer.cancel();
            await disconnect();
          }
        }
      }
    });
  }

  /// 停止心跳检测
  void _stopHeartbeatMonitor() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _missedHeartbeats = 0;
    _lastHeartbeatTime = null;
  }

  /// 重新连接
  Future<void> _reconnect() async {
    final device = _device;
    if (device == null) return;

    print('[BLE] 开始重新连接...');
    await disconnect();
    await Future.delayed(const Duration(seconds: 2));
    await connect(device);
  }

  /// 获取设备信息
  Future<void> getDeviceInfo() async {
    final data = BleProtocolHelper.getDeviceInfoCommand();
    await _writeCharacteristic!.write(data, withoutResponse: false);
  }

  /// 获取设备UUID
  Future<String?> getDeviceUuid() async {
    if (_writeCharacteristic == null) throw Exception('未连接设备');

    // 如果 completer 还没有创建，则创建一个
    if (_uuidCompleter == null || _uuidCompleter!.isCompleted) {
      _uuidCompleter = Completer<String>();
    }
    
    // 保存 future 引用，避免在 complete 后访问 null
    final uuidFuture = _uuidCompleter!.future;

    try {
      final data = BleProtocolHelper.getUuidDataCommand();
      await _writeCharacteristic!.write(data, withoutResponse: false);
      print('[BLE] 已发送获取UUID命令: $data');

      final uuid = await uuidFuture.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _uuidCompleter = null;
          throw Exception('获取UUID超时');
        },
      );

      return uuid;
    } catch (e) {
      print('[BLE] 获取UUID失败: $e');
      _uuidCompleter = null;
      return null;
    }
  }

  /// 获取设备状态
  Future<void> getDeviceStatus() async {
    final data = BleProtocolHelper.getDeviceStatusCommand();
    await _writeCharacteristic!.write(data, withoutResponse: false);
  }

  /// 同步时间
  Future<void> syncTime() async {
    final now = DateTime.now();
    // 读取温度单位设置
    final unit = await AppStorage.loadUnit();
    final temperatureUnit = unit == '°F' ? 0x01 : 0x00;
    final data = BleProtocolHelper.syncTimeCommand(now,
        temperatureUnit: temperatureUnit);
    await _writeCharacteristic!.write(data, withoutResponse: false);
    print(
        '[BLE] 时间同步指令已发送: ${now.hour}:${now.minute}:${now.second} (总分钟数: ${now.hour * 60 + now.minute}, 温度单位: $unit)');
    print('[BLE] 时间同步数据: $data');
  }

  /// 设置工作模式
  Future<bool> setWork({
    required WorkMode mode,
    required int temperature,
    required int heatingTime,
    required int mealTime,
  }) async {
    final data = BleProtocolHelper.setWorkCommand(
      mode: mode,
      temperature: temperature,
      heatingTime: heatingTime,
      mealTime: mealTime,
    );
    final success = await _writeWithResponse(data, 0x40, 0x00);

    if (success) {
      await getDeviceStatus();
      _lastHeartbeatTime = DateTime.now();
      print('[BLE] 工作命令发送成功，已更新心跳时间');
    }

    return success;
  }

  /// 停止设备
  Future<bool> stopDevice() async {
    if (_writeCharacteristic == null) return false;

    try {
      final data = BleProtocolHelper.stopDeviceCommand();
      await _writeCharacteristic!.write(data, withoutResponse: false);
      print('[BLE] 关机命令已发送: $data');
      return true;
    } catch (e) {
      print('[BLE] 发送关机命令失败: $e');
      return false;
    }
  }

  /// 开启设备
  Future<bool> startDevice() async {
    if (_writeCharacteristic == null) return false;

    try {
      final data = BleProtocolHelper.startDeviceCommand();
      await _writeCharacteristic!.write(data, withoutResponse: false);
      print('[BLE] 开机命令已发送: $data');
      return true;
    } catch (e) {
      print('[BLE] 发送开机命令失败: $e');
      return false;
    }
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
            final currentUuid = Platform.isAndroid
                ? device.remoteId.str.replaceAll(':', '').toUpperCase()
                : device.remoteId.str.replaceAll('-', '').toUpperCase();
            if (currentUuid == deviceUuid) {
              print('[BLE] 设备已连接');
              return device;
            }
          }

          print('[BLE] 开始扫描设备...');
          await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

          BluetoothDevice? foundDevice;
          final subscription = FlutterBluePlus.scanResults.listen((results) {
            for (var r in results) {
              final currentUuid = Platform.isAndroid
                  ? r.device.remoteId.str.replaceAll(':', '').toUpperCase()
                  : r.device.remoteId.str.replaceAll('-', '').toUpperCase();
              if (currentUuid == deviceUuid) {
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
    _stopHeartbeatMonitor();
    _statusController.close();
  }
}
