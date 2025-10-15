import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'utils/app_colors.dart';

void main() {
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
        inputDecorationTheme: InputDecorationTheme(
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          floatingLabelAlignment: FloatingLabelAlignment.start,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.0,
            color: Colors.black.withOpacity(0.4),
          ),
          floatingLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.0,
            color: Colors.black.withOpacity(0.4),
          ),
          filled: true,
          fillColor: AppColors.white,
          // 让标签在白色框内距顶约 12，并使输入文字略微下移
          contentPadding: const EdgeInsets.fromLTRB(16, 28, 16, 18),
          constraints: const BoxConstraints(minHeight: 72),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      themeMode: ThemeMode.light,
      home: const HomePage(),
    );
  }
}
