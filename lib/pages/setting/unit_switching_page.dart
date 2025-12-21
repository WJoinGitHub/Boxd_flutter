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
      body: Column(
        children: [
          const SizedBox(height: 50),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Assets.user.images.temperatureChange.image(width: 250),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 220,
                  child: Column(
                    children: [
                      Text('Unit switching',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 17)),
                      SizedBox(height: 7),
                      Text('You can set the display unit for temperature here',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 27),
                _buildUnitButton('°F', 'Fahrenheit'),
                const SizedBox(height: 10),
                _buildUnitButton('°C', 'Centigrade'),
              ],
            ),
          ),
        ],
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
