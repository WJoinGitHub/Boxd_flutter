import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/utils/app_storage.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';

class UnitSwitchingPage extends StatefulWidget {
  const UnitSwitchingPage({super.key});

  @override
  State<UnitSwitchingPage> createState() => _UnitSwitchingPageState();
}

class _UnitSwitchingPageState extends State<UnitSwitchingPage> {
  String selectedUnit = '°C';

  @override
  void initState() {
    super.initState();
    _loadSavedUnit();
  }

  Future<void> _loadSavedUnit() async {
    final saved = await AppStorage.loadUnit();
    setState(() => selectedUnit = saved);
  }

  Future<void> _selectUnit(String unit) async {
    setState(() => selectedUnit = unit);
    await AppStorage.saveUnit(unit);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BxAppBar(
        leftIcon: Assets.common.images.deviceBack.image(
          width: 35,
          height: 35,
          fit: BoxFit.contain,
        ),
        title: "Settings",
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('45°C',
                  style: TextStyle(
                      color: Colors.black26,
                      fontSize: 33,
                      fontWeight: FontWeight.bold)),
              const Text('113°F',
                  style: TextStyle(
                      color: Colors.black26,
                      fontSize: 33,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('Unit switching',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
              const SizedBox(height: 7),
              const Text('You can set the display unit for temperature here',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 27),
              _buildUnitButton('°F', 'Fahrenheit'),
              const SizedBox(height: 10),
              _buildUnitButton('°C', 'Centigrade'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitButton(String symbol, String label) {
    final bool selected = selectedUnit == symbol;
    return GestureDetector(
      onTap: () => _selectUnit(symbol),
      child: Container(
        width: 133,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: selected ? AppColors.orange : Colors.black26,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(symbol,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: selected ? AppColors.orange : Colors.black)),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: selected ? AppColors.orange : Colors.black54)),
          ],
        ),
      ),
    );
  }
}
