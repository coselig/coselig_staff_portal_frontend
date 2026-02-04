import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:coselig_staff_portal/widgets/app_drawer.dart';
import 'package:universal_html/html.dart' as html;

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  @override
  void initState() {
    super.initState();
    html.document.title = '光悅顧客系統';
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('顧客主頁面'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '歡迎, ${authService.chineseName ?? authService.name ?? '顧客'}!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Text(
              '這是顧客專用的主頁面',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 40),
            // 這裡可以添加顧客特定的功能
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.person, size: 48),
                    const SizedBox(height: 8),
                    Text('顧客功能', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text('這裡將顯示顧客可用的功能'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}