import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';

/// 显示时长选择底部弹窗（15-50分钟）
/// 返回选择的分钟数
Future<int?> showMinutesPicker(
  BuildContext context,
  int initialMinutes,
) async {
  return await showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _MinutesPickerBottomSheet(
      initialMinutes: initialMinutes,
    ),
  );
}

class _MinutesPickerBottomSheet extends StatefulWidget {
  final int initialMinutes;

  const _MinutesPickerBottomSheet({
    required this.initialMinutes,
  });

  @override
  State<_MinutesPickerBottomSheet> createState() =>
      _MinutesPickerBottomSheetState();
}

class _MinutesPickerBottomSheetState extends State<_MinutesPickerBottomSheet> {
  late int minutes;
  FixedExtentScrollController? _minutesController;

  @override
  void initState() {
    super.initState();
    minutes = widget.initialMinutes.clamp(15, 50);
    _minutesController = FixedExtentScrollController(
      initialItem: minutes - 15, // 15-50分钟，索引从0开始
    );
  }

  @override
  void dispose() {
    _minutesController?.dispose();
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
              l10n.t('select_duration'),
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
                      _buildMinutesPicker(),
                      const SizedBox(width: 8, height: 2),
                      const Text(
                        'MIN',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                  // 中间选中行的背景（覆盖数值和单位）
                  Positioned(
                    top: 50,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 150, // 足够覆盖数值和单位
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
              onPressed: () => Navigator.pop(context, minutes),
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

  Widget _buildMinutesPicker() {
    if (_minutesController == null) {
      return const SizedBox(width: 80, height: 200);
    }
    return SizedBox(
      width: 80,
      height: 200,
      child: ListWheelScrollView.useDelegate(
        controller: _minutesController!,
        itemExtent: 40,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          setState(() {
            minutes = index + 15; // 15-50分钟
          });
        },
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            final displayValue = index + 15;
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
          childCount: 36, // 15-50分钟，共36个值
        ),
      ),
    );
  }
}
