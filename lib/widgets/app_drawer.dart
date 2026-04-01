import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
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
          ListTile(
            title: Text(
              authService.isCustomer ? 'Coselig 顧客系統' : 'Coselig 員工系統',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            // 管理項目（估價系統管理項）已移至一般員工選單，留空或其他 admin-only 項目可置於此處
          ] else if (authService.isManager) ...[
            ListTile(
              leading: Icon(Icons.people),
              title: Text('用戶資料預覽'),
              onTap: () {
                navigatorKey.currentState!.pushNamed('/admin_user_preview');
              },
            ),
          ],
          const Divider(),
          if (!authService.isCustomer) ...[
            ListTile(
              leading: Icon(Icons.home),
              title: Text('首頁'),
              onTap: () {
                navigatorKey.currentState!.pushNamed('/');
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
              leading: Icon(Icons.cloud),
              title: Text('雲端硬碟'),
              onTap: () async {
                final Uri url = Uri.parse(
                  'https://drive.google.com/drive/folders/1KAwWpAqFOA6CqaQ508yQVm3B_zIlcGpr?usp=drive_link',
                );
                if (!await launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                )) {
                  throw Exception('Could not launch $url');
                }
              },
            ),

            const Divider(),
            ListTile(
              leading: Icon(Icons.build),
              title: Text('裝置註冊表生成器'),
              onTap: () {
                navigatorKey.currentState!.pushNamed('/discovery_generate');
              },
            ),
            ListTile(
              leading: Icon(Icons.device_hub),
              title: Text('裝置設定管理'),
              onTap: () {
                navigatorKey.currentState!.pushNamed(
                  '/device_config_management',
                );
              },
            ),
            const Divider(),
            // 估價系統 - 員工和顧客都可以使用
            ListTile(
              leading: Icon(Icons.calculate),
              title: Text('估價系統'),
              onTap: () {
                navigatorKey.currentState!.pushNamed('/customer_quote_builder');
              },
            ),
            ListTile(
              leading: Icon(Icons.fact_check_outlined),
              title: Text('智慧型住宅確認表'),
              onTap: () {
                navigatorKey.currentState!.pushNamed('/smart_home_assessment');
              },
            ),
            ExpansionTile(
              initiallyExpanded: false,
              leading: Icon(Icons.tune),
              title: Text('估價系統管理項'),
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 72, right: 16),
                  leading: Icon(Icons.settings),
                  title: Text('模組管理'),
                  onTap: () {
                    navigatorKey.currentState!.pushNamed('/module_management');
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 72, right: 16),
                  leading: Icon(Icons.lightbulb_outline),
                  title: Text('燈具類型管理'),
                  onTap: () {
                    navigatorKey.currentState!.pushNamed(
                      '/fixture_type_management',
                    );
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 72, right: 16),
                  leading: Icon(Icons.toggle_on),
                  title: Text('開關管理'),
                  onTap: () {
                    navigatorKey.currentState!.pushNamed('/switch_management');
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 72, right: 16),
                  leading: Icon(Icons.bolt),
                  title: Text('電源供應器管理'),
                  onTap: () {
                    navigatorKey.currentState!.pushNamed(
                      '/power_supply_management',
                    );
                  },
                ),
              ],
            ),
          ] else ...[
            // 顧客特定的選項
            ListTile(
              leading: Icon(Icons.home),
              title: Text('首頁'),
              onTap: () {
                navigatorKey.currentState!.pushNamed('/customer_home');
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('個人資料'),
              onTap: () {
                navigatorKey.currentState!.pushNamed('/customer_profile');
              },
            ),
            ListTile(
              leading: Icon(Icons.calculate),
              title: Text('估價系統'),
              onTap: () {
                navigatorKey.currentState!.pushNamed('/customer_quote_builder');
              },
            ),
          ],
          const Divider(),
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
