import 'package:coselig_staff_portal/constants/app_constants.dart';
import 'package:coselig_staff_portal/pages/admin_page.dart';
import 'package:coselig_staff_portal/pages/admin_user_preview_page.dart';
import 'package:coselig_staff_portal/pages/auth_page.dart';
import 'package:coselig_staff_portal/pages/ble_page.dart';
import 'package:coselig_staff_portal/pages/discovery_generate_page.dart';
import 'package:coselig_staff_portal/pages/privacy_policy_page.dart';
import 'package:coselig_staff_portal/pages/splash_screen.dart';
import 'package:coselig_staff_portal/pages/staff_home_page.dart';
import 'package:coselig_staff_portal/pages/user_data_page.dart';
import 'package:coselig_staff_portal/services/attendance_service.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:coselig_staff_portal/services/theme_provider.dart';
import 'package:coselig_staff_portal/widgets/register_frame.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';
import 'dart:html' as html;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  // 確保 Flutter binding 已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 AppConstants（讀取版本信息）
  await AppConstants.init();
  
  // 顯示版本信息
  final currentTime = DateTime.now().toIso8601String();

  html.window.console.log('=== Coselig 員工系統啟動 ===');
  html.window.console.log('版本: ${AppConstants.appVersion}');
  html.window.console.log('構建: ${AppConstants.buildNumber}');
  html.window.console.log('時間: $currentTime');
  html.window.console.log('=======================');
  
  setPathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AttendanceService()),
        ChangeNotifierProxyProvider<AuthService, ThemeProvider>(
          create: (context) =>
              ThemeProvider(Provider.of<AuthService>(context, listen: false)),
          update: (context, authService, previous) =>
              ThemeProvider(authService),
        ),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Coselig 員工系統',
      color: Colors.orangeAccent[100],
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      onUnknownRoute: (settings) {
        // 對於未知路由，重定向到 splash，讓它處理
        return MaterialPageRoute(builder: (context) => const SplashScreen());
      },
      routes: {
        '/': (context) => const SplashScreen(),
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const AuthPage(),
        '/home': (context) => const StaffHomePage(),
        '/register': (context) => const RegisterFrame(),
        '/admin': (context) => const AdminPage(),
        '/discovery_generate': (context) => const DiscoveryGeneratePage(),
        '/ble': (context) => const BlePage(),
        '/user_data': (context) => const UserDataPage(),
        '/admin_user_preview': (context) => const AdminUserPreviewPage(),
        '/privacy': (context) => const PrivacyPolicyPage(),
      },
    );
  }
}