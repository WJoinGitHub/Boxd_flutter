import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/services/ble_service.dart';
import 'package:flutter_boxd_app_flow/services/ble_protocol.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io';

class KeepWarmPage extends StatefulWidget {
  const KeepWarmPage({super.key});

  @override
  State<KeepWarmPage> createState() => _KeepWarmPageState();
}

class _KeepWarmPageState extends State<KeepWarmPage> {
  final bleService = BleService();
  int batteryLevel = 0;
  bool remindEnabled = false;
  int selectedHour = 0;
  int selectedMinute = 0;

  // 固定值
  static const int temperature = 60; // 60°C
  static const int durationHours = 2; // 2小时

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final DeviceCalendarPlugin _calendarPlugin = DeviceCalendarPlugin();

  late final FixedExtentScrollController hourController;
  late final FixedExtentScrollController minuteController;

  @override
  void initState() {
    super.initState();
    // 初始化时区
    tz_data.initializeTimeZones();

    // 初始化时间：当前时间+2小时
    final now = DateTime.now();
    final targetTime = now.add(const Duration(hours: 2));
    selectedHour = targetTime.hour;
    selectedMinute = targetTime.minute;

    hourController = FixedExtentScrollController(initialItem: selectedHour);
    minuteController = FixedExtentScrollController(initialItem: selectedMinute);

    _initNotifications();
    _loadBatteryLevel();

    bleService.statusStream.listen((status) {
      if (mounted && status.batteryLevel != null) {
        final level = status.batteryLevel!;
        setState(() {
          batteryLevel = (level >= 1 && level <= 4) ? level * 25 : level;
        });
      }
    });
  }

  Future<void> _initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
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

  void _loadBatteryLevel() {
    final lastStatus = bleService.lastStatus;
    if (lastStatus?.batteryLevel != null) {
      final level = lastStatus!.batteryLevel!;
      batteryLevel = (level >= 1 && level <= 4) ? level * 25 : level;
    }
  }

  @override
  void dispose() {
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
                  const Text(':', style: TextStyle(fontSize: 40)),
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
              padding: const EdgeInsets.all(20),
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

  Widget _buildTimePicker(
    int value,
    Function(int) onChanged,
    int maxCount,
    FixedExtentScrollController controller,
  ) {
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
          childCount: maxCount,
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
      'keep_warm_channel',
      'Keep Warm',
      channelDescription: 'Notifications for keep warm reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      0,
      'Keep Warm Reminder',
      'Your food will be ready to keep warm at ${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
      tz.TZDateTime.from(targetTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _saveToCalendar() async {
    try {
      final permissionsGranted = await _calendarPlugin.requestPermissions();
      if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Calendar permission denied')),
          );
        }
        return;
      }

      final calendarsResult = await _calendarPlugin.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to retrieve calendars')),
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
      final endDateTime =
          startDateTime.add(const Duration(hours: durationHours));

      final tzStartTime = tz.TZDateTime.from(startDateTime, tz.local);
      final tzEndTime = tz.TZDateTime.from(endDateTime, tz.local);

      final event = Event(
        calendar.id,
        title: 'Keep Warm',
        description: 'Keep warm at $temperature°C for $durationHours hours',
        start: tzStartTime,
        end: tzEndTime,
      );

      final createEventResult =
          await _calendarPlugin.createOrUpdateEvent(event);
      if (createEventResult != null && createEventResult.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to calendar')),
        );
      } else if (mounted) {
        final errors = createEventResult?.errors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to save to calendar: ${errors != null ? errors.join(', ') : 'Unknown error'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _startKeepWarm() async {
    // 检查设备是否连接
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

    // 发送BLE命令启动保温功能
    // 保温模式：60°C，2小时（120分钟）
    final success = await bleService.setWork(
      mode: WorkMode.keepWarm,
      temperature: temperature,
      heatingTime: durationHours * 60, // 转换为分钟
      mealTime: 0, // 保温模式不需要用餐时间
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
          const SnackBar(content: Text('Keep warm started successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('[KEEP_WARM] 处理提醒失败: $e');
      // 即使提醒处理失败，命令已发送成功，仍然返回成功
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Keep warm started, but reminder setup failed')),
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
        title: 'Keep Warm',
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
                  // 左侧：Ins图标和标题
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Assets.device.images.devIns.image(
                        width: 56,
                        height: 52,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Keep\nWarm',
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
                  Assets.device.images.temperature.image(
                    width: 31,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$temperature °C',
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w400),
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

            // Warming Duration
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Warming Duration',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '$durationHours Hours',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
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
                    onPressed: _startKeepWarm,
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
