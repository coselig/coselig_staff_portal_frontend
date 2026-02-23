import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/quote_service.dart';
import 'package:coselig_staff_portal/models/quote_models.dart';

class SwitchManagementPage extends StatefulWidget {
  const SwitchManagementPage({super.key});

  @override
  State<SwitchManagementPage> createState() => _SwitchManagementPageState();
}

class _SwitchManagementPageState extends State<SwitchManagementPage> {
  late QuoteService _quoteService;
  List<SwitchModel> _switches = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _quoteService = Provider.of<QuoteService>(context, listen: false);
    _loadSwitches();
  }

  Future<void> _loadSwitches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final switches = await _quoteService.fetchSwitchOptions();
      setState(() {
        _switches = switches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addSwitch() async {
    final result = await showDialog<SwitchModel>(
      context: context,
      builder: (context) => _AddSwitchDialog(),
    );
    if (result != null) {
      setState(() => _isLoading = true);
      try {
        await _quoteService.addSwitchOption(result);
        await _loadSwitches();
      } catch (e) {
        setState(() => _error = e.toString());
      }
    }
  }

  Future<void> _editSwitch(int index) async {
    final result = await showDialog<SwitchModel>(
      context: context,
      builder: (context) => _AddSwitchDialog(switchModel: _switches[index]),
    );
    if (result != null) {
      setState(() => _isLoading = true);
      try {
        // 需有 id，這裡假設 _switches[index] 有 id 屬性，若無請補上
        final id = _switches[index].id ?? 0;
        await _quoteService.updateSwitchOption(id, result);
        await _loadSwitches();
      } catch (e) {
        setState(() => _error = e.toString());
      }
    }
  }

  Future<void> _deleteSwitch(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除開關 "${_switches[index].name}" 嗎？'),
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
        final id = _switches[index].id ?? 0;
        await _quoteService.deleteSwitchOption(id);
        await _loadSwitches();
      } catch (e) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('開關管理'),
        actions: [
          IconButton(
            onPressed: _addSwitch,
            icon: const Icon(Icons.add),
            tooltip: '新增開關',
          ),
          IconButton(
            onPressed: _loadSwitches,
            icon: const Icon(Icons.refresh),
            tooltip: '重新載入',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('載入失敗: $_error'))
              : _switches.isEmpty
                  ? const Center(child: Text('沒有開關資料'))
                  : ListView.builder(
                      itemCount: _switches.length,
                      itemBuilder: (context, index) {
                        final sw = _switches[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(sw.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('數量: ${sw.count}'),
                                Text('位置: ${sw.location}'),
                                if (sw.price > 0) Text('價格: ${sw.price}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editSwitch(index),
                                  tooltip: '編輯',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () => _deleteSwitch(index),
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

class _AddSwitchDialog extends StatefulWidget {
  final SwitchModel? switchModel;
  const _AddSwitchDialog({this.switchModel});

  @override
  State<_AddSwitchDialog> createState() => _AddSwitchDialogState();
}

class _AddSwitchDialogState extends State<_AddSwitchDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _countController;
  late final TextEditingController _priceController;
  late final TextEditingController _locationController;

  int? _id;

  @override
  void initState() {
    super.initState();
    _id = widget.switchModel?.id;
    _nameController = TextEditingController(text: widget.switchModel?.name ?? '');
    _countController = TextEditingController(text: widget.switchModel?.count.toString() ?? '1');
    _priceController = TextEditingController(text: widget.switchModel?.price.toString() ?? '');
    _locationController = TextEditingController(text: widget.switchModel?.location ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.switchModel == null ? '新增開關' : '編輯開關'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '名稱'),
                validator: (v) => v == null || v.isEmpty ? '請輸入名稱' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countController,
                decoration: const InputDecoration(labelText: '數量'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || int.tryParse(v) == null ? '請輸入有效數字' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: '價格'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: '位置'),
              ),
            ],
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
              final model = SwitchModel(
                id: _id,
                name: _nameController.text.trim(),
                count: int.tryParse(_countController.text.trim()) ?? 1,
                price: double.tryParse(_priceController.text.trim()) ?? 0.0,
                location: _locationController.text.trim(),
              );
              Navigator.of(context).pop(model);
            }
          },
          child: const Text('儲存'),
        ),
      ],
    );
  }
}
