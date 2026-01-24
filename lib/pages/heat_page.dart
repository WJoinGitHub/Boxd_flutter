import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/services/ble_service.dart';
import 'package:flutter_boxd_app_flow/services/ble_protocol.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:flutter_boxd_app_flow/widgets/temperature_picker_dialog.dart';
import 'package:flutter_boxd_app_flow/widgets/minutes_picker_dialog.dart';
import 'package:flutter_boxd_app_flow/utils/app_storage.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/widgets/reminder_helper.dart';

class HeatPage extends StatefulWidget {
  const HeatPage({super.key});

  @override
  State<HeatPage> createState() => _HeatPageState();
}

class _HeatPageState extends State<HeatPage> {
  int minutes = 30;
  int temperature = 0;
  int? selectedTemperature;
  int batteryLevel = 0;
  String temperatureUnit = '°C';
  final bleService = BleService();
  final ReminderHelper reminderHelper = ReminderHelper();

  @override
  void initState() {
    super.initState();

    // 初始化提醒时间：当前时间+加热时长
    reminderHelper.updateReminderTimeFromDuration(minutes);

    _loadTemperatureUnit();
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

  @override
  void dispose() {
    reminderHelper.dispose();
    super.dispose();
  }

  Future<void> _showMinutesPicker() async {
    final result = await showMinutesPicker(context, minutes);
    if (result != null) {
      setState(() {
        minutes = result;
        // 更新 remind 时间：当前时间 + 新选择的时长
        reminderHelper.updateReminderTimeFromDuration(result);
      });
    }
  }

  /// 获取显示温度（根据单位转换）
  int _getDisplayTemperature() {
    if (selectedTemperature == null) return 0;
    if (temperatureUnit == '°F') {
      // 摄氏度转华氏度: F = C * 9/5 + 32
      return (selectedTemperature! * 9 / 5 + 32).round();
    }
    return selectedTemperature!;
  }

  void _sendCommand() async {
    if (selectedTemperature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context).t('please_select_temperature'))),
      );
      return;
    }

    if (minutes < 15 || minutes > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context).t('heating_time_range'))),
      );
      return;
    }

    if (!bleService.isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context).t('device_not_connected'))),
        );
      }
      return;
    }

    final success = await bleService.setWork(
      mode: WorkMode.heating,
      temperature: selectedTemperature!,
      heatingTime: minutes,
      mealTime: 0,
    );

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).t('command_failed'))),
        );
      }
      return;
    }

    // 命令发送成功后，根据remindEnabled决定处理方式
    if (reminderHelper.remindEnabled) {
      // 只有当开关打开时，才处理提醒相关操作
      try {
        // 保存到日历
        await reminderHelper.createHeatCalendarReminder(
          context,
          temperature: selectedTemperature!,
          minutes: minutes,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context).t('heat_started'))),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        print('[HEAT] 处理提醒失败: $e');
        // 如果是精确闹钟权限错误，静默处理，不显示提示
        if (e is PlatformException && e.code == 'exact_alarms_not_permitted') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(AppLocalizations.of(context).t('heat_started'))),
            );
            Navigator.of(context).pop();
          }
        } else {
          // 其他错误，显示提示
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(l10n.t('heat_started_but_reminder_failed'))),
            );
            Navigator.of(context).pop();
          }
        }
      }
    } else {
      // 开关没打开，不做任何日历相关操作，直接成功返回
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).t('heat_started'))),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayTemp = _getDisplayTemperature();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BxAppBar(
        title: l10n.t('heat_title'),
      ),
      body: Column(
        children: [
          // 主要内容区域
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 图片距离导航栏高度12
                  const SizedBox(height: 12),

                  // 加热图标（橙色）
                  Assets.device.images.devHeatSelect.image(
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 60),

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
                        final initialTemp = selectedTemperature ??
                            (temperature > 0 ? temperature : 90);
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
                                    : '75 - 100 $temperatureUnit',
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
                onPressed: _sendCommand,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
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
    );
  }
}
