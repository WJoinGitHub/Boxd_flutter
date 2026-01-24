import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/utils/app_storage.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';

/// 显示温度选择底部弹窗
/// 返回选择的温度值（摄氏度）
Future<int?> showTemperaturePicker(
  BuildContext context,
  int initialTemperature,
) async {
  return await showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _TemperaturePickerBottomSheet(
      initialTemperature: initialTemperature,
    ),
  );
}

class _TemperaturePickerBottomSheet extends StatefulWidget {
  final int initialTemperature;

  const _TemperaturePickerBottomSheet({
    required this.initialTemperature,
  });

  @override
  State<_TemperaturePickerBottomSheet> createState() =>
      _TemperaturePickerBottomSheetState();
}

class _TemperaturePickerBottomSheetState
    extends State<_TemperaturePickerBottomSheet> {
  late int temperature; // 存储的是显示温度（根据单位可能是°C或°F）
  String temperatureUnit = '°C';
  int _celsiusTemperature = 90; // 内部存储的摄氏度值（用于发送给设备）
  FixedExtentScrollController? _temperatureController;

  @override
  void initState() {
    super.initState();
    // 确保初始温度在有效范围内（70-100°C）
    _celsiusTemperature = widget.initialTemperature.clamp(70, 100);
    // 同步初始化 temperature，避免异步加载时未初始化
    temperature = _celsiusTemperature;
    // 先初始化控制器（使用默认单位°C）
    _temperatureController = FixedExtentScrollController(
      initialItem: temperature - 70, // 摄氏度：70-100，索引从0开始
    );
    _loadTemperatureUnit();
  }

  @override
  void dispose() {
    _temperatureController?.dispose();
    super.dispose();
  }

  Future<void> _loadTemperatureUnit() async {
    final unit = await AppStorage.loadUnit();
    if (mounted) {
      setState(() {
        temperatureUnit = unit;
        // 确保摄氏度在有效范围内
        _celsiusTemperature = _celsiusTemperature.clamp(70, 100);
        // 根据单位转换显示温度
        if (unit == '°F') {
          temperature = _celsiusToFahrenheit(_celsiusTemperature);
          // 确保华氏度在有效范围内
          temperature = temperature.clamp(158, 212);
        } else {
          temperature = _celsiusTemperature;
        }
        // 更新控制器，设置当前选中项
        _temperatureController?.dispose();
        _temperatureController = FixedExtentScrollController(
          initialItem: unit == '°F'
              ? temperature - 158 // 华氏度：158-212，索引从0开始
              : temperature - 70, // 摄氏度：70-100，索引从0开始
        );
      });
    }
  }

  /// 摄氏度转华氏度
  int _celsiusToFahrenheit(int celsius) {
    return ((celsius * 9 / 5) + 32).round();
  }

  /// 华氏度转摄氏度
  int _fahrenheitToCelsius(int fahrenheit) {
    return ((fahrenheit - 32) * 5 / 9).round();
  }

  /// 获取温度范围
  int get _minTemperature => temperatureUnit == '°F' ? 158 : 70;
  int get _maxTemperature => temperatureUnit == '°F' ? 212 : 100;
  int get _temperatureCount =>
      _maxTemperature - _minTemperature + 1; // 31个值（70-100或158-212）

  /// 根据索引获取温度值
  int _getTemperatureFromIndex(int index) {
    return _minTemperature + index;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Select Temperature',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 200,
              child: Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTemperaturePicker(),
                      const SizedBox(width: 8),
                      Text(
                        temperatureUnit,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                  // 中间选中行的背景（覆盖数值和单位）
                  Positioned(
                    top: 50,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 140, // 足够覆盖数值和单位
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _celsiusTemperature),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                minimumSize: const Size(double.infinity, 44),
              ),
              child: Text(
                l10n.t('confirm'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperaturePicker() {
    if (_temperatureController == null) {
      return const SizedBox(width: 80, height: 200);
    }
    return SizedBox(
      width: 80,
      height: 200,
      child: ListWheelScrollView.useDelegate(
        controller: _temperatureController!,
        itemExtent: 40,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          final newTemp = _getTemperatureFromIndex(index);
          setState(() {
            temperature = newTemp;
            if (temperatureUnit == '°F') {
              _celsiusTemperature = _fahrenheitToCelsius(newTemp);
            } else {
              _celsiusTemperature = newTemp;
            }
          });
        },
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            final temp = _getTemperatureFromIndex(index);
            return Center(
              child: Text(
                temp.toString(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                ),
              ),
            );
          },
          childCount: _temperatureCount,
        ),
      ),
    );
  }
}
