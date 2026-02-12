import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/quote_service.dart';
import 'package:coselig_staff_portal/models/quote_models.dart';

class ModuleManagementPage extends StatefulWidget {
  const ModuleManagementPage({super.key});

  @override
  State<ModuleManagementPage> createState() => _ModuleManagementPageState();
}

class _ModuleManagementPageState extends State<ModuleManagementPage> {
  late QuoteService _quoteService;
  List<Map<String, dynamic>> _moduleOptions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _quoteService = Provider.of<QuoteService>(context, listen: false);
    _loadModuleOptions();
  }

  Future<void> _loadModuleOptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final options = await _quoteService.fetchAllModuleOptions();
      setState(() {
        _moduleOptions = options;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addModuleOption() async {
    final result = await showDialog<ModuleOption>(
      context: context,
      builder: (context) => const AddModuleDialog(),
    );

    if (result != null) {
      try {
        await _quoteService.addModuleOption(result);
        await _loadModuleOptions(); // 重新載入列表
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('模組選項已添加')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('添加失敗: $e')),
          );
        }
      }
    }
  }

  Future<void> _editModuleOption(Map<String, dynamic> option) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditModuleDialog(option: option),
    );

    if (result != null) {
      try {
        await _quoteService.updateModuleOption(option['id'], result);
        await _loadModuleOptions(); // 重新載入列表
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('模組選項已更新')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('更新失敗: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteModuleOption(Map<String, dynamic> option) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除模組 "${option['model']}" 嗎？此操作無法撤銷。'),
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
      try {
        await _quoteService.deleteModuleOption(option['id']);
        await _loadModuleOptions(); // 重新載入列表
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('模組選項已刪除')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('刪除失敗: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('模組管理'),
        actions: [
          IconButton(
            onPressed: _addModuleOption,
            icon: const Icon(Icons.add),
            tooltip: '添加模組',
          ),
          IconButton(
            onPressed: _loadModuleOptions,
            icon: const Icon(Icons.refresh),
            tooltip: '重新載入',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('載入失敗: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadModuleOptions,
                        child: const Text('重試'),
                      ),
                    ],
                  ),
                )
              : _moduleOptions.isEmpty
                  ? const Center(child: Text('沒有模組選項'))
                  : ListView.builder(
                      itemCount: _moduleOptions.length,
                      itemBuilder: (context, index) {
                        final option = _moduleOptions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(
                              option['model'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${option['channelCount']} 通道'),
                                Text(option['isDimmable'] ? '可調光' : '不可調光'),
                                Text('每通道最大安培: ${option['maxAmperePerChannel']}A'),
                                Text('模組最大安培: ${option['maxAmpereTotal']}A'),
                        Text('價格: \$${option['price'] ?? 0}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _editModuleOption(option),
                                  icon: const Icon(Icons.edit),
                                  tooltip: '編輯',
                                ),
                                IconButton(
                                  onPressed: () => _deleteModuleOption(option),
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
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

class AddModuleDialog extends StatefulWidget {
  const AddModuleDialog({super.key});

  @override
  State<AddModuleDialog> createState() => _AddModuleDialogState();
}

class _AddModuleDialogState extends State<AddModuleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _channelCountController = TextEditingController();
  final _maxAmperePerChannelController = TextEditingController();
  final _maxAmpereTotalController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isDimmable = true;

  @override
  void dispose() {
    _modelController.dispose();
    _channelCountController.dispose();
    _maxAmperePerChannelController.dispose();
    _maxAmpereTotalController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加模組選項'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: '模組型號',
                  hintText: '例如: P210, P404',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入模組型號';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _channelCountController,
                decoration: const InputDecoration(
                  labelText: '通道數量',
                  hintText: '例如: 2, 4, 8',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入通道數量';
                  }
                  final count = int.tryParse(value);
                  if (count == null || count <= 0) {
                    return '請輸入有效的正整數';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxAmperePerChannelController,
                decoration: const InputDecoration(
                  labelText: '每通道最大安培數',
                  hintText: '例如: 5.0',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入每通道最大安培數';
                  }
                  final ampere = double.tryParse(value);
                  if (ampere == null || ampere <= 0) {
                    return '請輸入有效的正數';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxAmpereTotalController,
                decoration: const InputDecoration(
                  labelText: '模組最大安培數',
                  hintText: '例如: 10.0',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入模組最大安培數';
                  }
                  final ampere = double.tryParse(value);
                  if (ampere == null || ampere <= 0) {
                    return '請輸入有效的正數';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: '價格',
                  hintText: '例如: 1500',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final price = double.tryParse(value);
                    if (price == null || price < 0) {
                      return '請輸入有效的數字';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('可調光'),
                value: _isDimmable,
                onChanged: (value) {
                  setState(() {
                    _isDimmable = value ?? true;
                  });
                },
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
              final option = ModuleOption(
                model: _modelController.text.trim(),
                channelCount: int.parse(_channelCountController.text),
                isDimmable: _isDimmable,
                maxAmperePerChannel: double.parse(_maxAmperePerChannelController.text),
                maxAmpereTotal: double.parse(_maxAmpereTotalController.text),
                price: _priceController.text.isNotEmpty
                    ? double.parse(_priceController.text)
                    : 0.0,
              );
              Navigator.of(context).pop(option);
            }
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}

class EditModuleDialog extends StatefulWidget {
  final Map<String, dynamic> option;

  const EditModuleDialog({super.key, required this.option});

  @override
  State<EditModuleDialog> createState() => _EditModuleDialogState();
}

class _EditModuleDialogState extends State<EditModuleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _modelController;
  late final TextEditingController _channelCountController;
  late final TextEditingController _maxAmperePerChannelController;
  late final TextEditingController _maxAmpereTotalController;
  late final TextEditingController _priceController;
  late bool _isDimmable;

  @override
  void initState() {
    super.initState();
    _modelController = TextEditingController(text: widget.option['model']);
    _channelCountController = TextEditingController(text: widget.option['channelCount'].toString());
    _maxAmperePerChannelController = TextEditingController(text: widget.option['maxAmperePerChannel'].toString());
    _maxAmpereTotalController = TextEditingController(text: widget.option['maxAmpereTotal'].toString());
    _priceController = TextEditingController(
      text: (widget.option['price'] ?? 0).toString(),
    );
    _isDimmable = widget.option['isDimmable'];
  }

  @override
  void dispose() {
    _modelController.dispose();
    _channelCountController.dispose();
    _maxAmperePerChannelController.dispose();
    _maxAmpereTotalController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('編輯模組選項'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: '模組型號',
                  hintText: '例如: P210, P404',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入模組型號';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _channelCountController,
                decoration: const InputDecoration(
                  labelText: '通道數量',
                  hintText: '例如: 2, 4, 8',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入通道數量';
                  }
                  final count = int.tryParse(value);
                  if (count == null || count <= 0) {
                    return '請輸入有效的正整數';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxAmperePerChannelController,
                decoration: const InputDecoration(
                  labelText: '每通道最大安培數',
                  hintText: '例如: 5.0',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入每通道最大安培數';
                  }
                  final ampere = double.tryParse(value);
                  if (ampere == null || ampere <= 0) {
                    return '請輸入有效的正數';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxAmpereTotalController,
                decoration: const InputDecoration(
                  labelText: '模組最大安培數',
                  hintText: '例如: 10.0',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入模組最大安培數';
                  }
                  final ampere = double.tryParse(value);
                  if (ampere == null || ampere <= 0) {
                    return '請輸入有效的正數';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: '價格',
                  hintText: '例如: 1500',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final price = double.tryParse(value);
                    if (price == null || price < 0) {
                      return '請輸入有效的數字';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('可調光'),
                value: _isDimmable,
                onChanged: (value) {
                  setState(() {
                    _isDimmable = value ?? true;
                  });
                },
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
              final updates = {
                'model': _modelController.text.trim(),
                'channelCount': int.parse(_channelCountController.text),
                'isDimmable': _isDimmable,
                'maxAmperePerChannel': double.parse(_maxAmperePerChannelController.text),
                'maxAmpereTotal': double.parse(_maxAmpereTotalController.text),
                'price': _priceController.text.isNotEmpty
                    ? double.parse(_priceController.text)
                    : 0.0,
              };
              Navigator.of(context).pop(updates);
            }
          },
          child: const Text('更新'),
        ),
      ],
    );
  }
}