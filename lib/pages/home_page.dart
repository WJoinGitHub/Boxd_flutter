import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/pages/login/email_login_page.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('主页面')),
      backgroundColor: AppColors.pageBg,
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                fullscreenDialog: true,
                pageBuilder: (_, __, ___) => const EmailLoginPage(),
              ),
            );
          },
          child: const Text('登录'),
        ),
      ),
    );
  }
}
