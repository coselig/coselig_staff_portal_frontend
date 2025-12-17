import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>(); // 監聽 service 狀態

    return Scaffold(
      appBar: AppBar(title: const Text('員工入口')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: '帳號'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: '密碼'),
              obscureText: true,
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => authService.login(
                    usernameController.text,
                    passwordController.text,
                  ),
                  child: const Text('登入'),
                ),
                ElevatedButton(
                  onPressed: () => authService.register(
                    usernameController.text,
                    passwordController.text,
                  ),
                  child: const Text('註冊'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  authService.output, // 這裡自動更新
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
