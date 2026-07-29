import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/services/ble_service.dart';
import 'package:flutter_boxd_app_flow/services/ble_protocol.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:flutter_boxd_app_flow/widgets/temperature_picker_dialog.dart';
import 'package:flutter_boxd_app_flow/widgets/minutes_picker_dialog.dart';
import 'package:flutter_boxd_app_flow/widgets/time_picker_dialog.dart';
import 'package:flutter_boxd_app_flow/utils/app_storage.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/widgets/reminder_helper.dart';
import 'package:flutter_boxd_app_flow/utils/app_toast.dart';

class HeatingTimePage extends StatefulWidget {
  const HeatingTimePage({super.key});

  @override
  State<HeatingTimePage> createState() => _HeatingTimePageState();
}

class _HeatingTimePageState extends State<HeatingTimePage> {
  int minutes = 30; // 加热时长（分钟），15-50分钟
  int mealHours = DateTime.now().hour;
  int mealMinutes = DateTime.now().minute;
  int temperature = 0;
  int? selectedTemperature;
  int batteryLevel = 0;
  String temperatureUnit = '°C';
  int endHour = 0; // 结束时间（小时）
  int endMinute = 0; // 结束时间（分钟）
  final bleService = BleService();
  bool isHeating = false;
  final ReminderHelper reminderHelper = ReminderHelper();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // 初始化时间：当前时间+1小时（最小可选时间）
    final now = DateTime.now();
    final minTime = now.add(const Duration(hours: 1));
    endHour = minTime.hour;
    endMinute = minTime.minute;
    // 初始化提醒时间
    reminderHelper.selectedHour = minTime.hour;
    reminderHelper.selectedMinute = minTime.minute;

    _loadTemperatureUnit();
    _loadSavedHeatingTimeTemperature();
    _loadBatteryLevel();

    bleService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          if (status.temperature != null) {
            temperature = status.temperature!;
          }
          if (status.batteryLevel != null) {
            final level = status.batteryLevel!;
            batteryLevel = (level >= 1 && level <= 4) ? level * 25 : level;
          }
        });
      }
    });
  }

  void _loadBatteryLevel() {
    final lastStatus = bleService.lastStatus;
    if (lastStatus?.batteryLevel != null) {
      final level = lastStatus!.batteryLevel!;
      batteryLevel = (level >= 1 && level <= 4) ? level * 25 : level;
    }
  }

  Future<void> _loadTemperatureUnit() async {
    final unit = await AppStorage.loadUnit();
    if (mounted) {
      setState(() => temperatureUnit = unit);
    }
  }

  /// 从本地读取上次设置过的定时加热温度，有效范围 75-100 摄氏度
  Future<void> _loadSavedHeatingTimeTemperature() async {
    final saved = await AppStorage.loadHeatingTimeTemperature();
    if (mounted && saved != null && saved >= 75 && saved <= 100) {
      setState(() => selectedTemperature = saved);
    }
  }

  @override
  void dispose() {
    reminderHelper.dispose();
    super.dispose();
  }

  /// 获取显示温度（根据单位转换）
  int _getDisplayTemperature() {
    if (selectedTemperature == null) return 0;
    if (temperatureUnit == '°F') {
      return (selectedTemperature! * 9 / 5 + 32).round();
    }
    return selectedTemperature!;
  }

  /// 温度范围 75-100 为摄氏度，华氏度时转换显示
  String _getTemperatureRangeDisplay() {
    if (temperatureUnit == '°F') {
      final lowF = (75 * 9 / 5 + 32).round();
      final highF = (100 * 9 / 5 + 32).round();
      return '$lowF - $highF $temperatureUnit';
    }
    return '75 - 100 $temperatureUnit';
  }

  Future<void> _showMinutesPicker() async {
    final result = await showMinutesPicker(context, minutes);
    if (result != null) {
      setState(() {
        minutes = result;
      });
    }
  }

  Future<void> _showEndTimePicker() async {
    final result = await showRestrictedTimePicker(context, endHour, endMinute);
    if (result != null) {
      setState(() {
        endHour = result.hour;
        endMinute = result.minute;
        // 同步更新 remind 时间
        reminderHelper.selectedHour = result.hour;
        reminderHelper.selectedMinute = result.minute;
      });
    }
  }

  Future<void> _sendCommand() async {
    if (_isSubmitting) return;

    if (selectedTemperature == null) {
      AppToast.show(
        context,
        AppLocalizations.of(context).t('please_select_temperature'),
      );
      return;
    }

    final heatingTotalMinutes = minutes;

    // 验证不超过5小时（300分钟）
    if (heatingTotalMinutes > 300) {
      AppToast.show(
        context,
        AppLocalizations.of(context).t('heating_time_exceed'),
      );
      return;
    }

    // 计算目标时间（开饭时间）
    final now = DateTime.now();
    final targetTime = DateTime(
      now.year,
      now.month,
      now.day,
      reminderHelper.selectedHour,
      reminderHelper.selectedMinute,
    );

    // 如果目标时间小于当前时间，说明是第二天
    final actualTargetTime = targetTime.isBefore(now)
        ? targetTime.add(const Duration(days: 1))
        : targetTime;

    // 计算时间差（分钟）
    final diffMinutes = actualTargetTime.difference(now).inMinutes;

    // 验证不超过5小时（300分钟）
    if (diffMinutes > 300) {
      AppToast.show(
        context,
        AppLocalizations.of(context).t('end_time_exceed'),
      );
      return;
    }

    if (diffMinutes < 0) {
      AppToast.show(
        context,
        AppLocalizations.of(context).t('end_time_past'),
      );
      return;
    }

    // 验证：时长 + 现在时间 < 结束时间
    final estimatedEndTime = now.add(Duration(minutes: heatingTotalMinutes));
    if (estimatedEndTime.isAfter(actualTargetTime)) {
      AppToast.show(
        context,
        AppLocalizations.of(context).t('heating_duration_too_long'),
      );
      return;
    }

    if (!bleService.isConnected) {
      if (mounted) {
        AppToast.show(
          context,
          AppLocalizations.of(context).t('device_not_connected'),
        );
      }
      return;
    }

    // 将结束时间转换为总分钟数（从00:00开始计算）
    final mealTimeTotalMinutes =
        reminderHelper.selectedHour * 60 + reminderHelper.selectedMinute;

    setState(() => _isSubmitting = true);
    try {
      final success = await bleService.setWork(
        mode: WorkMode.timing,
        temperature: selectedTemperature!,
        heatingTime: heatingTotalMinutes,
        mealTime: mealTimeTotalMinutes,
      );

      if (success) {
        await AppStorage.saveHeatingTimeTemperature(selectedTemperature!);
      }

      if (mounted) {
        if (success) {
          setState(() => isHeating = true);
          // 只有当开关打开时，才处理日历相关操作
          if (reminderHelper.remindEnabled) {
            await reminderHelper.createTimingCalendarReminder(context);
          }
          AppToast.show(
            context,
            AppLocalizations.of(context).t('timing_heating_started'),
          );
          Navigator.of(context).pop();
        } else {
          AppToast.show(
            context,
            AppLocalizations.of(context).t('command_failed'),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayTemp = _getDisplayTemperature();

    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: BxAppBar(
        title: l10n.t('timer_mode'),
      ),
      body: AbsorbPointer(
        absorbing: _isSubmitting,
        child: Column(
        children: [
          // 主要内容区域
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 图片距离导航栏高度12
                  const SizedBox(height: 12),

                  // 定时图标（橙色）
                  Assets.device.images.devTimerSelect.image(
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 30),

                  // Setting End Time
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.t('setting_end_time'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 结束时间输入框
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: _showEndTimePicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${endHour.toString().padLeft(2, '0')} : ${endMinute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Setting Heat Duration
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.t('setting_heat_duration'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 加热时长输入框
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: _showMinutesPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${minutes.toString().padLeft(2, '0')} ${l10n.t('minutes')}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Setting Temperature
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.t('setting_temperature'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 温度输入框
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () async {
                        final initialTemp = selectedTemperature ?? 90;
                        final result = await showTemperaturePicker(
                          context,
                          initialTemp,
                        );
                        if (result != null) {
                          setState(() => selectedTemperature = result);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedTemperature != null
                                    ? '$displayTemp $temperatureUnit'
                                    : _getTemperatureRangeDisplay(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Remind组件
                  ReminderWidget(
                    reminderHelper: reminderHelper,
                    onRemindChanged: (value) {
                      setState(() {
                        reminderHelper.remindEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // 底部 Start 按钮
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _sendCommand,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  disabledBackgroundColor: AppColors.orange.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.t('start'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      ),
    ),
    );
  }
}
