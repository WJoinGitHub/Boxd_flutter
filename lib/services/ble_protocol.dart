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
  ready(0x00),        // 待机
  keepWarm(0x01),     // 保温
  heating(0x02),     // 加热
  timing(0x03),       // 设定开饭
  stopped(0x01),      // 已停止（兼容旧值）
  starting(0x02),     // 启动中（兼容旧值）
  running(0x03),     // 运行中（兼容旧值）
  paused(0x0A),      // 暂停
  fault(0x05),       // 故障
  disabled(0x06);    // 已禁用

  final int value;
  const DeviceState(this.value);

  static DeviceState fromValue(int value) {
    // 根据协议，状态值0-3对应：待机/保温/加热/设定开饭
    switch (value) {
      case 0x00:
        return DeviceState.ready;
      case 0x01:
        return DeviceState.keepWarm;
      case 0x02:
        return DeviceState.heating;
      case 0x03:
        return DeviceState.timing;
      case 0x0A:
        return DeviceState.paused;
      case 0x05:
        return DeviceState.fault;
      case 0x06:
        return DeviceState.disabled;
      default:
        return DeviceState.ready;
    }
  }

  /// 获取状态的英文描述（用于用户界面显示）
  String get displayName {
    switch (this) {
      case DeviceState.ready:
        return 'Standby';
      case DeviceState.keepWarm:
        return 'Keep Warm';
      case DeviceState.heating:
        return 'Heating';
      case DeviceState.timing:
        return 'Scheduled Meal';
      case DeviceState.stopped:
        return 'Stopped';
      case DeviceState.starting:
        return 'Starting';
      case DeviceState.running:
        return 'Running';
      case DeviceState.paused:
        return 'Paused';
      case DeviceState.fault:
        return 'Fault';
      case DeviceState.disabled:
        return 'Disabled';
    }
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
  final int? heatingTime; // 设定加热时间（分钟）
  final int? remainingHeatingTime; // 剩余加热时间（分钟）
  final int? temperature;
  final int? mealTime; // 开饭时间（从00:00开始的总分钟数）
  final int? batteryLevel;
  final int? chargingState;
  final bool? isLocked; // 按键锁定状态
  final bool? isFahrenheit; // 温度单位：false=摄氏度，true=华氏度
  final int? lockState; // 兼容旧字段
  final int? faultCode;

  DeviceStatusData({
    required this.state,
    this.mode,
    this.countdownSeconds,
    this.heatingTime,
    this.remainingHeatingTime,
    this.temperature,
    this.mealTime,
    this.batteryLevel,
    this.chargingState,
    this.isLocked,
    this.isFahrenheit,
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

  /// 字节转uint16（大端）
  static int bytesToUint16BigEndian(List<int> bytes, int offset) {
    return (bytes[offset] << 8) | bytes[offset + 1];
  }

  /// 获取设备基本信息指令
  static Uint8List getDeviceInfoCommand() {
    return buildPacket(0x50, [0x00]);
  }

  /// 获取广播数据指令
  static Uint8List getBroadcastDataCommand() {
    return buildPacket(0x50, [0x01]);
  }

  /// 获取UUID数据指令（根据协议：0x02, 0x50, 0x02, XX, 0x03）
  static Uint8List getUuidDataCommand([int param = 0x00]) {
    // 根据协议，这个命令格式特殊：没有FCS校验码，直接是 [0x02, 0x50, 0x02, XX, 0x03]
    return Uint8List.fromList(
        [BleProtocol.startCode, 0x50, 0x02, param, BleProtocol.endCode]);
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

  /// 设备开机指令（根据协议：0x02, 0x53, 0x04, XX, 0x03）
  static Uint8List startDeviceCommand() {
    return buildPacket(0x53, [0x04]);
  }

  /// 时间同步指令
  /// [time] 要设置的时间
  /// [temperatureUnit] 温度单位：0x00=摄氏度，0x01=华氏度
  static Uint8List syncTimeCommand(DateTime time,
      {int temperatureUnit = 0x00}) {
    // 根据协议：0x02, 0x40, 0x01, 小时分钟(2字节), 秒(1字节), 温度单位(1字节), 0x00, 0x00, 0x23, 0x03
    // 将时分转换为分钟数，然后转为uint16
    final totalMinutes = time.hour * 60 + time.minute;
    final data = [
      0x01, // 子指令码
      ...uint16ToBytes(totalMinutes), // 总分钟数(小端)
      time.second, // 秒
      temperatureUnit, // 温度单位：0x00为摄氏度，0x01为华氏度
      0x00, 0x00, // 无功能数据
    ];
    return buildPacket(0x40, data);
  }

  /// 计算校验码（根据新协议：从Byte 1到Byte 12的和）
  static int calculateChecksum(List<int> data, int start, int end) {
    int sum = 0;
    for (int i = start; i < end; i++) {
      sum += data[i];
    }
    return sum & 0xFF;
  }

  /// 解析设备状态响应
  /// 支持两种格式：
  /// 1. 15字节完整格式（包含所有详细信息）
  /// 2. 6字节简化格式：Byte 0=起始码, Byte 1=指令码0x51, Byte 2=设备状态, Byte 3-4=数据, Byte 5=结束码
  /// 
  /// 15字节格式：
  /// Byte 0: 起始码 0x02
  /// Byte 1: 指令码 0x51
  /// Byte 2: 设备状态 (0=待机, 1-3=保温/加热/定时开饭, 0x05=故障, 0x06=关机)
  /// Bytes 3-4: 剩余加热时间 (两字节，大端序)
  /// Byte 5: 当前温度
  /// Bytes 6-7: 开饭时间 (两字节，大端序，总分钟数)
  /// Byte 8: 电池电量
  /// Byte 9: 充电状态 (0=未充电, 1=充电中, 2=已充满)
  /// Byte 10: 标志位 (bit0=按键锁定, bit1=温度单位 0=摄氏度, 1=华氏度)
  /// Bytes 11-12: 设定加热时间 (两字节，大端序)
  /// Byte 13: 校验码
  /// Byte 14: 结束码 0x03
  /// 
  /// 6字节简化格式：
  /// Byte 0: 起始码 0x02
  /// Byte 1: 指令码 0x51
  /// Byte 2: 设备状态
  /// Byte 3: 数据1
  /// Byte 4: 数据2
  /// Byte 5: 结束码 0x03
  static DeviceStatusData? parseDeviceStatus(List<int> data) {
    // 检查基本格式：起始码0x02，结束码0x03，指令码0x51
    if (data.length < 3 ||
        data[0] != 0x02 ||
        data[data.length - 1] != 0x03 ||
        data[1] != 0x51) {
      print('[PROTOCOL] 数据格式错误: 长度=${data.length}, 起始=${data[0]}, 结束=${data[data.length - 1]}, 指令=${data.length > 1 ? data[1] : 'N/A'}');
      return null;
    }

    // 处理6字节简化格式
    if (data.length == 6) {
      final stateValue = data[2];
      final state = DeviceState.fromValue(stateValue);
      final data1 = data[3];
      final data2 = data[4];
      
      print('[PROTOCOL] 解析简化格式设备状态: 状态=$stateValue, 数据1=$data1, 数据2=$data2');
      
      // 简化格式只返回基本状态信息，其他字段为null
      return DeviceStatusData(
        state: state,
        // 其他字段在简化格式中不可用，设为null
      );
    }

    // 处理15字节完整格式
    if (data.length != 15) {
      print('[PROTOCOL] 数据长度错误: 期望15字节，实际${data.length}字节');
      return null;
    }

    // 心跳数据不需要校验码匹配，直接解析

    // 解析设备状态
    final stateValue = data[2];
    final state = DeviceState.fromValue(stateValue);

    // 解析剩余加热时间（Bytes 3-4，小端序）
    final remainingHeatingTime = bytesToUint16(data, 3);

    // 解析当前温度（Byte 5）
    final temperature = data[5];

    // 解析开饭时间（Bytes 6-7，大端序，总分钟数）
    final mealTime = bytesToUint16BigEndian(data, 6);

    // 解析电池电量（Byte 8）
    final batteryLevel = data[8];

    // 解析充电状态（Byte 9）
    final chargingState = data[9];

    // 解析标志位（Byte 10）
    final flags = data[10];
    final isLocked = (flags & 0x01) != 0; // bit0: 按键锁定
    final isFahrenheit = (flags & 0x02) != 0; // bit1: 温度单位

    // 解析设定加热时间（Bytes 11-12，大端序）
    final heatingTime = bytesToUint16BigEndian(data, 11);

    print('[PROTOCOL] 解析设备状态: 状态=$stateValue, 剩余加热=$remainingHeatingTime分钟, 温度=$temperature, 开饭时间=$mealTime分钟, 电池=$batteryLevel, 充电=$chargingState, 锁定=$isLocked, 华氏度=$isFahrenheit, 设定加热=$heatingTime分钟');

    return DeviceStatusData(
      state: state,
      remainingHeatingTime: remainingHeatingTime,
      temperature: temperature,
      mealTime: mealTime,
      batteryLevel: batteryLevel,
      chargingState: chargingState,
      isLocked: isLocked,
      isFahrenheit: isFahrenheit,
      lockState: flags, // 兼容旧字段
      heatingTime: heatingTime,
    );
  }
}
