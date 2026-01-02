import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/services/ble_service.dart';
import 'package:flutter_boxd_app_flow/services/ble_protocol.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:flutter_boxd_app_flow/widgets/temperature_picker_dialog.dart';
import 'package:flutter_boxd_app_flow/utils/app_storage.dart';

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
  final bleService = BleService();

  late final FixedExtentScrollController minutesController =
      FixedExtentScrollController(initialItem: 10);

  @override
  void initState() {
    super.initState();
    _loadTemperatureUnit();
    final lastStatus = bleService.lastStatus;
    if (lastStatus != null) {
      if (lastStatus.temperature != null) temperature = lastStatus.temperature!;
      if (lastStatus.batteryLevel != null) {
        final level = lastStatus.batteryLevel!;
        batteryLevel = (level >= 1 && level <= 4) ? level * 25 : level;
      }
    }
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

  Future<void> _loadTemperatureUnit() async {
    final unit = await AppStorage.loadUnit();
    if (mounted) {
      setState(() => temperatureUnit = unit);
    }
  }

  @override
  void dispose() {
    minutesController.dispose();
    super.dispose();
  }

  void _sendCommand() async {
    if (selectedTemperature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select temperature')),
      );
      return;
    }

    if (minutes < 20 || minutes > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Heating time must be between 20-50 minutes')),
      );
      return;
    }

    final success = await bleService.setWork(
      mode: WorkMode.heating,
      temperature: selectedTemperature!,
      heatingTime: minutes,
      mealTime: 0,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Command sent successfully' : 'Failed to send command, please try again')),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    final result = await showDialog<int>(
                      context: context,
                      builder: (context) => TemperaturePickerDialog(
                        initialTemperature: selectedTemperature ?? 90,
                      ),
                    );
                    if (result != null) {
                      setState(() => selectedTemperature = result);
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Assets.home.images.devTemperatureF.image(
                        width: 117,
                        fit: BoxFit.contain,
                      ),
                      Positioned(
                        top: 54,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedTemperature?.toString() ?? temperature.toString(),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              temperatureUnit,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Assets.home.images.homeDevice.image(
                      width: 150,
                      fit: BoxFit.contain,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          batteryLevel > 20
                              ? Icons.battery_std
                              : Icons.battery_alert,
                          color:
                              batteryLevel > 20 ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$batteryLevel%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Padding(
            padding: EdgeInsets.only(left: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Heating ...',
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(
                    width: 120,
                    child: Center(
                        child: Text('MIN',
                            style:
                                TextStyle(fontSize: 12, color: Colors.grey)))),
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
                          minutes, (v) => setState(() => minutes = v + 20)),
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

  Widget _buildTimePicker(int value, Function(int) onChanged) {
    return SizedBox(
      width: 120,
      height: 60,
      child: ListWheelScrollView.useDelegate(
        controller: minutesController,
        itemExtent: 40,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            final displayValue = index + 20;
            return Center(
              child: Text(
                displayValue.toString().padLeft(2, '0'),
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.w300),
              ),
            );
          },
          childCount: 31,
        ),
      ),
    );
  }
}
