import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_boxd_app_flow/utils/app_storage.dart';

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
  late int temperature; // 存储的是显示温度（根据单位可能是°C或°F）
  String temperatureUnit = '°C';
  int _celsiusTemperature = 90; // 内部存储的摄氏度值（用于发送给设备）

  @override
  void initState() {
    super.initState();
    _celsiusTemperature = widget.initialTemperature;
    _loadTemperatureUnit();
  }

  Future<void> _loadTemperatureUnit() async {
    final unit = await AppStorage.loadUnit();
    if (mounted) {
      setState(() {
        temperatureUnit = unit;
        // 根据单位转换显示温度
        if (unit == '°F') {
          temperature = _celsiusToFahrenheit(_celsiusTemperature);
        } else {
          temperature = _celsiusTemperature;
        }
      });
    }
  }

  /// 摄氏度转华氏度
  int _celsiusToFahrenheit(int celsius) {
    return ((celsius * 9 / 5) + 32).round();
  }

  /// 华氏度转摄氏度
  int _fahrenheitToCelsius(int fahrenheit) {
    return ((fahrenheit - 32) * 5 / 9).round();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Temperature',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onPanUpdate: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final center = Offset(box.size.width / 2, 200);
                final angle = math.atan2(
                  details.localPosition.dy - center.dy,
                  details.localPosition.dx - center.dx,
                );
                final degrees = (angle * 180 / math.pi + 90) % 360;
                
                // 根据单位设置不同的温度范围
                int temp;
                if (temperatureUnit == '°F') {
                  // 华氏度范围：158-212 (对应70-100°C)
                  temp = (158 + (degrees / 360 * 54)).round();
                  if (temp >= 158 && temp <= 212) {
                    setState(() {
                      temperature = temp;
                      _celsiusTemperature = _fahrenheitToCelsius(temp);
                    });
                  }
                } else {
                  // 摄氏度范围：70-100
                  temp = (70 + (degrees / 360 * 30)).round();
                  if (temp >= 70 && temp <= 100) {
                    setState(() {
                      temperature = temp;
                      _celsiusTemperature = temp;
                    });
                  }
                }
              },
              child: CustomPaint(
                size: const Size(300, 300),
                painter: TemperatureCirclePainter(temperature, temperatureUnit),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _celsiusTemperature),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('Confirm', style: TextStyle(fontSize: 16)),
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
  final String temperatureUnit;

  TemperatureCirclePainter(this.temperature, this.temperatureUnit);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.8;

    // 绘制外圈阴影
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(center, radius + 10, shadowPaint);

    // 绘制黑色背景圆
    final bgPaint = Paint()
      ..color = const Color(0xFF1a1a1a)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // 绘制进度圆弧（橙色到蓝色渐变）
    // 根据单位计算进度角度
    double progress;
    if (temperatureUnit == '°F') {
      // 华氏度范围：158-212，映射到0-1
      progress = (temperature - 158) / (212 - 158);
    } else {
      // 摄氏度范围：70-100，映射到0-1
      progress = (temperature - 70) / (100 - 70);
    }
    progress = progress.clamp(0.0, 1.0);
    final sweepAngle = progress * 2 * math.pi;
    final rect = Rect.fromCircle(center: center, radius: radius + 15);
    
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + sweepAngle,
      colors: [
        const Color(0xFFFF9966),
        const Color(0xFF3366CC),
        const Color(0xFFFF9966),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // 绘制滑块圆点
    final knobAngle = -math.pi / 2 + sweepAngle;
    final knobX = center.dx + (radius + 15) * math.cos(knobAngle);
    final knobY = center.dy + (radius + 15) * math.sin(knobAngle);
    
    final knobPaint = Paint()
      ..color = const Color(0xFF2a2a2a)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(knobX, knobY), 30, knobPaint);
    
    final knobDotPaint = Paint()
      ..color = const Color(0xFFFFAA66)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(knobX, knobY), 8, knobDotPaint);

    // 绘制刻度线
    for (int i = 0; i < 12; i++) {
      final angle = -math.pi / 2 + (i * math.pi / 6);
      final isMainTick = i % 3 == 0;
      final tickLength = isMainTick ? 15.0 : 8.0;
      final tickWidth = isMainTick ? 3.0 : 2.0;
      
      final startX = center.dx + (radius + 25) * math.cos(angle);
      final startY = center.dy + (radius + 25) * math.sin(angle);
      final endX = center.dx + (radius + 25 + tickLength) * math.cos(angle);
      final endY = center.dy + (radius + 25 + tickLength) * math.sin(angle);
      
      final tickPaint = Paint()
        ..color = const Color(0xFFFFAA66)
        ..strokeWidth = tickWidth
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), tickPaint);
    }

    // 绘制温度文字
    final tempTextPainter = TextPainter(
      text: TextSpan(
        text: '$temperature$temperatureUnit',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tempTextPainter.layout();
    tempTextPainter.paint(
      canvas,
      Offset(
        center.dx - tempTextPainter.width / 2,
        center.dy - tempTextPainter.height / 2 - 10,
      ),
    );

    // 绘制"Temperature"文字
    final labelTextPainter = TextPainter(
      text: const TextSpan(
        text: 'Temperature',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w400,
          color: Colors.white70,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelTextPainter.layout();
    labelTextPainter.paint(
      canvas,
      Offset(
        center.dx - labelTextPainter.width / 2,
        center.dy + 20,
      ),
    );
  }

  @override
  bool shouldRepaint(TemperatureCirclePainter oldDelegate) =>
      oldDelegate.temperature != temperature ||
      oldDelegate.temperatureUnit != temperatureUnit;
}
