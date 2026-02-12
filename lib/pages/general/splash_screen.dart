import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:coselig_staff_portal/services/attendance_service.dart';

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
    await authService.tryAutoLogin();
    if (!mounted) return;
    if (!_navigated) {
      _navigated = true;
      String targetRoute;
      if (authService.isLoggedIn) {
        // 登入成功後才獲取正在上班的員工列表
        context.read<AttendanceService>().fetchAndCacheWorkingStaff();
        // 檢查當前 URL 路徑
        final currentPath = html.window.location.pathname;
        if (currentPath == '/discovery_generate' ||
            currentPath == '/admin' ||
            currentPath == '/ble') {
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
            const ThemeToggleSwitch(),
          ],
        ),
      ),
    );
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/ctc_icon.png',
            width: MediaQuery.of(context).size.width * 0.3,
          ),
          SizedBox(height: 24),
          Text(
            '光悅員工系統',
            style: TextStyle(
              fontSize: MediaQuery.of(context).textScaler.scale(24),
            ),
          ),
          SizedBox(height: 12),
          Text(
            '載入中...',
            style: TextStyle(
              fontSize: MediaQuery.of(context).textScaler.scale(24),
            ),
          ),
        ],
      ),
    ),
  );
}
