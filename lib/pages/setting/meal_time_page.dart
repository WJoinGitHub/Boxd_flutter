import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';

class MealTimePage extends StatelessWidget {
  const MealTimePage({super.key});

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
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Assets.device.images.devHeatTime.image(
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 40),
            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Meal\ntime!  ',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                  TextSpan(
                    text: '12',
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                  TextSpan(
                    text: ' : ',
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                  TextSpan(
                    text: '00',
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
