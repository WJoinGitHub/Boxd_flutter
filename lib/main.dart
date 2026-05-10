import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'pages/splash_page.dart';
import 'pages/home_page.dart';
import 'pages/login/register_email_page.dart';
import 'services/user_service.dart';
import 'services/push_channel_init.dart';
import 'services/push_token_report.dart';
import 'utils/app_colors.dart';

// 全局导航器 key，用于在任何地方导航
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 推送/统计初始化走原生通道，若在 runApp 之前 await，首帧无法调度，
  // 再叠加系统深色下 NormalTheme 为黑底，会出现长时间启动黑屏。
  runApp(const MyApp());
  _initPushAfterFirstFrame();

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

  if (kDebugMode) {
    debugPrint('main: runApp scheduled');
  }
}

/// 首帧之后再初始化推送，避免阻塞引擎挂载与第一帧绘制。
///
/// [initPushByRegion] 内部若有 `await` 永久挂起（例如无 GMS 时 FCM
/// `getToken()`），则下一行永远不会执行；因此用 [Future.timeout] 与
/// [finally] 保证 [PushTokenReport.syncIfLoggedIn] 仍会跑到。
void _initPushAfterFirstFrame() {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await initPushByRegion().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint(
              'initPushByRegion: timed out after 20s (e.g. FCM getToken without '
              'GMS, or Umeng initCommon blocking); continuing to push token sync',
            );
          }
        },
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('initPushByRegion failed: $e\n$st');
      }
    } finally {
      await PushTokenReport.syncIfLoggedIn();
    }
  });
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
        Locale('fr', ''),
        Locale('de', ''),
        Locale('it', ''),
        Locale('es', ''),
        Locale('pt', ''),
        Locale('ja', ''),
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
