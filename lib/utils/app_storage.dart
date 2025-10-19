import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const String _unitKey = 'temperature_unit';

  /// 保存温度单位（"°C" or "°F"）
  static Future<void> saveUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unitKey, unit);
  }

  /// 读取温度单位，默认为 °C
  static Future<String> loadUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_unitKey) ?? '°C';
  }
}
