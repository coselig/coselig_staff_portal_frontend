import 'package:coselig_staff_portal/pages/customer/widgets/quote_result_dialog.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:coselig_staff_portal/services/quote_service.dart';
import 'package:coselig_staff_portal/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomerQuotesPage extends StatefulWidget {
  const CustomerQuotesPage({super.key});

  @override
  State<CustomerQuotesPage> createState() => _CustomerQuotesPageState();
}

class _CustomerQuotesPageState extends State<CustomerQuotesPage> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<QuoteService>().fetchConfigurations();
    } catch (e) {
      _error = '載入報價單失敗: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatTimestamp(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      return '未記錄';
    }

    final normalized = value.contains('T')
        ? value
        : value.replaceFirst(' ', 'T');
    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) {
      return value;
    }

    final local = parsed.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${local.year}/${twoDigits(local.month)}/${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  Future<void> _openQuote(QuoteConfiguration configuration) async {
    final messenger = ScaffoldMessenger.of(context);
    var quoteData = configuration.quoteData;

    if (quoteData == null) {
      setState(() => _isLoading = true);
      try {
        quoteData = await context.read<QuoteService>().loadConfiguration(
          configuration.name,
        );
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text('載入報價內容失敗: $e')));
        return;
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }

    if (!mounted || quoteData == null) {
      messenger.showSnackBar(const SnackBar(content: Text('找不到報價內容')));
      return;
    }

    final resolvedQuoteData = quoteData;
    showDialog(
      context: context,
      builder: (dialogContext) => QuoteResultDialog(
        loops: resolvedQuoteData.loops,
        modules: resolvedQuoteData.modules,
        switchCount: resolvedQuoteData.switchCount,
        otherDevices: resolvedQuoteData.otherDevices,
        powerSupplies: resolvedQuoteData.powerSupplies,
        boardMaterials: resolvedQuoteData.boardMaterials,
        wiring: resolvedQuoteData.wiring,
        ceilingHasLn: resolvedQuoteData.ceilingHasLn,
        ceilingHasMaintenanceHole: resolvedQuoteData.ceilingHasMaintenanceHole,
        switchHasLn: resolvedQuoteData.switchHasLn,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authService = context.watch<AuthService>();
    final quoteService = context.watch<QuoteService>();
    final currentCustomerUserId = int.tryParse(authService.userId ?? '');
    final configurations = quoteService.configurations.where((configuration) {
      if (currentCustomerUserId == null) {
        return false;
      }
      return configuration.customerUserId == currentCustomerUserId &&
          configuration.isPublished;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的報價單'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadQuotes,
            icon: const Icon(Icons.refresh),
            tooltip: '重新整理',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.primaryContainer.withValues(alpha: 0.25),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadQuotes,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  '客戶報價單',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '這裡會顯示已經發送給你的報價單，你可以查看內容與最後一次修改時間。',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                if (_isLoading && configurations.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_error != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(_error!),
                    ),
                  )
                else if (configurations.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '目前還沒有收到報價單',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '等員工端發送報價後，就會出現在這裡。',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...configurations.map((configuration) {
                    final hasProjectName = (configuration.projectName ?? '')
                        .trim()
                        .isNotEmpty;
                    final hasProjectAddress =
                        (configuration.projectAddress ?? '').trim().isNotEmpty;
                    final hasSentAt = (configuration.sentAt ?? '')
                        .trim()
                        .isNotEmpty;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              configuration.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (hasProjectName) ...[
                              const SizedBox(height: 10),
                              Text('專案名稱：${configuration.projectName!.trim()}'),
                            ],
                            if (hasProjectAddress)
                              Text(
                                '專案地址：${configuration.projectAddress!.trim()}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                Chip(
                                  avatar: const Icon(Icons.schedule, size: 18),
                                  label: Text(
                                    '最後修改 ${_formatTimestamp(configuration.updatedAt)}',
                                  ),
                                ),
                                if (hasSentAt)
                                  Chip(
                                    avatar: const Icon(
                                      Icons.mark_email_read_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      '已發送 ${_formatTimestamp(configuration.sentAt!)}',
                                    ),
                                  ),
                                if (configuration.createdAt.trim().isNotEmpty)
                                  Chip(
                                    avatar: const Icon(Icons.history, size: 18),
                                    label: Text(
                                      '建立 ${_formatTimestamp(configuration.createdAt)}',
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => _openQuote(configuration),
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('查看報價單'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
