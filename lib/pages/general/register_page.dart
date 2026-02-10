import 'package:coselig_staff_portal/widgets/register_frame.dart';
import 'package:coselig_staff_portal/widgets/theme_toggle_switch.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('註冊新帳號'),
        actions: [
          ThemeToggleSwitch(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: const RegisterFrame(),
        ),
      ),
    );
  }
}