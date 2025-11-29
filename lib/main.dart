import 'dart:io';
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'utils/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // iOS 调试模式下触发本地网络权限弹窗
  if (Platform.isIOS) {
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        final socket = await Socket.connect('127.0.0.1', 8080,
            timeout: const Duration(milliseconds: 100));
        socket.destroy();
      } catch (_) {}
    });
  }

  print("main start");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light(useMaterial3: true);
    return MaterialApp(
      title: 'Flutter Boxd App',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: AppColors.pageBg,
      ),
      themeMode: ThemeMode.light,
      home: const HomePage(),
    );
  }
}
