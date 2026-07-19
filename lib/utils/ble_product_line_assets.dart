import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';

/// 按蓝牙广播名区分的产品线（与 SKU 文案 B17 / B16 / B15 / B13 / B14 一致）。
enum BleProductLineKind { b17, b16, b15, b1314OrDefault }

BleProductLineKind bleProductLineKindFromName(String? blePlatformName) {
  final raw = blePlatformName?.trim();
  if (raw == null || raw.isEmpty) {
    return BleProductLineKind.b1314OrDefault;
  }
  final name = raw.toUpperCase();
  if (name.contains('B17')) {
    return BleProductLineKind.b17;
  }
  if (name.contains('B16')) {
    return BleProductLineKind.b16;
  }
  if (name.contains('B15')) {
    return BleProductLineKind.b15;
  }
  if (name.contains('B13') || name.contains('B14')) {
    return BleProductLineKind.b1314OrDefault;
  }
  return BleProductLineKind.b1314OrDefault;
}

/// 首页右侧大设备图。
AssetGenImage homeDeviceHeroImageForBleName(String? blePlatformName) {
  switch (bleProductLineKindFromName(blePlatformName)) {
    case BleProductLineKind.b17:
      return Assets.home.images.homeDeviceB17;
    case BleProductLineKind.b16:
      return Assets.home.images.homeDeviceB16;
    case BleProductLineKind.b15:
      return Assets.home.images.homeDeviceB15;
    case BleProductLineKind.b1314OrDefault:
      return Assets.home.images.homeDeviceB14;
  }
}

/// 连接流程等处的 `dev_connect_b*` 插图。
AssetGenImage devConnectImageForBleName(String? blePlatformName) {
  switch (bleProductLineKindFromName(blePlatformName)) {
    case BleProductLineKind.b17:
      return Assets.device.images.devConnectB17;
    case BleProductLineKind.b16:
      return Assets.device.images.devConnectB16;
    case BleProductLineKind.b15:
      return Assets.device.images.devConnectB15;
    case BleProductLineKind.b1314OrDefault:
      return Assets.device.images.devConnectB14;
  }
}
