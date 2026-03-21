import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/utils/app_storage.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:flutter_boxd_app_flow/services/ble_service.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/utils/app_toast.dart';

class UnitSwitchingPage extends StatefulWidget {
  const UnitSwitchingPage({super.key});

  @override
  State<UnitSwitchingPage> createState() => _UnitSwitchingPageState();
}

class _UnitSwitchingPageState extends State<UnitSwitchingPage> {
  String selectedUnit = '°C';
  final bleService = BleService();
  bool _isSending = false;

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
    if (_isSending || selectedUnit == unit) return;

    setState(() {
      selectedUnit = unit;
      _isSending = true;
    });

    await AppStorage.saveUnit(unit);

    // 发送时间同步命令，包含温度单位
    if (bleService.isConnected) {
      final l10n = AppLocalizations.of(context);
      try {
        await bleService.syncTime();
        if (mounted) {
          AppToast.show(context, '${l10n.t('temperature_unit_changed_to')} $unit');
        }
      } catch (e) {
        print('[UNIT] 发送温度单位命令失败: $e');
        if (mounted) {
          AppToast.show(context, l10n.t('failed_to_send_command_try_again'));
        }
      }
    }

    if (mounted) {
      setState(() => _isSending = false);
      // 返回新的单位值给调用者
      Navigator.pop(context, unit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: BxAppBar(
        leftIcon: Assets.common.images.deviceBack.image(
          width: 35,
          height: 35,
          fit: BoxFit.contain,
        ),
        title: l10n.t('settings'),
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
                SizedBox(
                  width: 220,
                  child: Column(
                    children: [
                      Text(l10n.t('unit_switching_title'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 17)),
                      const SizedBox(height: 12),
                      Text(l10n.t('unit_switching_description'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 27),
                _buildUnitButton('°F', l10n.t('fahrenheit')),
                const SizedBox(height: 10),
                _buildUnitButton('°C', l10n.t('centigrade')),
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
      onTap: _isSending ? null : () => _selectUnit(symbol),
      child: Opacity(
        opacity: _isSending ? 0.5 : 1.0,
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
      ),
    );
  }
}
