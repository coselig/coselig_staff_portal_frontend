import 'package:coselig_staff_portal/main.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginFrame extends StatefulWidget {
  const LoginFrame({super.key});

  @override
  State<LoginFrame> createState() => _LoginFrameState();
}

class _LoginFrameState extends State<LoginFrame> {
  TextEditingController accountController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Color.fromARGB(28, 211, 80, 40),
      ),
      padding: const EdgeInsets.all(16.0),
      width: MediaQuery.of(context).size.width * 0.4,
      constraints: BoxConstraints(
        minHeight: 250,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          TextField(
            controller: accountController,
            decoration: const InputDecoration(labelText: '電子郵件/帳號'),
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
                  final success = await authService.login(
                    accountController.text,
                    passwordController.text,
                  );
                  if (success) {
                    if (mounted) {
                      navigatorKey.currentState!.pushReplacementNamed('/home');
                    }
                  }
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 3,
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                child: const Text('登入'),
              ),
          ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final success = await authService.googleLogin();
                  if (success) {
                    if (mounted) {
                      navigatorKey.currentState!.pushReplacementNamed('/home');
                    }
                  }
                  setState(() {});
                },
                icon: Icon(Icons.login),
                label: Text('使用 Google 登入'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  navigatorKey.currentState!.pushNamed('/privacy');
                },
                child: const Text(
                  '隱私權政策',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            // SizedBox(height: 8),
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
