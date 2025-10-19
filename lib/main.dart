import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'utils/app_colors.dart';

void main() {
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
