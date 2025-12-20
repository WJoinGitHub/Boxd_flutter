import 'package:flutter/material.dart';
import 'dart:math' as math;

class TemperaturePickerDialog extends StatefulWidget {
  final int initialTemperature;

  const TemperaturePickerDialog({
    super.key,
    this.initialTemperature = 90,
  });

  @override
  State<TemperaturePickerDialog> createState() =>
      _TemperaturePickerDialogState();
}

class _TemperaturePickerDialogState extends State<TemperaturePickerDialog> {
  late int temperature;

  @override
  void initState() {
    super.initState();
    temperature = widget.initialTemperature;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Temperature',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onPanUpdate: (details) {
                final center = Offset(150, 150);
                final angle = math.atan2(
                  details.localPosition.dy - center.dy,
                  details.localPosition.dx - center.dx,
                );
                final degrees = (angle * 180 / math.pi + 90) % 360;
                final temp = (degrees / 360 * 100).round();
                if (temp >= 70 && temp <= 100) {
                  setState(() => temperature = temp);
                }
              },
              child: CustomPaint(
                size: const Size(300, 300),
                painter: TemperatureCirclePainter(temperature),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, temperature),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TemperatureCirclePainter extends CustomPainter {
  final int temperature;

  TemperatureCirclePainter(this.temperature);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // 绘制背景圆
    final bgPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;
    canvas.drawCircle(center, radius, bgPaint);

    // 绘制进度圆弧
    final progressPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (temperature / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // 绘制温度文字
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$temperature°C',
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(TemperatureCirclePainter oldDelegate) =>
      oldDelegate.temperature != temperature;
}
