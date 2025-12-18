import 'package:coselig_staff_portal/pages/staff_home_page.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Color.fromARGB(28, 211, 80, 40),
      ),
      padding: const EdgeInsets.all(16.0),
      width: MediaQuery.of(context).size.width * 0.4,
      height: MediaQuery.of(context).size.height * 0.27,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await authService.register(
                emailController.text,
                usernameController.text,
                passwordController.text,
              );
              // 假設 statusCode 200/201 視為登入成功
              if (authService.output.contains('HTTP status: 200') ||
                  authService.output.contains('HTTP status: 201')) {
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const StaffHomePage()),
                );
              }
              setState(() {});
            },
            child: const Text('註冊'),
          ),

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
    );
  }
}
