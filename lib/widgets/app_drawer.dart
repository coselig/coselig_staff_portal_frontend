import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:coselig_staff_portal/widgets/theme_toggle_switch.dart';
import 'package:coselig_staff_portal/main.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Text(
              '光悅員工系統',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          if (authService.isAdmin) ...[
            ListTile(
              leading: Icon(Icons.admin_panel_settings),
              title: Text('管理員系統'),
              onTap: () {
                navigatorKey.currentState!.pushNamed('/admin');
              },
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('用戶資料預覽'),
              onTap: () {
                navigatorKey.currentState!.pushNamed('/admin_user_preview');
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('首頁'),
            onTap: () {
              navigatorKey.currentState!.pushNamed('/');
            },
          ),
          ListTile(
            leading: Icon(Icons.cloud),
            title: Text('雲端硬碟'),
            onTap: () async {
              final Uri url = Uri.parse('https://drive.google.com/drive/folders/1KAwWpAqFOA6CqaQ508yQVm3B_zIlcGpr?usp=drive_link');
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                throw Exception('Could not launch $url');
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.build),
            title: Text('裝置註冊表生成器'),
            onTap: () {
              navigatorKey.currentState!.pushNamed('/discovery_generate');
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('我的資料'),
            onTap: () {
              navigatorKey.currentState!.pushNamed('/user_data');
            },
          ),
          ListTile(
            leading: Icon(Icons.work),
            title: Text('顯示目前工作的員工'),
            onTap: () {
              print('Toggle currently working employees');
            },
          ),
          const Divider(),
          ListTile(title: ThemeToggleSwitch()),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('登出'),
            onTap: () {
              final authService = context.read<AuthService>();
              authService.logout();
              navigatorKey.currentState!.pushReplacementNamed('/login');
            },
          ),
        ],
      ),
    );
  }
}
