import 'dart:convert';
import 'package:coselig_staff_portal/services/quote_service.dart';
import 'package:coselig_staff_portal/pages/customer/customer_quote_builder_page.dart';
import 'package:coselig_staff_portal/pages/staff/discovery_generate_page.dart';
import 'package:coselig_staff_portal/pages/staff/smart_home_assessment_page.dart';
import 'package:coselig_staff_portal/services/project_case_service.dart';
import 'package:coselig_staff_portal/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CaseDetailPage extends StatefulWidget {
  final int caseId;

  const CaseDetailPage({super.key, required this.caseId});

  @override
  State<CaseDetailPage> createState() => _CaseDetailPageState();
}

class _CaseDetailPageState extends State<CaseDetailPage> {
  late final ProjectCaseService _service;
  ProjectCase? _case;
  List<QuoteSnapshot> _snapshots = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = context.read<ProjectCaseService>();
    _load();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除案件'),
        content: const Text('確定要刪除此案件？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await _service.deleteCase(widget.caseId);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _loading = false;
        _error = '刪除失敗，請重試';
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final c = await _service.fetchCaseById(widget.caseId);
    final snaps = await _service.fetchSnapshots(widget.caseId);
    if (!mounted) return;
    setState(() {
      _case = c;
      _snapshots = snaps;
      _loading = false;
      if (c == null) _error = '找不到此案件';
    });
  }

  void _openQuoteBuilder() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CustomerQuoteBuilderPage(caseId: widget.caseId),
      ),
    );
  }

  void _openAssessment() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SmartHomeAssessmentPage(),
      ),
    );
  }

  void _openDiscovery() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DiscoveryGeneratePage(),
      ),
    );
  }

  Future<void> _showDeleteSnapshotConfirm(QuoteSnapshot snap) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除版本'),
        content: Text('確定要刪除版本「${snap.label}」嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteSnapshot(widget.caseId, snap.id);
      await _load();
    }
  }

  Future<void> _loadSnapshot(QuoteSnapshot snap) async {
    final full = await _service.fetchSnapshotById(widget.caseId, snap.id);
    if (!mounted || full == null || full.quoteData == null) return;

    QuoteData? quoteData;
    try {
      final decoded = jsonDecode(full.quoteData!);
      quoteData = QuoteData.fromJson(decoded is Map<String, dynamic>
          ? decoded
          : jsonDecode(decoded));
    } catch (_) {}

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('版本：${snap.label}'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('儲存時間：${snap.createdAt}'),
                Text('儲存者：${snap.creatorDisplayName}'),
                const Divider(),
                if (quoteData != null) ...[
                  Text('迴路數：${quoteData.loops.length}'),
                  Text('模組數：${quoteData.modules.length}'),
                  Text('電源供應器：${quoteData.powerSupplies.length}'),
                ] else
                  const Text('無法解析估價資料'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    if (_case == null) return;
    final nameCtrl = TextEditingController(text: _case!.name);
    final notesCtrl = TextEditingController(text: _case!.notes ?? '');
    String selectedStatus = _case!.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('編輯案件'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '案件名稱',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: '狀態',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('進行中')),
                    DropdownMenuItem(
                        value: 'completed', child: Text('已完成')),
                    DropdownMenuItem(
                        value: 'cancelled', child: Text('已取消')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedStatus = v ?? selectedStatus),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: '備註',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _service.updateCase(
                  widget.caseId,
                  name: nameCtrl.text.trim(),
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                  status: selectedStatus,
                );
                await _load();
              },
              child: const Text('儲存'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_case?.displayName ?? '案件'),
        actions: [
          if (_case != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: '編輯案件',
              onPressed: _showEditDialog,
            ),
          if (_case != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '刪除案件',
              onPressed: _confirmDelete,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新整理',
            onPressed: _load,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final c = _case!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 基本資訊
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.folder_open),
                    const SizedBox(width: 8),
                    Text(c.displayName,
                        style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    _StatusChip(status: c.status),
                  ],
                ),
                const Divider(height: 20),
                _InfoRow(label: '客戶', value: c.customerDisplayName),
                if (c.customerEmail != null)
                  _InfoRow(label: 'Email', value: c.customerEmail!),
                if (c.customerPhone != null)
                  _InfoRow(label: '電話', value: c.customerPhone!),
                _InfoRow(label: '建立者', value: c.creatorDisplayName),
                _InfoRow(label: '建立時間', value: c.createdAt),
                if (c.notes != null && c.notes!.isNotEmpty)
                  _InfoRow(label: '備註', value: c.notes!),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 三個工具入口
        Text('工具', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ToolCard(
                icon: Icons.calculate,
                label: '估價系統',
                description: '編輯迴路、模組與報價',
                onTap: _openQuoteBuilder,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ToolCard(
                icon: Icons.fact_check_outlined,
                label: '現場評估表',
                description: '智慧型住宅確認表',
                onTap: _openAssessment,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ToolCard(
                icon: Icons.build,
                label: '註冊表生成器',
                description: '產生裝置 Discovery 設定',
                onTap: _openDiscovery,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 估價版本歷程
        Row(
          children: [
            Text('估價版本歷程',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text('${_snapshots.length} 份',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),

        if (_snapshots.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('尚無估價版本\n進入估價系統後，點選「儲存此版本」即可建立快照',
                  textAlign: TextAlign.center),
            ),
          )
        else
          ...List.generate(_snapshots.length, (i) {
            final snap = _snapshots[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  child: Text('${i + 1}',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer)),
                ),
                title: Text(snap.label),
                subtitle: Text(
                    '${snap.createdAt}  ·  ${snap.creatorDisplayName}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined),
                      tooltip: '檢視',
                      onPressed: () => _loadSnapshot(snap),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error),
                      tooltip: '刪除',
                      onPressed: () => _showDeleteSnapshotConfirm(snap),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color _color(BuildContext context) {
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

  String get _label {
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
    return Chip(
      label: Text(_label, style: const TextStyle(fontSize: 12)),
      backgroundColor: _color(context).withValues(alpha: 0.15),
      side: BorderSide.none,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text('$label：',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6))),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(description,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
