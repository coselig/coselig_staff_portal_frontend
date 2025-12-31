import 'package:coselig_staff_portal/main.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Widget registerGenerateButton() {
  return IconButton(
    icon: const Icon(Icons.build),
    tooltip: '裝置註冊表生成器',
    onPressed: () {
      navigatorKey.currentState!.pushNamed('/discovery_generate');
    },
  );
}

Widget logoutButton(BuildContext context) {
  final authService = context.read<AuthService>();
  return IconButton(
    icon: const Icon(Icons.logout),
    tooltip: '登出',
    onPressed: () {
      authService.logout();
      navigatorKey.currentState!.pushReplacementNamed('/login');
    },
  );
}

Widget blePageButton() {
  return IconButton(
    icon: const Icon(Icons.bluetooth),
    tooltip: '附近低功耗藍芽裝置',
    onPressed: () {
      navigatorKey.currentState!.pushNamed('/ble');
    },
  );
}
