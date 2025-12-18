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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            '歡迎，${authService.name ?? '員工'}！',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () {}, child: const Text('功能按鈕範例')),
        ],
      ),
    );
  }
}
