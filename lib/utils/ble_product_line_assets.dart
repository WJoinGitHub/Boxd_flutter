import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';

/// 按蓝牙广播名区分的产品线（与 SKU 文案 B11 / B13 / B14 一致）。
enum BleProductLineKind { b11, b1314OrDefault }

BleProductLineKind bleProductLineKindFromName(String? blePlatformName) {
  final raw = blePlatformName?.trim();
  if (raw == null || raw.isEmpty) {
    return BleProductLineKind.b1314OrDefault;
  }
  final name = raw.toUpperCase();
  if (name.contains('B11')) {
    return BleProductLineKind.b11;
  }
  if (name.contains('B13') || name.contains('B14')) {
    return BleProductLineKind.b1314OrDefault;
  }
  return BleProductLineKind.b1314OrDefault;
}

/// 首页右侧大设备图。
AssetGenImage homeDeviceHeroImageForBleName(String? blePlatformName) {
  switch (bleProductLineKindFromName(blePlatformName)) {
    case BleProductLineKind.b11:
      return Assets.home.images.homeDeviceB11;
    case BleProductLineKind.b1314OrDefault:
      return Assets.home.images.homeDeviceB14;
  }
}

/// 连接流程等处的 `dev_connect_b*` 插图。
AssetGenImage devConnectImageForBleName(String? blePlatformName) {
  switch (bleProductLineKindFromName(blePlatformName)) {
    case BleProductLineKind.b11:
      return Assets.device.images.devConnectB11;
    case BleProductLineKind.b1314OrDefault:
      return Assets.device.images.devConnectB14;
  }
}
