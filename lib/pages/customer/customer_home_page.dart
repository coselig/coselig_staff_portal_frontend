import 'package:coselig_staff_portal/widgets/app_drawer.dart';
import 'package:flutter/material.dart';

class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({super.key});

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('顧客首頁')),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.primaryContainer.withValues(alpha: 0.35),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '歡迎使用顧客入口',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '原本放在首頁裡的估價流程已獨立成新頁面，現在可以從這裡直接進入報價建立或維護個人資料。',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 800;
                        final quoteCard = _buildActionCard(
                          context: context,
                          icon: Icons.calculate_outlined,
                          title: '建立估價',
                          description: '進入完整的五步驟估價流程，包含迴路、模組、電源供應器與材料配置。',
                          buttonLabel: '前往估價流程',
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushNamed('/customer_quote_builder');
                          },
                        );
                        final profileCard = _buildActionCard(
                          context: context,
                          icon: Icons.person_outline,
                          title: '個人資料',
                          description: '查看並更新聯絡資訊、公司欄位與其他顧客相關資料。',
                          buttonLabel: '前往個人資料',
                          onPressed: () {
                            Navigator.of(context).pushNamed('/customer_profile');
                          },
                        );

                        if (!isWide) {
                          return Column(
                            children: [
                              quoteCard,
                              const SizedBox(height: 16),
                              profileCard,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: quoteCard),
                            const SizedBox(width: 16),
                            Expanded(child: profileCard),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
