import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/services/ble_service.dart';
import 'package:flutter_boxd_app_flow/services/ble_protocol.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:flutter_boxd_app_flow/widgets/temperature_picker_dialog.dart';
import 'package:flutter_boxd_app_flow/utils/app_storage.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io';

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
  bool remindEnabled = false;
  int selectedHour = 0;
  int selectedMinute = 0;
  final bleService = BleService();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final DeviceCalendarPlugin _calendarPlugin = DeviceCalendarPlugin();

  late final FixedExtentScrollController minutesController;
  late final FixedExtentScrollController hourController;
  late final FixedExtentScrollController minuteController;

  @override
  void initState() {
    super.initState();
    // 初始化时区
    tz_data.initializeTimeZones();

    // 初始化时间：当前时间+加热时长
    final now = DateTime.now();
    final targetTime = now.add(Duration(minutes: minutes));
    selectedHour = targetTime.hour;
    selectedMinute = targetTime.minute;

    minutesController = FixedExtentScrollController(initialItem: minutes - 20);
    hourController = FixedExtentScrollController(initialItem: selectedHour);
    minuteController = FixedExtentScrollController(initialItem: selectedMinute);

    _loadTemperatureUnit();
    _initNotifications();
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

  Future<void> _initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {},
    );

    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  @override
  void dispose() {
    minutesController.dispose();
    hourController.dispose();
    minuteController.dispose();
    super.dispose();
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Select Time',
                style: TextStyle(
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

  Future<void> _scheduleNotification() async {
    final scheduledTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      selectedHour,
      selectedMinute,
    );

    // 如果选择的时间已过，则设置为明天
    final now = DateTime.now();
    final targetDateTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    final targetTime = tz.TZDateTime.from(targetDateTime, tz.local);

    final androidDetails = AndroidNotificationDetails(
      'heat_channel',
      'Heat',
      channelDescription: 'Notifications for heat reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      1,
      'Heat Reminder',
      'Your food will be ready at ${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
      tz.TZDateTime.from(targetTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _saveToCalendar() async {
    final calendarsResult = await _calendarPlugin.retrieveCalendars();
    if (!calendarsResult.isSuccess || calendarsResult.data == null) {
      print('[HEAT] 获取日历失败');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to access calendar')),
        );
      }
      return;
    }

    final calendars = calendarsResult.data!;
    if (calendars.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No calendars available')),
        );
      }
      return;
    }

    // 使用第一个可写日历
    final calendar = calendars.firstWhere(
      (cal) => cal.isReadOnly == false,
      orElse: () => calendars.first,
    );
    final scheduledTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      selectedHour,
      selectedMinute,
    );

    final now = DateTime.now();
    final startDateTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;
    final endDateTime = startDateTime.add(Duration(minutes: minutes));

    final tzStartTime = tz.TZDateTime.from(startDateTime, tz.local);
    final tzEndTime = tz.TZDateTime.from(endDateTime, tz.local);

    final event = Event(
      calendar.id,
      title: 'Heat',
      description:
          'Heat at ${selectedTemperature ?? temperature}°C for $minutes minutes',
      start: tzStartTime,
      end: tzEndTime,
    );

    final createEventResult = await _calendarPlugin.createOrUpdateEvent(event);
    if (createEventResult != null && createEventResult.isSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event saved to calendar')),
      );
    } else {
      final errors = createEventResult?.errors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Failed to save to calendar: ${errors != null ? errors.join(', ') : 'Unknown error'}')),
      );
    }
  }

  /// 获取显示温度（根据单位转换）
  int _getDisplayTemperature() {
    final temp = selectedTemperature ?? temperature;
    if (temperatureUnit == '°F') {
      // 摄氏度转华氏度: F = C * 9/5 + 32
      return (temp * 9 / 5 + 32).round();
    }
    return temp;
  }

  void _sendCommand() async {
    if (selectedTemperature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select temperature')),
      );
      return;
    }

    if (minutes < 20 || minutes > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Heating time must be between 20-50 minutes')),
      );
      return;
    }

    if (!bleService.isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Device not connected. Please connect your device first.')),
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
          const SnackBar(
              content: Text('Failed to send command. Please try again.')),
        );
      }
      return;
    }

    // 命令发送成功后，根据remindEnabled决定处理方式
    try {
      if (remindEnabled) {
        // 保存到日历
        await _saveToCalendar();
      } else {
        // 只做本地通知
        await _scheduleNotification();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Heat started successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('[HEAT] 处理提醒失败: $e');
      // 即使提醒处理失败，命令已发送成功，仍然返回成功
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Heat started, but reminder setup failed')),
        );
        Navigator.of(context).pop();
      }
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
                  // 左侧：Heat图标和标题
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Assets.device.images.devHeat.image(
                        width: 99,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Heating',
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

            // 温度和电量
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final result = await showDialog<int>(
                        context: context,
                        builder: (context) => TemperaturePickerDialog(
                          initialTemperature:
                              selectedTemperature ?? temperature,
                        ),
                      );
                      if (result != null) {
                        setState(() => selectedTemperature = result);
                      }
                    },
                    child: Row(
                      children: [
                        Text(
                          '${_getDisplayTemperature()}  $temperatureUnit',
                          style: const TextStyle(
                              fontSize: 30, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(width: 15),
                        const Text(
                          '±',
                          style: TextStyle(
                              fontSize: 30, fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.battery_charging_full,
                      size: 20, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '$batteryLevel%',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Setting Heat Duration
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Setting Heat Duration',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
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
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF7F8489), width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMinutesPicker(
                        minutes, (v) => setState(() => minutes = v + 20)),
                  ],
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
                  const Text(
                    'Remind',
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

            // 时间选择
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

  Widget _buildMinutesPicker(int value, Function(int) onChanged) {
    return SizedBox(
      width: 120,
      height: 60,
      child: ListWheelScrollView.useDelegate(
        controller: minutesController,
        itemExtent: 40,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            final displayValue = index + 20;
            return Center(
              child: Text(
                displayValue.toString().padLeft(2, '0'),
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.w300),
              ),
            );
          },
          childCount: 31,
        ),
      ),
    );
  }
}
