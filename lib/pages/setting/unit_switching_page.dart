import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/utils/app_storage.dart';

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
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context, selectedUnit),
        ),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('45°C',
                  style: TextStyle(
                      color: Colors.black26,
                      fontSize: 40,
                      fontWeight: FontWeight.bold)),
              const Text('113°F',
                  style: TextStyle(
                      color: Colors.black26,
                      fontSize: 40,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const Text('Unit switching',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
              const SizedBox(height: 8),
              const Text('You can set the display unit for temperature here',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 14)),
              const SizedBox(height: 32),
              _buildUnitButton('°F', 'Fahrenheit'),
              const SizedBox(height: 12),
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
        width: 160,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
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
                    fontSize: 16,
                    color: selected ? AppColors.orange : Colors.black)),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    color: selected ? AppColors.orange : Colors.black54)),
          ],
        ),
      ),
    );
  }
}
