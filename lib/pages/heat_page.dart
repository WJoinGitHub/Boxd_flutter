import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
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

  late final FixedExtentScrollController hourController;
  late final FixedExtentScrollController minuteController;
  FixedExtentScrollController? _minutesPickerController;

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
    hourController.dispose();
    minuteController.dispose();
    _minutesPickerController?.dispose();
    super.dispose();
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
                child: Text(
                  AppLocalizations.of(context).t('confirm'),
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
          final newMinutes = index + 20; // 20-50分钟
          setState(() {
            minutes = newMinutes;
            // 更新 remind 时间：当前时间 + 新选择的时长
            final now = DateTime.now();
            final targetTime = now.add(Duration(minutes: newMinutes));
            selectedHour = targetTime.hour;
            selectedMinute = targetTime.minute;
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
                child: Text(AppLocalizations.of(context).t('confirm'),
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

  Future<void> _saveToCalendar() async {
    final l10n = AppLocalizations.of(context);
    final calendarsResult = await _calendarPlugin.retrieveCalendars();
    if (!calendarsResult.isSuccess || calendarsResult.data == null) {
      print('[HEAT] 获取日历失败');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('failed_to_access_calendar'))),
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
        SnackBar(content: Text(l10n.t('event_saved_to_calendar'))),
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
        SnackBar(
            content: Text(
                AppLocalizations.of(context).t('please_select_temperature'))),
      );
      return;
    }

    if (minutes < 20 || minutes > 50) {
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
    if (remindEnabled) {
      // 只有当开关打开时，才处理提醒相关操作
      try {
        // 保存到日历
        await _saveToCalendar();

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
                        width: 60,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFF7F8489), width: 1),
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
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
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
}
