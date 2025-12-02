import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/services/ble_service.dart';
import 'package:flutter_boxd_app_flow/services/ble_protocol.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';

class KeepWarmPage extends StatefulWidget {
  const KeepWarmPage({super.key});

  @override
  State<KeepWarmPage> createState() => _KeepWarmPageState();
}

class _KeepWarmPageState extends State<KeepWarmPage> {
  int hours = 2;
  int minutes = 0;
  final bleService = BleService();

  void _sendCommand() async {
    final totalMinutes = hours * 60 + minutes;

    if (totalMinutes > 240) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('时间不能超过4小时')),
      );
      return;
    }

    final success = await bleService.setWork(
      mode: WorkMode.keepWarm,
      temperature: 60,
      heatingTime: totalMinutes,
      mealTime: 0,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '指令发送成功' : '发送指令失败，请稍后重试')),
      );
      if (success) Navigator.pop(context);
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
                        '60',
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
          const Text('Keep Warm Heating ...',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
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
                      _buildTimePicker(
                          hours, (v) => setState(() => hours = v), 5),
                      const Text(':', style: TextStyle(fontSize: 40)),
                      _buildTimePicker(
                          minutes, (v) => setState(() => minutes = v), 60),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: _sendCommand,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
              ),
              child: const Text('SLIDE TO EAT',
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
}
