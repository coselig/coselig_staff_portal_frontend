import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:coselig_staff_portal/services/ui_settings_provider.dart';
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
            child: Consumer<UiSettingsProvider>(
              builder: (context, uiSettings, child) {
                return Text(
                  authService.isCustomer ? '光悅顧客系統' : '光悅員工系統',
                  style: TextStyle(
                    fontSize: (20 * uiSettings.fontSizeScale).toDouble(),
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
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
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('模組管理'),
              onTap: () {
                navigatorKey.currentState!.pushNamed('/module_management');
              },
            ),
            ListTile(
              leading: Icon(Icons.lightbulb_outline),
              title: Text('燈具類型管理'),
              onTap: () {
                navigatorKey.currentState!.pushNamed(
                  '/fixture_type_management',
                );
              },
            ),
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
            if (authService.isAdmin || authService.isManager) ...[
              ListTile(
                leading: Icon(Icons.build),
                title: Text('裝置註冊表生成器'),
                onTap: () {
                  navigatorKey.currentState!.pushNamed('/discovery_generate');
                },
              ),
            ],
            ListTile(
              leading: Icon(Icons.person),
              title: Text('我的資料'),
              onTap: () {
                navigatorKey.currentState!.pushNamed('/user_data');
              },
            ),
            if (authService.isAdmin ||
                authService.isManager ||
                authService.isStaff) ...[
              ListTile(
                leading: Icon(Icons.work),
                title: Text('顯示目前工作的員工'),
                trailing: Consumer<UiSettingsProvider>(
                  builder: (context, uiSettings, child) {
                    return Switch(
                      value: uiSettings.showWorkingStaffCard,
                      onChanged: (bool value) {
                        uiSettings.setShowWorkingStaffCard(value);
                      },
                    );
                  },
                ),
              ),
            ],
            // 估價系統 - 員工和顧客都可以使用
            ListTile(
              leading: Icon(Icons.calculate),
              title: Text('估價系統'),
              onTap: () {
                navigatorKey.currentState!.pushNamed('/customer_home');
              },
            ),
          ] else ...[
            // 顧客特定的選項
            ListTile(
              leading: Icon(Icons.store),
              title: Text('商店'),
              onTap: () {
                // TODO: 添加商店頁面
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('商店功能即將推出')));
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('訂單記錄'),
              onTap: () {
                // TODO: 添加訂單記錄頁面
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('訂單記錄功能即將推出')));
              },
            ),
          ],
          ListTile(
            leading: Icon(Icons.text_fields),
            title: Text('字體大小'),
            subtitle: Consumer<UiSettingsProvider>(
              builder: (context, uiSettings, child) {
                return Slider(
                  value: uiSettings.fontSizeScale,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: '${(uiSettings.fontSizeScale * 100).round()}%',
                  onChanged: (double value) {
                    uiSettings.setFontSizeScale(value);
                  },
                );
              },
            ),
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
