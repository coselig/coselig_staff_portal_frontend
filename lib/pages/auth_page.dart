import 'package:universal_html/html.dart' as html;
import 'package:coselig_staff_portal/widgets/buttons.dart';
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
  void initState() {
    super.initState();
    html.document.title = '員工入口';
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('員工入口'),
        actions: [
          ThemeToggleSwitch(),
          registerGenerateButton(),
          blePageButton(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              mode == "login" ? const LoginFrame() : const RegisterFrame(),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Color.fromARGB(40, 200, 100, 100),
                ),
                onPressed: () {
                  setState(() {
                    mode = mode == "login" ? "register" : "login";
                  });
                },
                child: Text(mode == "login" ? "\n註\n冊\n" : "\n登\n入\n"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
