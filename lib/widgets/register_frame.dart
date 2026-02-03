import 'package:coselig_staff_portal/main.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:coselig_staff_portal/services/ui_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterFrame extends StatefulWidget {
  const RegisterFrame({super.key});

  @override
  State<RegisterFrame> createState() => _RegisterFrameState();
}

class _RegisterFrameState extends State<RegisterFrame> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final uiSettings = context.watch<UiSettingsProvider>();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Color.fromARGB(28, 211, 80, 40),
      ),
      padding: const EdgeInsets.all(16.0),
      width: MediaQuery.of(context).size.width * 0.4,
      constraints: BoxConstraints(
        minHeight: 300,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: '電子郵件'),
          ),
          TextField(
            controller: usernameController,
            decoration: const InputDecoration(labelText: '帳號名稱'),
          ),
          TextField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: '密碼'),
            obscureText: true,
          ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final success = await authService.register(
                    usernameController.text,
                    emailController.text,
                    passwordController.text,
                  );
                  if (success) {
                    if (!mounted) return;
                    navigatorKey.currentState!.pushReplacementNamed('/home');
                  }
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                  textStyle: TextStyle(
                    fontSize: (18 * uiSettings.fontSizeScale).toDouble(),
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 3,
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                child: const Text('註冊'),
              ),
          ),
          // SizedBox(height: 8),
          // Expanded(
          //   child: SingleChildScrollView(
          //     child: Text(
          //       authService.message,
          //       style: const TextStyle(fontFamily: 'Courier', fontSize: 14),
          //     ),
          //   ),
          // ),
          ],
        ),
      ),
    );
  }
}
