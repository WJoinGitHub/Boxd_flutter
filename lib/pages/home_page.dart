import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/pages/login/login_options_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('主页面')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                fullscreenDialog: true,
                pageBuilder: (_, __, ___) => const LoginOptionsPage(),
              ),
            );
          },
          child: const Text('登录'),
        ),
      ),
    );
  }
}
