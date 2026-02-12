import 'package:universal_html/html.dart' as html;
import 'package:coselig_staff_portal/widgets/login_frame.dart';
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

  @override
  void initState() {
    super.initState();
    html.document.title = '光悅員工系統';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final paddingValue = isSmallScreen ? 8.0 : 20.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('光悅員工系統'),
        actions: [
          ThemeToggleSwitch(),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(paddingValue),
        child: Column(
          children: [
            // 應用程式用途說明
            Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.only(bottom: 20.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '應用程式用途',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '光悅員工系統是一款專為光悅科技員工設計的內部管理平台，提供以下功能：',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text('• 員工考勤記錄和管理', style: TextStyle(fontSize: 14)),
                  Text('• 員工個人資料管理', style: TextStyle(fontSize: 14)),
                  Text('• 公司公告和通知系統', style: TextStyle(fontSize: 14)),
                  Text('• 員工發現和建議功能', style: TextStyle(fontSize: 14)),
                  Text(
                    '• 管理員功能（員工列表管理、BLE 設備管理等）',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '本應用程式僅限 @coselig.com 域名下的 Google 帳號使用，旨在提高公司內部管理效率和員工工作體驗。',
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            // 登入區域
            Expanded(
              child: Center(
                child: const LoginFrame(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
