import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:coselig_staff_portal/pages/staff_home_page.dart';
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
    final authService = context.watch<AuthService>();

    Future<void> handleLogin() async {
      await authService.login(usernameController.text, passwordController.text);
      // 假設 statusCode 200/201 視為登入成功
      if (authService.output.contains('HTTP status: 200') ||
          authService.output.contains('HTTP status: 201')) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StaffHomePage()),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('員工入口')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
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
                    onPressed: handleLogin,
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
                    authService.output,
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
