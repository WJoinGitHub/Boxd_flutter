import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/services/ble_service.dart';
import 'package:flutter_boxd_app_flow/services/ble_protocol.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';

class HeatingPage extends StatefulWidget {
  const HeatingPage({super.key});

  @override
  State<HeatingPage> createState() => _HeatingPageState();
}

class _HeatingPageState extends State<HeatingPage> {
  int heatingHours = 0;
  int heatingMinutes = 30;
  int mealHours = 12;
  int mealMinutes = 0;
  final bleService = BleService();
  bool isHeating = false;

  void _sendCommand() async {
    final heatingTotalMinutes = heatingHours * 60 + heatingMinutes;
    final mealTotalMinutes = mealHours * 60 + mealMinutes;

    if (heatingTotalMinutes > 240) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('加热时间不能超过4小时')),
      );
      return;
    }

    if (mealTotalMinutes > 240) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('开饭时间不能超过4小时')),
      );
      return;
    }

    final success = await bleService.setWork(
      mode: WorkMode.heating,
      temperature: 25,
      heatingTime: heatingTotalMinutes,
      mealTime: mealTotalMinutes,
    );

    if (mounted) {
      if (success) {
        setState(() => isHeating = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发送指令失败，请稍后重试')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BxAppBar(
        leftIcon: Assets.common.images.deviceBack.image(
          width: 35,
          height: 35,
          fit: BoxFit.contain,
        ),
        title: "QIMI\nHotRice",
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Assets.home.images.devTemperatureF.image(
                      width: 117,
                      fit: BoxFit.contain,
                    ),
                    Positioned(
                      top: 54,
                      child: const Text(
                        '25',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 40),
                child: Assets.home.images.homeDevice.image(
                  width: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          if (isHeating)
            Column(
              children: [
                Assets.device.images.devHeatWork.image(height: 45),
                const SizedBox(height: 8),
                const Text('Delicious food\nis heating up',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.only(left: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child:
                    Text('Setting Heat Time', style: TextStyle(fontSize: 16)),
              ),
            ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                        width: 80,
                        child: Center(
                            child: Text('HOURS',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)))),
                    const SizedBox(width: 40),
                    const SizedBox(
                        width: 80,
                        child: Center(
                            child: Text('MIN',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)))),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFF7F8489), width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTimePicker(heatingHours,
                          (v) => setState(() => heatingHours = v), 5),
                      const Text(':', style: TextStyle(fontSize: 40)),
                      _buildTimePicker(heatingMinutes,
                          (v) => setState(() => heatingMinutes = v), 60),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Padding(
            padding: EdgeInsets.only(left: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Mealtime', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0x33A9E88B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Assets.device.images.devHeat.image(height: 40),
                  const SizedBox(width: 20),
                  _buildSimpleTimePicker(
                      mealHours, (v) => setState(() => mealHours = v)),
                  const Text(':', style: TextStyle(fontSize: 32)),
                  _buildSimpleTimePicker(
                      mealMinutes, (v) => setState(() => mealMinutes = v)),
                ],
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: _sendCommand,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
              ),
              child: const Text('START',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(int value, Function(int) onChanged, int maxCount) {
    return SizedBox(
      width: 80,
      height: 60,
      child: ListWheelScrollView.useDelegate(
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

  Widget _buildSimpleTimePicker(int value, Function(int) onChanged) {
    return SizedBox(
      width: 60,
      height: 60,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 30,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            return Center(
              child: Text(
                index.toString().padLeft(2, '0'),
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
              ),
            );
          },
          childCount: 60,
        ),
      ),
    );
  }
}
