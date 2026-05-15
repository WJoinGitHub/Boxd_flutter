/// 绑定列表中的设备名与 BLE [BluetoothDevice.platformName] 的匹配程度。
/// [exact]：完全一致（手动切换设备时应优先，避免多台 QIMI 前缀相同连错）
/// [prefix]：仅 QIMI 前两段一致
/// [none]：不匹配
enum BleNameMatchLevel { exact, prefix, none }

/// 返回匹配等级；[boundDeviceName] 为空视为 [BleNameMatchLevel.none]
BleNameMatchLevel bleNameMatchLevel(
  String boundDeviceName,
  String blePlatformName,
) {
  final deviceName = boundDeviceName.trim();
  // 部分机型/固件在 GAP 名末尾带空格，不 trim 会导致无法精确匹配、拖满 15s 与总超时竞态
  final bleName = blePlatformName.trim();
  if (deviceName.isEmpty || bleName.isEmpty) {
    return BleNameMatchLevel.none;
  }
  if (bleName == deviceName) return BleNameMatchLevel.exact;
  if (bleName.startsWith('QIMI-') && deviceName.startsWith('QIMI-')) {
    final blePrefix = bleName.split('-').take(2).join('-');
    final listPrefix = deviceName.split('-').take(2).join('-');
    if (blePrefix == listPrefix) return BleNameMatchLevel.prefix;
  }
  return BleNameMatchLevel.none;
}

/// 是否匹配（精确或前缀均可）
bool bleDeviceNameMatchesBoundListName(
  String boundDeviceName,
  String blePlatformName,
) {
  final level = bleNameMatchLevel(boundDeviceName, blePlatformName);
  return level == BleNameMatchLevel.exact ||
      level == BleNameMatchLevel.prefix;
}
