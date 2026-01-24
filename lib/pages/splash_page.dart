import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/pages/home_page.dart';
import 'package:flutter_boxd_app_flow/pages/login/register_email_page.dart';
import 'package:flutter_boxd_app_flow/services/user_service.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // 等待2秒显示启动页面
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 先加载本地保存的登录信息
    await UserService().loadFromLocal();

    // 检查登录状态
    final isLoggedIn = UserService().isLoggedIn;

    // 导航到相应页面
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            isLoggedIn ? const HomePage() : const RegisterEmailPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // HeatLink 文字 - 黑色，size 50，weight 510，x 和 y 都居中
          Center(
            child: Text(
              'HeatLink',
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.w500, // Flutter 不支持精确的 510，使用 500 作为近似值
                color: AppColors.black,
                fontFamily: 'SF Pro',
              ),
            ),
          ),
          // QIMI 文字 - 橙色，size 60，weight 700，QIMI的bottom距离HeatLink的top间距75
          Center(
            child: Transform.translate(
              offset: const Offset(
                  0,
                  -75 -
                      25 -
                      30), // 向上移动：75(间距) + HeatLink高度的一半(约25) + QIMI高度的一半(约30)
              child: Text(
                'QIMI',
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w700,
                  color: AppColors.orange,
                  fontFamily: 'SF Pro',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
