import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const String _unitKey = 'temperature_unit';
  static const String _deviceNamePrefix = 'device_name_';

  /// 保存温度单位（"°C" or "°F"）
  static Future<void> saveUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unitKey, unit);
  }

  /// 读取温度单位，默认为 °F
  static Future<String> loadUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_unitKey) ?? '°F';
  }

  /// 保存设备本地名称（与用户ID和设备UUID绑定）
  static Future<void> saveDeviceLocalName(
      String userId, String deviceUuid, String localName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_deviceNamePrefix${userId}_$deviceUuid';
    await prefs.setString(key, localName);
  }

  /// 读取设备本地名称
  static Future<String?> loadDeviceLocalName(
      String userId, String deviceUuid) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_deviceNamePrefix${userId}_$deviceUuid';
    return prefs.getString(key);
  }
}
