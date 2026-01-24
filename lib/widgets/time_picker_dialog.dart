import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';

/// 时间选择结果
class TimePickerResult {
  final int hour;
  final int minute;

  TimePickerResult({required this.hour, required this.minute});
}

/// 显示时间选择底部弹窗（当前时间+1小时到+6小时）
/// 返回选择的时间（小时和分钟）
Future<TimePickerResult?> showRestrictedTimePicker(
  BuildContext context,
  int initialHour,
  int initialMinute,
) async {
  return await showModalBottomSheet<TimePickerResult>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _TimePickerBottomSheet(
      initialHour: initialHour,
      initialMinute: initialMinute,
    ),
  );
}

class _TimePickerBottomSheet extends StatefulWidget {
  final int initialHour;
  final int initialMinute;

  const _TimePickerBottomSheet({
    required this.initialHour,
    required this.initialMinute,
  });

  @override
  State<_TimePickerBottomSheet> createState() => _TimePickerBottomSheetState();
}

class _TimePickerBottomSheetState extends State<_TimePickerBottomSheet> {
  late int selectedHour;
  late int selectedMinute;
  FixedExtentScrollController? _timeController;
  List<Map<String, dynamic>> availableTimes = [];

  @override
  void initState() {
    super.initState();
    selectedHour = widget.initialHour;
    selectedMinute = widget.initialMinute;
    _generateAvailableTimes();
    _initializeController();
  }

  void _generateAvailableTimes() {
    final now = DateTime.now();
    final minTime = now.add(const Duration(hours: 1));
    final maxTime = now.add(const Duration(hours: 6));

    availableTimes = [];
    DateTime currentTime = minTime;
    while (currentTime.isBefore(maxTime) ||
        currentTime.isAtSameMomentAs(maxTime)) {
      final isNextDay = currentTime.day != now.day;
      availableTimes.add({
        'hour': currentTime.hour,
        'minute': currentTime.minute,
        'isNextDay': isNextDay,
        'datetime': currentTime,
      });
      currentTime = currentTime.add(const Duration(minutes: 1));
    }
  }

  void _initializeController() {
    int initialIndex = 0;
    for (int i = 0; i < availableTimes.length; i++) {
      final time = availableTimes[i];
      if (time['hour'] == selectedHour && time['minute'] == selectedMinute) {
        initialIndex = i;
        break;
      }
    }
    _timeController = FixedExtentScrollController(initialItem: initialIndex);
  }

  @override
  void dispose() {
    _timeController?.dispose();
    super.dispose();
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l10n.t('select_time'),
              style: const TextStyle(
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
                      _buildTimePicker(),
                    ],
                  ),
                  // 中间选中行的背景
                  Positioned(
                    top: 48,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 200, // 覆盖时间选择器的宽度
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
              onPressed: () => Navigator.pop(context,
                  TimePickerResult(hour: selectedHour, minute: selectedMinute)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
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

  Widget _buildTimePicker() {
    if (_timeController == null) {
      return const SizedBox(width: 200, height: 200);
    }
    return SizedBox(
      width: 200,
      height: 200,
      child: ListWheelScrollView.useDelegate(
        controller: _timeController!,
        itemExtent: 40,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          if (index >= 0 && index < availableTimes.length) {
            final time = availableTimes[index];
            setState(() {
              selectedHour = time['hour'] as int;
              selectedMinute = time['minute'] as int;
            });
          }
        },
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            if (index >= availableTimes.length) return const SizedBox();
            final time = availableTimes[index];
            final hour = time['hour'] as int;
            final minute = time['minute'] as int;
            final isNextDay = time['isNextDay'] as bool;
            return Center(
              child: Text(
                '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}${isNextDay ? ' (+1)' : ''}',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
              ),
            );
          },
          childCount: availableTimes.length,
        ),
      ),
    );
  }
}
