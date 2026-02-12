import 'dart:js_interop';

import 'package:coselig_staff_portal/constants/app_constants.dart';
import 'package:coselig_staff_portal/pages/admin/attendance_view_page.dart';
import 'package:coselig_staff_portal/pages/admin/user_data_view_page.dart';
import 'package:coselig_staff_portal/pages/admin/module_management_page.dart';
import 'package:coselig_staff_portal/pages/admin/fixture_type_management_page.dart';
import 'package:coselig_staff_portal/pages/general/auth_page.dart';
import 'package:coselig_staff_portal/pages/general/ble_page.dart';
import 'package:coselig_staff_portal/pages/general/privacy_policy_page.dart';
import 'package:coselig_staff_portal/pages/staff/discovery_generate_page.dart';
import 'package:coselig_staff_portal/pages/general/register_page.dart';
import 'package:coselig_staff_portal/pages/general/splash_screen.dart';
import 'package:coselig_staff_portal/pages/staff/staff_home_page.dart';
import 'package:coselig_staff_portal/pages/customer/customer_home_page.dart';
import 'package:coselig_staff_portal/pages/staff/staff_data_page.dart';
import 'package:coselig_staff_portal/services/attendance_service.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:coselig_staff_portal/services/quote_service.dart';
import 'package:coselig_staff_portal/services/theme_provider.dart';
import 'package:coselig_staff_portal/services/ui_settings_provider.dart';
import 'package:coselig_staff_portal/services/customer_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:web/web.dart';

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

  console.log('=== Coselig 員工系統啟動 ==='.toJS);
  console.log('版本: ${AppConstants.appVersion}'.toJS);
  console.log('構建: ${AppConstants.buildNumber}'.toJS);
  console.log('時間: $currentTime'.toJS);
  console.log('======================='.toJS);
  
  setPathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AttendanceService()),
        ChangeNotifierProvider(create: (_) => UiSettingsProvider()),
        ChangeNotifierProvider(create: (_) => QuoteService()),
        ChangeNotifierProvider(create: (_) => CustomerService()),
        ChangeNotifierProxyProvider<AuthService, ThemeProvider>(
          create: (context) =>
              ThemeProvider(Provider.of<AuthService>(context, listen: false)),
          update: (context, authService, previous) =>
              ThemeProvider(authService),
        ),
      ],
      child: const AppInitializer(),
    ),
  );
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    // 應用啟動時初始化共享數據
    Future.microtask(() {
      final attendanceService = context.read<AttendanceService>();
      attendanceService.fetchAndCacheWorkingStaff();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MainApp();
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Consumer<UiSettingsProvider>(
      builder: (context, uiSettings, child) {
        final baseLightTheme = ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFfEBC82),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        );
        final baseDarkTheme = ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFfEBC82),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        );

        final lightThemeWithScale = baseLightTheme.copyWith(
          textTheme: baseLightTheme.textTheme.apply(
            fontSizeFactor: uiSettings.fontSizeScale,
            fontSizeDelta: 0,
          ),
        );
        final darkThemeWithScale = baseDarkTheme.copyWith(
          textTheme: baseDarkTheme.textTheme.apply(
            fontSizeFactor: uiSettings.fontSizeScale,
            fontSizeDelta: 0,
          ),
        );

        return Consumer<AuthService>(
          builder: (context, authService, child) {
            return MaterialApp(
              title: authService.isCustomer ? 'Coselig 顧客系統' : 'Coselig 員工系統',
              color: Colors.orangeAccent[100],
              navigatorKey: navigatorKey,
              scaffoldMessengerKey: scaffoldMessengerKey,
              theme: lightThemeWithScale,
              darkTheme: darkThemeWithScale,
              themeMode: themeProvider.themeMode,
              initialRoute: '/',
              onUnknownRoute: (settings) {
                // 對於未知路由，重定向到 splash，讓它處理
                return MaterialPageRoute(
                  builder: (context) => const SplashScreen(),
                );
              },
              routes: {
                '/': (context) => const SplashScreen(),
                '/splash': (context) => const SplashScreen(),
                '/login': (context) => const AuthPage(),
                '/home': (context) => const StaffHomePage(),
                '/customer_home': (context) => const CustomerHomePage(),
                '/register': (context) => const RegisterPage(),
                '/admin': (context) => const AllAttendanceViewPage(),
                '/discovery_generate': (context) =>
                    const DiscoveryGeneratePage(),
                '/ble': (context) => const BlePage(),
                '/user_data': (context) => const StaffDataPage(),
                '/admin_user_preview': (context) =>
                    const UserDataViewPage(),
                '/module_management': (context) => const ModuleManagementPage(),
                '/fixture_type_management': (context) =>
                    const FixtureTypeManagementPage(),
                '/privacy': (context) => const PrivacyPolicyPage(),
              },
            );
          },
        );
      },
    );
  }
}