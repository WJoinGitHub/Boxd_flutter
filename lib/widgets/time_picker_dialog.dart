import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';

/// 时间选择结果
class TimePickerResult {
  final int hour;
  final int minute;

  TimePickerResult({required this.hour, required this.minute});
}

/// 显示时间选择底部弹窗（当前时间+1小时到+6小时）
/// 两个滚轮：一个选小时，一个选分钟；遵守最小/最大时间约束
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

  /// 最小可选时间（当前时间 + 1 小时）
  late final DateTime _minTime;

  /// 最大可选时间（当前时间 + 6 小时）
  late final DateTime _maxTime;

  late List<int> _availableHours;
  List<int> _availableMinutes = [];

  FixedExtentScrollController? _hourController;
  FixedExtentScrollController? _minuteController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _minTime = now.add(const Duration(hours: 1));
    _maxTime = now.add(const Duration(hours: 6));

    _availableHours = _buildAvailableHours();
    _clampInitialSelection();
    _availableMinutes = _buildAvailableMinutesForHour(selectedHour);

    final hourIndex = _availableHours.indexOf(selectedHour);
    final minuteIndex = _availableMinutes.indexOf(selectedMinute);
    _hourController = FixedExtentScrollController(
      initialItem: hourIndex >= 0 ? hourIndex : 0,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: minuteIndex >= 0 ? minuteIndex : 0,
    );
  }

  void _clampInitialSelection() {
    final now = DateTime.now();
    var t = DateTime(
        now.year, now.month, now.day, widget.initialHour, widget.initialMinute);
    if (t.isBefore(now)) t = t.add(const Duration(days: 1));
    if (t.isBefore(_minTime)) {
      selectedHour = _minTime.hour;
      selectedMinute = _minTime.minute;
    } else if (t.isAfter(_maxTime)) {
      selectedHour = _maxTime.hour;
      selectedMinute = _maxTime.minute;
    } else {
      selectedHour = widget.initialHour;
      selectedMinute = widget.initialMinute;
    }
  }

  List<int> _buildAvailableHours() {
    final hours = <int>[];
    final minH = _minTime.hour;
    final maxH = _maxTime.hour;
    final maxIsNextDay =
        _maxTime.isAfter(_minTime) && _maxTime.day != _minTime.day;
    if (!maxIsNextDay) {
      for (int h = minH; h <= maxH; h++) hours.add(h);
    } else {
      for (int h = minH; h <= 23; h++) hours.add(h);
      for (int h = 0; h <= maxH; h++) hours.add(h);
    }
    return hours;
  }

  List<int> _buildAvailableMinutesForHour(int hour) {
    final minutes = <int>[];
    int minM = 0;
    int maxM = 59;
    if (hour == _minTime.hour) {
      minM = _minTime.minute;
    }
    if (hour == _maxTime.hour) {
      maxM = _maxTime.minute;
    }
    for (int i = minM; i <= maxM; i++) {
      minutes.add(i);
    }
    return minutes;
  }

  void _onHourChanged(int index) {
    if (index < 0 || index >= _availableHours.length) return;
    final newHour = _availableHours[index];
    if (newHour == selectedHour) return;
    setState(() {
      selectedHour = newHour;
      _availableMinutes = _buildAvailableMinutesForHour(selectedHour);
      if (!_availableMinutes.contains(selectedMinute)) {
        selectedMinute = _availableMinutes.first;
      }
      _minuteController?.jumpToItem(
        _availableMinutes
            .indexOf(selectedMinute)
            .clamp(0, _availableMinutes.length - 1),
      );
    });
  }

  void _onMinuteChanged(int index) {
    if (index < 0 || index >= _availableMinutes.length) return;
    setState(() {
      selectedMinute = _availableMinutes[index];
    });
  }

  @override
  void dispose() {
    _hourController?.dispose();
    _minuteController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 400,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 滚轮区域：标签(~16) + 间距(4) + 滚轮(200)，选中行中心在 16+4+20 = 40 之上为 16+4+100 = 120
                const double labelHeight = 16;
                const double wheelHeight = 200;
                const double rowHeight = labelHeight + 4 + wheelHeight;
                const double selectedRowCenterFromTop =
                    labelHeight + 4 + wheelHeight / 2;
                const double grayBarHeight = 40;
                final double stackHeight = constraints.maxHeight;
                final double grayTop = (stackHeight - rowHeight) / 2 +
                    selectedRowCenterFromTop -
                    grayBarHeight / 2;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildWheel(
                          controller: _hourController,
                          itemCount: _availableHours.length,
                          onSelectedItemChanged: _onHourChanged,
                          itemBuilder: (index) {
                            if (index < 0 || index >= _availableHours.length)
                              return const SizedBox();
                            final h = _availableHours[index];
                            return Center(
                              child: Text(
                                h.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            );
                          },
                          label: l10n.t('hour'),
                        ),
                        const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: 16, width: 1),
                            SizedBox(
                              height: 200,
                              width: 24,
                              child: Center(
                                child: Text(
                                  ':',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        _buildWheel(
                          controller: _minuteController,
                          itemCount: _availableMinutes.length,
                          onSelectedItemChanged: _onMinuteChanged,
                          itemBuilder: (index) {
                            if (index < 0 || index >= _availableMinutes.length)
                              return const SizedBox();
                            final m = _availableMinutes[index];
                            return Center(
                              child: Text(
                                m.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            );
                          },
                          label: l10n.t('minute'),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      top: grayTop.clamp(0.0, stackHeight - grayBarHeight),
                      height: grayBarHeight,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                TimePickerResult(hour: selectedHour, minute: selectedMinute),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
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

  Widget _buildWheel({
    required FixedExtentScrollController? controller,
    required int itemCount,
    required ValueChanged<int> onSelectedItemChanged,
    required Widget Function(int index) itemBuilder,
    required String label,
  }) {
    if (controller == null || itemCount == 0) {
      return SizedBox(
        width: 100,
        height: 200,
        child: Center(child: Text(label)),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 100,
          height: 200,
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 40,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onSelectedItemChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) => itemBuilder(index),
              childCount: itemCount,
            ),
          ),
        ),
      ],
    );
  }
}
