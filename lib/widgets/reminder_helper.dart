import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/widgets/time_picker_dialog.dart';

/// 提醒功能管理类
class ReminderHelper {
  bool remindEnabled = false;
  int selectedHour = 0;
  int selectedMinute = 0;
  late final FixedExtentScrollController hourController;
  late final FixedExtentScrollController minuteController;
  final DeviceCalendarPlugin _calendarPlugin = DeviceCalendarPlugin();

  ReminderHelper() {
    tz_data.initializeTimeZones();
    // 初始化时间：当前时间+1小时
    final now = DateTime.now();
    final targetTime = now.add(const Duration(hours: 1));
    selectedHour = targetTime.hour;
    selectedMinute = targetTime.minute;
    hourController = FixedExtentScrollController(initialItem: selectedHour);
    minuteController = FixedExtentScrollController(initialItem: selectedMinute);
  }

  void dispose() {
    hourController.dispose();
    minuteController.dispose();
  }

  /// 更新提醒时间（当加热时长变化时调用）
  void updateReminderTimeFromDuration(int minutes) {
    final now = DateTime.now();
    final targetTime = now.add(Duration(minutes: minutes));
    selectedHour = targetTime.hour;
    selectedMinute = targetTime.minute;
    hourController.jumpToItem(selectedHour);
    minuteController.jumpToItem(selectedMinute);
  }

  /// 显示时间选择器
  Future<void> showTimePicker(BuildContext context) async {
    final result = await showRestrictedTimePicker(
      context,
      selectedHour,
      selectedMinute,
    );
    if (result != null) {
      selectedHour = result.hour;
      selectedMinute = result.minute;
      hourController.jumpToItem(selectedHour);
      minuteController.jumpToItem(selectedMinute);
    }
  }

  /// 创建日历提醒（用于加热模式）
  Future<bool> createHeatCalendarReminder(
    BuildContext context, {
    required int temperature,
    required int minutes,
  }) async {
    final l10n = AppLocalizations.of(context);
    try {
      final calendarsResult = await _calendarPlugin.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.t('failed_to_access_calendar'))),
          );
        }
        return false;
      }

      final calendars = calendarsResult.data!;
      if (calendars.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.t('no_calendars_available'))),
          );
        }
        return false;
      }

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
        description: 'Heat at $temperature°C for $minutes minutes',
        start: tzStartTime,
        end: tzEndTime,
      );

      final createEventResult = await _calendarPlugin.createOrUpdateEvent(event);
      if (createEventResult != null && createEventResult.isSuccess) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.t('event_saved_to_calendar'))),
          );
        }
        return true;
      } else {
        final errors = createEventResult?.errors;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to save to calendar: ${errors != null ? errors.join(', ') : 'Unknown error'}',
              ),
            ),
          );
        }
        return false;
      }
    } catch (e) {
      print('[REMINDER] Failed to create calendar reminder: $e');
      return false;
    }
  }

  /// 创建日历提醒（用于定时加热模式）
  Future<bool> createTimingCalendarReminder(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      final permissionGranted = await _calendarPlugin.hasPermissions();
      if (permissionGranted.isSuccess && !permissionGranted.data!) {
        try {
          final result = await _calendarPlugin.requestPermissions();
          if (!result.isSuccess || !result.data!) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.t('calendar_permission_denied_detail')),
                ),
              );
            }
            return false;
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.t('calendar_permission_denied_detail')),
              ),
            );
          }
          return false;
        }
      }

      final calendarsResult = await _calendarPlugin.retrieveCalendars();
      if (!calendarsResult.isSuccess ||
          calendarsResult.data == null ||
          calendarsResult.data!.isEmpty) {
        return false;
      }

      final calendar = calendarsResult.data!.first;
      final now = DateTime.now();
      final mealDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedHour,
        selectedMinute,
      );
      final actualMealTime = mealDateTime.isBefore(now)
          ? mealDateTime.add(const Duration(days: 1))
          : mealDateTime;

      final tzActualMealTime = tz.TZDateTime.from(actualMealTime, tz.local);
      final tzEndTime = tz.TZDateTime.from(
        actualMealTime.add(const Duration(minutes: 15)),
        tz.local,
      );

      final event = Event(
        calendar.id,
        title: 'HeatLink - Meal Ready',
        description:
            'Your meal will be ready at ${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
        start: tzActualMealTime,
        end: tzEndTime,
      );

      event.reminders = [Reminder(minutes: 0)];

      final createResult = await _calendarPlugin.createOrUpdateEvent(event);
      if (createResult?.isSuccess == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.t('calendar_reminder_created_successfully')),
            ),
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      print('[REMINDER] Failed to create calendar reminder: $e');
      return false;
    }
  }
}

/// 提醒UI组件
class ReminderWidget extends StatelessWidget {
  final ReminderHelper reminderHelper;
  final ValueChanged<bool> onRemindChanged;
  final VoidCallback? onTimeTapped;

  const ReminderWidget({
    super.key,
    required this.reminderHelper,
    required this.onRemindChanged,
    this.onTimeTapped,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        // Remind开关
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Assets.device.images.remainBell.image(
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.t('remind'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Switch(
                value: reminderHelper.remindEnabled,
                onChanged: onRemindChanged,
                activeColor: AppColors.orange,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // 时间选择（绿色背景容器）
        if (reminderHelper.remindEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // dev_heat_time 图片
                  Assets.device.images.devHeatTime.image(
                    width: 71,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onTimeTapped ??
                        () => reminderHelper.showTimePicker(context),
                    child: Text(
                      '${reminderHelper.selectedHour.toString().padLeft(2, '0')} : ${reminderHelper.selectedMinute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
