import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
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
  int heatingHours = 0;
  int heatingMinutes = 30;
  int mealHours = DateTime.now().hour;
  int mealMinutes = DateTime.now().minute;
  int temperature = 0;
  int? selectedTemperature;
  int batteryLevel = 0;
  String temperatureUnit = '°C';
  final bleService = BleService();
  bool isHeating = false;

  late final FixedExtentScrollController heatingHoursController =
      FixedExtentScrollController(initialItem: 0);
  late final FixedExtentScrollController heatingMinutesController =
      FixedExtentScrollController(initialItem: 30);
  late final FixedExtentScrollController mealHoursController =
      FixedExtentScrollController(initialItem: DateTime.now().hour);
  late final FixedExtentScrollController mealMinutesController =
      FixedExtentScrollController(initialItem: DateTime.now().minute);

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
    _loadTemperatureUnit();
    final lastStatus = bleService.lastStatus;
    if (lastStatus != null) {
      if (lastStatus.temperature != null) temperature = lastStatus.temperature!;
      if (lastStatus.batteryLevel != null) {
        final level = lastStatus.batteryLevel!;
        batteryLevel = (level >= 1 && level <= 4) ? level * 25 : level;
      }
    }
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

  Future<void> _loadTemperatureUnit() async {
    final unit = await AppStorage.loadUnit();
    if (mounted) {
      setState(() => temperatureUnit = unit);
    }
  }

  @override
  void dispose() {
    heatingHoursController.dispose();
    heatingMinutesController.dispose();
    mealHoursController.dispose();
    mealMinutesController.dispose();
    super.dispose();
  }

  void _sendCommand() async {
    if (selectedTemperature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select temperature')),
      );
      return;
    }

    final heatingTotalMinutes = heatingHours * 60 + heatingMinutes;

    // 验证不超过5小时（300分钟）
    if (heatingTotalMinutes > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Heating time cannot exceed 5 hours')),
      );
      return;
    }

    // 计算目标时间（加热结束时间）
    final now = DateTime.now();
    final targetTime =
        DateTime(now.year, now.month, now.day, mealHours, mealMinutes);

    // 如果目标时间小于当前时间，说明是第二天
    final actualTargetTime = targetTime.isBefore(now)
        ? targetTime.add(const Duration(days: 1))
        : targetTime;

    // 计算时间差（分钟）
    final diffMinutes = actualTargetTime.difference(now).inMinutes;

    // 验证不超过5小时（300分钟）
    if (diffMinutes > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time cannot exceed 5 hours from now')),
      );
      return;
    }

    if (diffMinutes < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time cannot be earlier than current time')),
      );
      return;
    }

    // 验证：时长 + 现在时间 < 结束时间
    final estimatedEndTime = now.add(Duration(minutes: heatingTotalMinutes));
    if (estimatedEndTime.isAfter(actualTargetTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Heating duration too long, cannot finish before set time')),
      );
      return;
    }

    // 将结束时间转换为总分钟数（从00:00开始计算）
    final mealTimeTotalMinutes = mealHours * 60 + mealMinutes;

    final success = await bleService.setWork(
      mode: WorkMode.timing,
      temperature: selectedTemperature!,
      heatingTime: heatingTotalMinutes,
      mealTime: mealTimeTotalMinutes,
    );

    if (mounted) {
      if (success) {
        setState(() => isHeating = true);
        await _createCalendarReminder();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send command, please try again')),
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
                const SnackBar(content: Text('Calendar permission denied. Please enable it in settings to use reminder feature.')),
              );
            }
            return;
          }
        } catch (e) {
          print('[CALENDAR] 权限请求异常: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Calendar permission denied. Please enable it in settings to use reminder feature.')),
            );
          }
          return;
        }
      }

      print('[CALENDAR] 获取日历列表');
      final calendarsResult = await plugin.retrieveCalendars();
      print('[CALENDAR] 日历数量: ${calendarsResult.data?.length}');
      if (!calendarsResult.isSuccess || calendarsResult.data == null || calendarsResult.data!.isEmpty) {
        print('[CALENDAR] No calendars found');
        return;
      }

      final calendar = calendarsResult.data!.first;
      print('[CALENDAR] 使用日历: ${calendar.name}');
      final now = DateTime.now();
      final mealDateTime = DateTime(now.year, now.month, now.day, mealHours, mealMinutes);
      final actualMealTime = mealDateTime.isBefore(now) ? mealDateTime.add(const Duration(days: 1)) : mealDateTime;
      print('[CALENDAR] 用餐时间: $actualMealTime');

      final tzActualMealTime = tz.TZDateTime.from(actualMealTime, tz.local);
      final tzEndTime = tz.TZDateTime.from(actualMealTime.add(const Duration(minutes: 15)), tz.local);

      final event = Event(
        calendar.id,
        title: 'HotRice - Meal Ready',
        description: 'Your meal will be ready at ${mealHours.toString().padLeft(2, '0')}:${mealMinutes.toString().padLeft(2, '0')}',
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
            const SnackBar(content: Text('Calendar reminder created successfully')),
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
        leftIcon: Assets.common.images.deviceBack.image(
          width: 35,
          height: 35,
          fit: BoxFit.contain,
        ),
        title: "QIMI\nHotRice",
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    final result = await showDialog<int>(
                      context: context,
                      builder: (context) => TemperaturePickerDialog(
                        initialTemperature: selectedTemperature ?? 90,
                      ),
                    );
                    if (result != null) {
                      setState(() => selectedTemperature = result);
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Assets.home.images.devTemperatureF.image(
                        width: 117,
                        fit: BoxFit.contain,
                      ),
                      Positioned(
                        top: 54,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedTemperature?.toString() ?? temperature.toString(),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              temperatureUnit,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Assets.home.images.homeDevice.image(
                      width: 150,
                      fit: BoxFit.contain,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          batteryLevel > 20
                              ? Icons.battery_std
                              : Icons.battery_alert,
                          color:
                              batteryLevel > 20 ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$batteryLevel%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 40),
          if (isHeating)
            Column(
              children: [
                Assets.device.images.devHeat.image(height: 45),
                const SizedBox(height: 8),
                const Text('Delicious food\nis heating up',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.only(left: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child:
                    Text('Setting Heat Time', style: TextStyle(fontSize: 16)),
              ),
            ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                        width: 80,
                        child: Center(
                            child: Text('HOURS',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)))),
                    const SizedBox(width: 40),
                    const SizedBox(
                        width: 80,
                        child: Center(
                            child: Text('MIN',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)))),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFF7F8489), width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTimePicker(
                          heatingHours,
                          (v) => setState(() => heatingHours = v),
                          6,
                          heatingHoursController),
                      const Text(':', style: TextStyle(fontSize: 40)),
                      _buildTimePicker(
                          heatingMinutes,
                          (v) => setState(() => heatingMinutes = v),
                          60,
                          heatingMinutesController),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Padding(
            padding: EdgeInsets.only(left: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Mealtime', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0x33A9E88B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Assets.device.images.devHeat.image(height: 40),
                  const SizedBox(width: 20),
                  _buildSimpleTimePicker(
                      mealHours,
                      (v) => setState(() => mealHours = v),
                      24,
                      mealHoursController),
                  const Text(':', style: TextStyle(fontSize: 32)),
                  _buildSimpleTimePicker(
                      mealMinutes,
                      (v) => setState(() => mealMinutes = v),
                      60,
                      mealMinutesController),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.all(20),
            child: isHeating
                ? Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Center(
                      child: Text('SLIDE TO EAT',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _sendCommand,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                    ),
                    child: const Text('START',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(int value, Function(int) onChanged, int maxCount,
      FixedExtentScrollController controller) {
    return SizedBox(
      width: 80,
      height: 60,
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
          childCount: maxCount,
        ),
      ),
    );
  }

  Widget _buildSimpleTimePicker(int value, Function(int) onChanged,
      int maxCount, FixedExtentScrollController controller) {
    return SizedBox(
      width: 60,
      height: 60,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 30,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            return Center(
              child: Text(
                index.toString().padLeft(2, '0'),
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
              ),
            );
          },
          childCount: maxCount,
        ),
      ),
    );
  }
}
