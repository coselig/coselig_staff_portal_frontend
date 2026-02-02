import 'package:universal_html/html.dart' as html;
import 'package:coselig_staff_portal/services/attendance_service.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:coselig_staff_portal/widgets/buttons.dart';
import 'package:coselig_staff_portal/widgets/app_drawer.dart';
import 'package:coselig_staff_portal/widgets/attendance_viewer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/main.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理員系統'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: '回首頁',
          onPressed: () {
            navigatorKey.currentState!.pushReplacementNamed('/home');
          },
        ),
        actions: [
          registerGenerateButton(),
          logoutButton(context),
        ],
      ),
      drawer: const AppDrawer(),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: AttendanceViewer(isAdminMode: true),
      ),
    );
  }
}