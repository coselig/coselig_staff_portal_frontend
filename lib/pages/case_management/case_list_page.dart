import 'package:coselig_staff_portal/services/customer_service.dart';
import 'package:coselig_staff_portal/services/project_case_service.dart';
import 'package:coselig_staff_portal/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/main.dart';

class CaseListPage extends StatefulWidget {
  const CaseListPage({super.key});

  @override
  State<CaseListPage> createState() => _CaseListPageState();
}

class _CaseListPageState extends State<CaseListPage> {
  late final ProjectCaseService _service;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _service = context.read<ProjectCaseService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _service.fetchCases();
    });
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProjectCase> get _filteredCases {
    if (_searchQuery.isEmpty) return _service.cases;
    return _service.cases.where((c) {
      return c.name.toLowerCase().contains(_searchQuery) ||
          (c.customerCompany?.toLowerCase().contains(_searchQuery) ?? false) ||
          (c.customerChineseName?.toLowerCase().contains(_searchQuery) ??
              false) ||
          (c.customerName?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }

  void _openCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _CreateCaseDialog(service: _service),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('案件管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新整理',
            onPressed: () => _service.fetchCases(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('新增案件'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜尋案件名稱或客戶...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _service,
              builder: (context, _) {
                if (_service.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_service.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_service.errorMessage!,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _service.fetchCases(),
                          child: const Text('重試'),
                        ),
                      ],
                    ),
                  );
                }
                final items = _filteredCases;
                if (items.isEmpty) {
                  return const Center(child: Text('目前沒有案件'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final c = items[index];
                    return _CaseCard(
                      projectCase: c,
                      onTap: () => navigatorKey.currentState!
                          .pushNamed('/cases/${c.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final ProjectCase projectCase;
  final VoidCallback onTap;

  const _CaseCard({required this.projectCase, required this.onTap});

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return '進行中';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor:
              _statusColor(projectCase.status).withValues(alpha: 0.15),
          child: Icon(Icons.folder_open,
              color: _statusColor(projectCase.status)),
        ),
        title: Text(projectCase.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('客戶：${projectCase.customerDisplayName}'),
            Text('快照：${projectCase.snapshotCount} 份 ｜ 建立者：${projectCase.creatorDisplayName}'),
          ],
        ),
        trailing: Chip(
          label: Text(_statusLabel(projectCase.status),
              style: const TextStyle(fontSize: 11)),
          backgroundColor:
              _statusColor(projectCase.status).withValues(alpha: 0.15),
          side: BorderSide.none,
          padding: EdgeInsets.zero,
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _CreateCaseDialog extends StatefulWidget {
  final ProjectCaseService service;

  const _CreateCaseDialog({required this.service});

  @override
  State<_CreateCaseDialog> createState() => _CreateCaseDialogState();
}

class _CreateCaseDialogState extends State<_CreateCaseDialog> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  int? _selectedCustomerId;
  bool _saving = false;
  late final CustomerService _customerService;

  @override
  void initState() {
    super.initState();
    _customerService = context.read<CustomerService>();
    if (_customerService.customers.isEmpty) {
      _customerService.fetchCustomers();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final id = await widget.service.createCase(
      name: _nameController.text.trim(),
      customerId: _selectedCustomerId,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (id != null) {
      Navigator.of(context).pop();
      navigatorKey.currentState!.pushNamed('/cases/$id');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('建立失敗，請重試')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新增案件'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '案件名稱 *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: _customerService,
              builder: (context, _) {
                final customers = _customerService.customers;
                return DropdownButtonFormField<int?>(
                  initialValue: _selectedCustomerId,
                  decoration: const InputDecoration(
                    labelText: '關聯客戶（選填）',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                        value: null, child: Text('不指定')),
                    ...customers.map((c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(
                              '${c.chineseName ?? c.name}${c.company != null ? ' (${c.company})' : ''}'),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedCustomerId = v),
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '備註（選填）',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('建立'),
        ),
      ],
    );
  }
}
