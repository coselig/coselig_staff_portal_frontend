import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:coselig_staff_portal/services/attendance_service.dart';
import 'package:coselig_staff_portal/services/ui_settings_provider.dart';
import 'package:coselig_staff_portal/constants/app_constants.dart';

import 'package:coselig_staff_portal/widgets/theme_toggle_switch.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;
  bool _autoLoginStarted = false;

  @override
  void initState() {
    super.initState();
    html.document.title = 'Coselig 員工系統';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_autoLoginStarted) {
      _autoLoginStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _doAutoLoginAndNavigate();
      });
    }
  }

  Future<void> _doAutoLoginAndNavigate() async {
    final authService = context.read<AuthService>();
    // 同時進行自動登入和最少顯示 2 秒的 splash
    await Future.wait([
      authService.tryAutoLogin(),
      Future.delayed(const Duration(seconds: 2)),
    ]);
    if (!mounted) return;
    if (!_navigated) {
      _navigated = true;
      String targetRoute;
      if (authService.isLoggedIn) {
        // 登入成功後載入 UI 偏好設定
        context.read<UiSettingsProvider>().bindAuthService(authService);
        // 登入成功後才獲取正在上班的員工列表
        context.read<AttendanceService>().fetchAndCacheWorkingStaff();
        // 檢查當前 URL 路徑
        final currentPath = html.window.location.pathname;
        if (currentPath == '/discovery_generate' ||
            currentPath == '/admin' ||
            currentPath == '/ble' ||
            currentPath == '/customer_home' ||
            currentPath == '/customer_profile' ||
            currentPath == '/home' ||
            currentPath == '/user_data' ||
            currentPath == '/admin_user_preview' ||
            currentPath == '/module_management' ||
            currentPath == '/fixture_type_management' ||
            currentPath == '/switch_management' ||
            currentPath == '/power_supply_management') {
          targetRoute = currentPath!;
        } else {
          // 根據角色導航到不同主頁面
          if (authService.isCustomer) {
            targetRoute = '/customer_home';
          } else {
            targetRoute = '/home';
          }
        }
      } else {
        targetRoute = '/login';
      }
      Navigator.of(context).pushReplacementNamed(targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              AppConstants.fullVersion,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            const ThemeToggleSwitch(),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                html.window.location.href = '/privacy.html';
              },
              child: const Text('隱私權政策 / Privacy Policy'),
            ),
          ],
        ),
      ),
    );
  }
}
