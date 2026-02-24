import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/quote_service.dart';

/// 設定檔格式
/// {
///   'table': 'switch_options',
///   'columns': [
///     {'name': 'name', 'label': '名稱', 'type': 'text'},
///     {'name': 'count', 'label': '數量', 'type': 'number'},
///     {'name': 'price', 'label': '價格', 'type': 'number'},
///     {'name': 'location', 'label': '位置', 'type': 'text'},
///   ],
///   'fetch': (QuoteService service) => service.fetchSwitchOptions(),
///   'add': (QuoteService service, Map<String, dynamic> data) => service.addSwitchOption(data),
///   'update': (QuoteService service, int id, Map<String, dynamic> data) => service.updateSwitchOption(id, data),
///   'delete': (QuoteService service, int id) => service.deleteSwitchOption(id),
/// }

class GenericManagementPage extends StatefulWidget {
  final Map<String, dynamic> config;
  const GenericManagementPage({required this.config, super.key});

  @override
  State<GenericManagementPage> createState() => _GenericManagementPageState();
}

class _GenericManagementPageState extends State<GenericManagementPage> {
  late QuoteService _quoteService;
  List<dynamic> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _quoteService = Provider.of<QuoteService>(context, listen: false);
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final fetchFn = widget.config['fetch'] as Future<List<dynamic>> Function(QuoteService);
      final items = await fetchFn(_quoteService);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addItem() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _GenericEditDialog(columns: widget.config['columns']),
    );
    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final addFn = widget.config['add'] as Future<void> Function(QuoteService, Map<String, dynamic>);
        await addFn(_quoteService, result);
        await _loadItems();
      } catch (e) {
        setState(() => _error = e.toString());
      }
    }
  }

  Future<void> _editItem(int index) async {
    final item = _items[index];
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _GenericEditDialog(
        columns: widget.config['columns'],
        initial: item is Map<String, dynamic> ? item : item.toJson(),
      ),
    );
    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final updateFn = widget.config['update'] as Future<void> Function(QuoteService, int, Map<String, dynamic>);
        final id = item['id'] ?? (item is Map ? item['id'] : item.id);
        await updateFn(_quoteService, id, result);
        await _loadItems();
      } catch (e) {
        setState(() => _error = e.toString());
      }
    }
  }

  Future<void> _deleteItem(int index) async {
    final item = _items[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final deleteFn = widget.config['delete'] as Future<void> Function(QuoteService, int);
        final id = item['id'] ?? (item is Map ? item['id'] : item.id);
        await deleteFn(_quoteService, id);
        await _loadItems();
      } catch (e) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config['title'] ?? '資料管理'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            tooltip: '新增',
          ),
          IconButton(
            onPressed: _loadItems,
            icon: const Icon(Icons.refresh),
            tooltip: '重新載入',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('載入失敗: $_error'))
              : _items.isEmpty
                  ? const Center(child: Text('沒有資料'))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index] is Map<String, dynamic>
                            ? _items[index]
                            : _items[index].toJson();
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(item[widget.config['columns'][0]['name']].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: widget.config['columns'].skip(1).map<Widget>((col) {
                                final value = item[col['name']];
                                return Text('${col['label']}: $value');
                              }).toList(),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editItem(index),
                                  tooltip: '編輯',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () => _deleteItem(index),
                                  tooltip: '刪除',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _GenericEditDialog extends StatefulWidget {
  final List<Map<String, dynamic>> columns;
  final Map<String, dynamic>? initial;
  const _GenericEditDialog({required this.columns, this.initial});

  @override
  State<_GenericEditDialog> createState() => _GenericEditDialogState();
}

class _GenericEditDialogState extends State<_GenericEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (var col in widget.columns)
        col['name']: TextEditingController(text: widget.initial?[col['name']]?.toString() ?? ''),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? '新增資料' : '編輯資料'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.columns.map<Widget>((col) {
              if (col['type'] == 'dropdown') {
                final List<String> options = List<String>.from(
                  col['options'] ?? [],
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: DropdownButtonFormField<String>(
                    initialValue: _controllers[col['name']]!.text.isNotEmpty
                        ? _controllers[col['name']]!.text
                        : (options.isNotEmpty ? options[0] : null),
                    decoration: InputDecoration(labelText: col['label']),
                    items: options
                        .map(
                          (opt) =>
                              DropdownMenuItem(value: opt, child: Text(opt)),
                        )
                        .toList(),
                    onChanged: (val) => setState(
                      () => _controllers[col['name']]!.text = val ?? '',
                    ),
                    validator: (v) =>
                        (col['required'] ?? true) && (v == null || v.isEmpty)
                        ? '必填'
                        : null,
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextFormField(
                    controller: _controllers[col['name']],
                    decoration: InputDecoration(labelText: col['label']),
                    keyboardType: col['type'] == 'number'
                        ? TextInputType.number
                        : TextInputType.text,
                    validator: (v) =>
                        (col['required'] ?? true) && (v == null || v.isEmpty)
                        ? '必填'
                        : null,
                  ),
                );
              }
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final data = {
                for (var col in widget.columns)
                  col['name']: col['type'] == 'number'
                      ? (double.tryParse(_controllers[col['name']]!.text) ?? 0)
                      : _controllers[col['name']]!.text.trim(),
              };
              Navigator.of(context).pop(data);
            }
          },
          child: const Text('儲存'),
        ),
      ],
    );
  }
}
