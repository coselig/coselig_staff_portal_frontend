import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';

class StaffHomePage extends StatelessWidget {
  const StaffHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    return Scaffold(
      appBar: AppBar(title: const Text('員工系統')),
      body: Center(
        child: Text(
          '歡迎，${authService.username ?? '未知使用者'}',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
