import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';

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
      if (authService.isLoggedIn) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
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
