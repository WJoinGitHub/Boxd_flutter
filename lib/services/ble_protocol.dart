import 'dart:typed_data';

/// 蓝牙协议常量
class BleProtocol {
  static const String serviceUUID = 'FFF0';
  static const String notifyUUID = 'FFF1';
  static const String writeUUID = 'FFF2';

  static const int startCode = 0x02;
  static const int endCode = 0x03;
  static const int maxLength = 20;
}

/// 指令码
class BleCommand {
  static const int getDeviceInfo = 0x50;
  static const int getBroadcastData = 0x50;
  static const int deviceStatus = 0x51;
  static const int setWork = 0x40;
  static const int stopDevice = 0x53;
  static const int syncTime = 0x52;
}

/// 设备状态
enum DeviceState {
  ready(0x00),
  stopped(0x01),
  starting(0x02),
  running(0x03),
  paused(0x0A),
  fault(0x05),
  disabled(0x06);

  final int value;
  const DeviceState(this.value);

  static DeviceState fromValue(int value) {
    return DeviceState.values
        .firstWhere((e) => e.value == value, orElse: () => DeviceState.ready);
  }
}

/// 工作模式
enum WorkMode {
  none(0x00),
  keepWarm(0x01),
  heating(0x02),
  timing(0x03);

  final int value;
  const WorkMode(this.value);

  static WorkMode fromValue(int value) {
    return WorkMode.values
        .firstWhere((e) => e.value == value, orElse: () => WorkMode.none);
  }
}

/// 设备状态数据
class DeviceStatusData {
  final DeviceState state;
  final WorkMode? mode;
  final int? countdownSeconds;
  final int? heatingTime;
  final int? temperature;
  final int? mealTime;
  final int? batteryLevel;
  final int? chargingState;
  final int? lockState;
  final int? faultCode;

  DeviceStatusData({
    required this.state,
    this.mode,
    this.countdownSeconds,
    this.heatingTime,
    this.temperature,
    this.mealTime,
    this.batteryLevel,
    this.chargingState,
    this.lockState,
    this.faultCode,
  });
}

/// 蓝牙协议工具类
class BleProtocolHelper {
  /// 计算FCS校验
  static int calculateFCS(List<int> data) {
    int sum = 0;
    for (int i = 1; i < data.length; i++) {
      sum += data[i];
    }
    return (sum ^ 0x5A) & 0xFF;
  }

  /// 构建数据包
  static Uint8List buildPacket(int command, [List<int>? data]) {
    final List<int> packet = [BleProtocol.startCode, command];
    if (data != null) packet.addAll(data);
    packet.add(calculateFCS(packet));
    packet.add(BleProtocol.endCode);
    return Uint8List.fromList(packet);
  }

  /// 解析数据包
  static List<int>? parsePacket(List<int> data) {
    if (data.isEmpty ||
        data[0] != BleProtocol.startCode ||
        data[data.length - 1] != BleProtocol.endCode) {
      return null;
    }
    final fcs = data[data.length - 2];
    final calculatedFCS = calculateFCS(data.sublist(0, data.length - 2));
    if (fcs != calculatedFCS) return null;
    return data.sublist(1, data.length - 2);
  }

  /// uint16转字节（小端）
  static List<int> uint16ToBytes(int value) {
    return [value & 0xFF, (value >> 8) & 0xFF];
  }

  /// 字节转uint16（小端）
  static int bytesToUint16(List<int> bytes, int offset) {
    return bytes[offset] | (bytes[offset + 1] << 8);
  }

  /// 获取设备基本信息指令
  static Uint8List getDeviceInfoCommand() {
    return buildPacket(0x50, [0x00]);
  }

  /// 获取广播数据指令
  static Uint8List getBroadcastDataCommand() {
    return buildPacket(0x50, [0x01]);
  }

  /// 设备状态同步指令
  static Uint8List getDeviceStatusCommand() {
    return buildPacket(0x51);
  }

  /// 设置饭盒工作指令
  static Uint8List setWorkCommand({
    required WorkMode mode,
    required int temperature,
    required int heatingTime,
    required int mealTime,
  }) {
    final data = [
      0x00,
      mode.value,
      temperature,
      ...uint16ToBytes(heatingTime),
      ...uint16ToBytes(mealTime),
    ];
    return buildPacket(0x40, data);
  }

  /// 设备停止指令
  static Uint8List stopDeviceCommand() {
    return buildPacket(0x53, [0x03]);
  }

  /// 时间同步指令
  static Uint8List syncTimeCommand(DateTime time) {
    // 将时分转换为分钟数，然后转为uint16
    final totalMinutes = time.hour * 60 + time.minute;
    final data = [
      0x01, // 子指令码
      ...uint16ToBytes(totalMinutes), // 总分钟数(小端)
      time.second, // 秒
      0x00, 0x00, 0x00, // 填充字节
    ];
    return buildPacket(0x40, data);
  }

  /// 解析设备状态响应
  static DeviceStatusData? parseDeviceStatus(List<int> data) {
    final parsed = parsePacket(data);
    if (parsed == null || parsed.isEmpty || parsed[0] != 0x51) return null;

    final state = DeviceState.fromValue(parsed[1]);

    switch (state) {
      case DeviceState.ready:
        if (parsed.length < 3) return null;
        return DeviceStatusData(
          state: state,
          mode: WorkMode.fromValue(parsed[2]),
        );

      case DeviceState.starting:
        if (parsed.length < 3) return null;
        return DeviceStatusData(
          state: state,
          countdownSeconds: parsed[2],
        );

      case DeviceState.stopped:
      case DeviceState.running:
      case DeviceState.paused:
        if (parsed.length < 9) return null;
        print('[PROTOCOL] 解析电量: parsed[7]=${parsed[7]}');
        return DeviceStatusData(
          state: state,
          heatingTime: bytesToUint16(parsed, 2),
          temperature: parsed[4],
          mealTime: bytesToUint16(parsed, 5),
          batteryLevel: parsed[7],
          chargingState: parsed[8],
          lockState: parsed.length > 9 ? parsed[9] : null,
        );

      case DeviceState.fault:
        if (parsed.length < 3) return null;
        return DeviceStatusData(
          state: state,
          faultCode: parsed[2],
        );

      case DeviceState.disabled:
        if (parsed.length < 3) return null;
        return DeviceStatusData(
          state: state,
          faultCode: parsed[2],
        );
    }
  }
}
