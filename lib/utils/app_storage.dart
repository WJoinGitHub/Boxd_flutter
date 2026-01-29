import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const String _unitKey = 'temperature_unit';
  static const String _deviceNamePrefix = 'device_name_';
  static const String _heatTemperatureKey = 'heat_temperature';
  static const String _heatingTimeTemperatureKey = 'heating_time_temperature';

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

  /// 保存加热页设置过的温度（摄氏度）
  static Future<void> saveHeatTemperature(int temperature) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_heatTemperatureKey, temperature);
  }

  /// 读取加热页上次设置的温度，无则返回 null
  static Future<int?> loadHeatTemperature() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_heatTemperatureKey);
  }

  /// 保存定时加热页设置过的温度（摄氏度）
  static Future<void> saveHeatingTimeTemperature(int temperature) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_heatingTimeTemperatureKey, temperature);
  }

  /// 读取定时加热页上次设置的温度，无则返回 null
  static Future<int?> loadHeatingTimeTemperature() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_heatingTimeTemperatureKey);
  }
}
