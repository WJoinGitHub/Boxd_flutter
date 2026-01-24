import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'pages/splash_page.dart';
import 'pages/home_page.dart';
import 'pages/login/register_email_page.dart';
import 'services/user_service.dart';
import 'utils/app_colors.dart';

// 全局导航器 key，用于在任何地方导航
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      navigatorKey: navigatorKey,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('zh', ''),
      ],
      theme: base.copyWith(
        scaffoldBackgroundColor: AppColors.pageBg,
      ),
      themeMode: ThemeMode.light,
      home: Platform.isAndroid
          ? const _InitialPage() // Android 使用原生启动页面，直接跳转
          : const SplashPage(), // iOS 使用 Flutter 启动页面
    );
  }
}

/// Android 初始页面，直接根据登录状态跳转（不使用启动页面，因为已有原生启动页面）
class _InitialPage extends StatefulWidget {
  const _InitialPage();

  @override
  State<_InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<_InitialPage> {
  @override
  void initState() {
    super.initState();
    _navigateToPage();
  }

  Future<void> _navigateToPage() async {
    // 等待 Flutter 引擎完全初始化
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // 先加载本地保存的登录信息
    await UserService().loadFromLocal();

    // 检查登录状态
    final isLoggedIn = UserService().isLoggedIn;

    // 导航到相应页面
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? const HomePage() : const RegisterEmailPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 显示空白页面，等待跳转
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox.shrink(),
      ),
    );
  }
}
