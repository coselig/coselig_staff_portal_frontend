import 'package:coselig_staff_portal/widgets/login_frame.dart';
import 'package:coselig_staff_portal/widgets/register_frame.dart';
import 'package:coselig_staff_portal/widgets/theme_toggle_switch.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  String mode = "login";

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('員工入口'),
        actions: const [ThemeToggleSwitch()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              mode == "login" ? const LoginFrame() : const RegisterFrame(),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    mode = mode == "login" ? "register" : "login";
                  });
                },
                child: Text(mode == "login" ? "我要註冊" : "我要登入"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
