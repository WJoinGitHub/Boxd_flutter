import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/services/ble_service.dart';
import 'package:flutter_boxd_app_flow/services/ble_protocol.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:flutter_boxd_app_flow/widgets/temperature_picker_dialog.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_boxd_app_flow/utils/app_storage.dart';

class HeatingTimePage extends StatefulWidget {
  const HeatingTimePage({super.key});

  @override
  State<HeatingTimePage> createState() => _HeatingTimePageState();
}

class _HeatingTimePageState extends State<HeatingTimePage> {
  int minutes = 30; // 加热时长（分钟），20-50分钟
  int mealHours = DateTime.now().hour;
  int mealMinutes = DateTime.now().minute;
  int temperature = 0;
  int? selectedTemperature;
  int batteryLevel = 0;
  String temperatureUnit = '°C';
  bool remindEnabled = false;
  int selectedHour = 0;
  int selectedMinute = 0;
  int endHour = 0; // 结束时间（小时）
  int endMinute = 0; // 结束时间（分钟）
  final bleService = BleService();
  bool isHeating = false;

  late final FixedExtentScrollController hourController;
  late final FixedExtentScrollController minuteController;
  FixedExtentScrollController? _minutesPickerController;
  FixedExtentScrollController? _endHourController;
  FixedExtentScrollController? _endMinuteController;

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();

    // 初始化时间：当前时间+默认时长（minutes）
    final now = DateTime.now();
    final targetTime = now.add(Duration(minutes: minutes));
    selectedHour = targetTime.hour;
    selectedMinute = targetTime.minute;
    endHour = targetTime.hour;
    endMinute = targetTime.minute;

    hourController = FixedExtentScrollController(initialItem: selectedHour);
    minuteController = FixedExtentScrollController(initialItem: selectedMinute);

    _loadTemperatureUnit();
    _loadBatteryLevel();

    bleService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          if (status.temperature != null) temperature = status.temperature!;
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
    hourController.dispose();
    minuteController.dispose();
    _minutesPickerController?.dispose();
    _endHourController?.dispose();
    _endMinuteController?.dispose();
    super.dispose();
  }

  /// 获取显示温度（根据单位转换）
  int _getDisplayTemperature() {
    final temp = selectedTemperature ?? temperature;
    if (temperatureUnit == '°F') {
      return (temp * 9 / 5 + 32).round();
    }
    return temp;
  }

  Future<void> _showMinutesPicker() async {
    // 初始化控制器
    _minutesPickerController?.dispose();
    _minutesPickerController = FixedExtentScrollController(
      initialItem: minutes - 20, // 20-50分钟，索引从0开始
    );

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                AppLocalizations.of(context).t('select_duration'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMinutesPickerInDialog(),
                  const SizedBox(width: 8),
                  const Text(
                    'MIN',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinutesPickerInDialog() {
    if (_minutesPickerController == null) {
      return const SizedBox(width: 80, height: 200);
    }
    return SizedBox(
      width: 80,
      height: 200,
      child: ListWheelScrollView.useDelegate(
        controller: _minutesPickerController!,
        itemExtent: 40,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          setState(() {
            minutes = index + 20; // 20-50分钟
          });
        },
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            final displayValue = index + 20;
            return Center(
              child: Text(
                displayValue.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                ),
              ),
            );
          },
          childCount: 31, // 20-50分钟，共31个值
        ),
      ),
    );
  }

  Future<void> _showEndTimePicker() async {
    // 初始化控制器
    _endHourController?.dispose();
    _endMinuteController?.dispose();
    _endHourController = FixedExtentScrollController(initialItem: endHour);
    _endMinuteController = FixedExtentScrollController(initialItem: endMinute);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                AppLocalizations.of(context).t('select_end_time'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: _endHourController == null || _endMinuteController == null
                  ? const SizedBox.shrink()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildEndTimePicker(
                          endHour,
                          (v) {
                            setState(() {
                              endHour = v;
                              // 同步更新 remind 时间
                              selectedHour = v;
                            });
                          },
                          24,
                          _endHourController!,
                        ),
                        const Text(' : ', style: TextStyle(fontSize: 24)),
                        _buildEndTimePicker(
                          endMinute,
                          (v) {
                            setState(() {
                              endMinute = v;
                              // 同步更新 remind 时间
                              selectedMinute = v;
                            });
                          },
                          60,
                          _endMinuteController!,
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text('Confirm',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndTimePicker(int value, Function(int) onChanged, int max,
      FixedExtentScrollController controller) {
    return SizedBox(
      width: 80,
      height: 200,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 40,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            return Center(
              child: Text(
                index.toString().padLeft(2, '0'),
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.w300),
              ),
            );
          },
          childCount: max,
        ),
      ),
    );
  }

  Future<void> _showTimePicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                AppLocalizations.of(context).t('select_time'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimePicker(
                    selectedHour,
                    (v) => setState(() => selectedHour = v),
                    24,
                    hourController,
                  ),
                  const Text(' : ', style: TextStyle(fontSize: 24)),
                  _buildTimePicker(
                    selectedMinute,
                    (v) => setState(() => selectedMinute = v),
                    60,
                    minuteController,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text('Confirm',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(int value, Function(int) onChanged, int max,
      FixedExtentScrollController controller) {
    return SizedBox(
      width: 80,
      height: 200,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 40,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            return Center(
              child: Text(
                index.toString().padLeft(2, '0'),
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.w300),
              ),
            );
          },
          childCount: max,
        ),
      ),
    );
  }

  void _sendCommand() async {
    if (selectedTemperature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('please_select_temperature'))),
      );
      return;
    }

    final heatingTotalMinutes = minutes;

    // 验证不超过5小时（300分钟）
    if (heatingTotalMinutes > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('heating_time_exceed'))),
      );
      return;
    }

    // 计算目标时间（开饭时间）
    final now = DateTime.now();
    final targetTime =
        DateTime(now.year, now.month, now.day, selectedHour, selectedMinute);

    // 如果目标时间小于当前时间，说明是第二天
    final actualTargetTime = targetTime.isBefore(now)
        ? targetTime.add(const Duration(days: 1))
        : targetTime;

    // 计算时间差（分钟）
    final diffMinutes = actualTargetTime.difference(now).inMinutes;

    // 验证不超过5小时（300分钟）
    if (diffMinutes > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).t('end_time_exceed'))),
      );
      return;
    }

    if (diffMinutes < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).t('end_time_past'))),
      );
      return;
    }

    // 验证：时长 + 现在时间 < 结束时间
    final estimatedEndTime = now.add(Duration(minutes: heatingTotalMinutes));
    if (estimatedEndTime.isAfter(actualTargetTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context).t('heating_duration_too_long'))),
      );
      return;
    }

    // 将结束时间转换为总分钟数（从00:00开始计算）
    final mealTimeTotalMinutes = selectedHour * 60 + selectedMinute;

    final success = await bleService.setWork(
      mode: WorkMode.timing,
      temperature: selectedTemperature!,
      heatingTime: heatingTotalMinutes,
      mealTime: mealTimeTotalMinutes,
    );

    if (mounted) {
      if (success) {
        setState(() => isHeating = true);
        // 只有当开关打开时，才处理日历相关操作
        if (remindEnabled) {
          await _createCalendarReminder();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).t('timing_heating_started'))),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).t('command_failed'))),
        );
      }
    }
  }

  Future<void> _createCalendarReminder() async {
    print('[CALENDAR] 开始创建日历提醒');
    try {
      final plugin = DeviceCalendarPlugin();
      print('[CALENDAR] 检查日历权限');
      final permissionGranted = await plugin.hasPermissions();
      print('[CALENDAR] 权限检查结果: ${permissionGranted.data}');

      if (permissionGranted.isSuccess && !permissionGranted.data!) {
        print('[CALENDAR] 请求日历权限');
        try {
          final result = await plugin.requestPermissions();
          print('[CALENDAR] 权限请求结果: ${result.data}');
          if (!result.isSuccess || !result.data!) {
            print('[CALENDAR] Permission denied');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Calendar permission denied. Please enable it in settings to use reminder feature.')),
              );
            }
            return;
          }
        } catch (e) {
          print('[CALENDAR] 权限请求异常: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Calendar permission denied. Please enable it in settings to use reminder feature.')),
            );
          }
          return;
        }
      }

      print('[CALENDAR] 获取日历列表');
      final calendarsResult = await plugin.retrieveCalendars();
      print('[CALENDAR] 日历数量: ${calendarsResult.data?.length}');
      if (!calendarsResult.isSuccess ||
          calendarsResult.data == null ||
          calendarsResult.data!.isEmpty) {
        print('[CALENDAR] No calendars found');
        return;
      }

      final calendar = calendarsResult.data!.first;
      print('[CALENDAR] 使用日历: ${calendar.name}');
      final now = DateTime.now();
      final mealDateTime =
          DateTime(now.year, now.month, now.day, selectedHour, selectedMinute);
      final actualMealTime = mealDateTime.isBefore(now)
          ? mealDateTime.add(const Duration(days: 1))
          : mealDateTime;
      print('[CALENDAR] 用餐时间: $actualMealTime');

      final tzActualMealTime = tz.TZDateTime.from(actualMealTime, tz.local);
      final tzEndTime = tz.TZDateTime.from(
          actualMealTime.add(const Duration(minutes: 15)), tz.local);

      final event = Event(
        calendar.id,
        title: 'HotRice - Meal Ready',
        description:
            'Your meal will be ready at ${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
        start: tzActualMealTime,
        end: tzEndTime,
      );

      event.reminders = [Reminder(minutes: 0)];

      print('[CALENDAR] 创建日历事件');
      final createResult = await plugin.createOrUpdateEvent(event);
      print('[CALENDAR] 创建结果: ${createResult?.isSuccess}');
      if (createResult?.isSuccess == true) {
        print('[CALENDAR] Reminder created successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Calendar reminder created successfully')),
          );
        }
      }
    } catch (e) {
      print('[CALENDAR] Failed to create reminder: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BxAppBar(
        title: '',
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部：图标和标题
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧：Timer图标和标题
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Assets.device.images.devHeatTime.image(
                        width: 60,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Timer',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // 右侧：设备图片
                  Assets.device.images.hotRice.image(
                    width: 150,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),

            // Setting Temperature
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                AppLocalizations.of(context).t('setting_temperature'),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
              ),
            ),
            const SizedBox(height: 10),

            // 温度
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF7F8489), width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_getDisplayTemperature()}  $temperatureUnit',
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Setting Heat Duration
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                AppLocalizations.of(context).t('setting_heat_duration'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: Text(
                  'MIN',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: _showMinutesPicker,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFF7F8489), width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        minutes.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Setting end time
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                AppLocalizations.of(context).t('setting_end_time'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 80,
                    child: Center(
                      child: Text(
                        'HOURS',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                  const SizedBox(
                    width: 80,
                    child: Center(
                      child: Text(
                        'MIN',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: _showEndTimePicker,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFF7F8489), width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        endHour.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const Text(':', style: TextStyle(fontSize: 40)),
                      Text(
                        endMinute.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Remind开关
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Assets.device.images.remainBell.image(
                    width: 33,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).t('remind'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Switch(
                    value: remindEnabled,
                    onChanged: (value) {
                      setState(() => remindEnabled = value);
                    },
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 时间选择（如果Remind开启）
            if (remindEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0x20A9E88B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Assets.device.images.devHeatTime.image(
                        width: 71,
                        fit: BoxFit.contain,
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _showTimePicker,
                        child: Text(
                          '${selectedHour.toString().padLeft(2, '0')} : ${selectedMinute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 40),

            // Start按钮（靠右，屏幕宽的2/3）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                    onPressed: _sendCommand,
                    icon: Assets.device.images.btnStart.image(
                      width: MediaQuery.of(context).size.width * 1 / 2,
                      fit: BoxFit.contain,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
