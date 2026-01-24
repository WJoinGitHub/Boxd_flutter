import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/services/ble_service.dart';
import 'package:flutter_boxd_app_flow/services/ble_protocol.dart';
import 'package:flutter_boxd_app_flow/utils/app_storage.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
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
  String temperatureUnit = '°C'; // 温度单位

  // 固定值
  static const int temperature = 60; // 60°C（内部存储，发送给设备时使用）
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
    _loadTemperatureUnit();

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

  Future<void> _loadTemperatureUnit() async {
    final unit = await AppStorage.loadUnit();
    if (mounted) {
      setState(() {
        temperatureUnit = unit;
      });
    }
  }

  /// 获取显示的温度（根据单位转换）
  int getDisplayTemperature() {
    if (temperatureUnit == '°F') {
      // 摄氏度转华氏度: F = C * 9/5 + 32
      return (temperature * 9 / 5 + 32).round();
    }
    return temperature;
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
                child: Text(AppLocalizations.of(context).t('confirm'),
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

  Future<void> _saveToCalendar() async {
    final l10n = AppLocalizations.of(context);
    try {
      final permissionsGranted = await _calendarPlugin.requestPermissions();
      if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.t('calendar_permission_denied'))),
          );
        }
        return;
      }

      final calendarsResult = await _calendarPlugin.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.t('failed_to_retrieve_calendars'))),
          );
        }
        return;
      }

      final calendars = calendarsResult.data!;
      if (calendars.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.t('no_calendars_available'))),
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
        description:
            'Keep warm at ${getDisplayTemperature()}$temperatureUnit for $durationHours hours',
        start: tzStartTime,
        end: tzEndTime,
      );

      final createEventResult =
          await _calendarPlugin.createOrUpdateEvent(event);
      if (createEventResult != null && createEventResult.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('saved_to_calendar'))),
        );
      } else if (mounted) {
        final errors = createEventResult?.errors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${l10n.t('failed_to_save_to_calendar')}: ${errors != null ? errors.join(', ') : l10n.t('unknown_error')}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.t('error')}: $e')),
        );
      }
    }
  }

  Future<void> _startKeepWarm() async {
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
      mode: WorkMode.keepWarm,
      temperature: temperature,
      heatingTime: durationHours * 60,
      mealTime: 0,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(success
                ? AppLocalizations.of(context).t('keep_warm_started')
                : AppLocalizations.of(context).t('command_failed'))),
      );
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayTemp = getDisplayTemperature();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BxAppBar(
        title: l10n.t('keep_warm'),
      ),
      body: Column(
        children: [
          // 主要内容区域（垂直居中）
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 图片距离导航栏高度100
                const SizedBox(height: 100),
                // 保温图标（橙色）
                Assets.device.images.devInsSelect.image(
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 60),

                // Temperature 标签和值
                Text(
                  l10n.t('temperature'),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$displayTemp',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      temperatureUnit,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Clock 标签和值
                Text(
                  l10n.t('clock'),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '${durationHours}H',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // 底部 Start 按钮
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _startKeepWarm,
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
