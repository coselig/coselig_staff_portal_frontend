import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/quote_service.dart';
import 'package:coselig_staff_portal/models/quote_models.dart';

class FixtureTypeManagementPage extends StatefulWidget {
  const FixtureTypeManagementPage({super.key});

  @override
  State<FixtureTypeManagementPage> createState() =>
      _FixtureTypeManagementPageState();
}

class _FixtureTypeManagementPageState extends State<FixtureTypeManagementPage> {
  late QuoteService _quoteService;
  List<Map<String, dynamic>> _fixtureTypes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _quoteService = Provider.of<QuoteService>(context, listen: false);
    _loadFixtureTypes();
  }

  Future<void> _loadFixtureTypes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final options = await _quoteService.fetchAllFixtureTypeOptions();
      setState(() {
        _fixtureTypes = options;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addFixtureType() async {
    final result = await showDialog<FixtureTypeData>(
      context: context,
      builder: (context) => const _AddFixtureTypeDialog(),
    );

    if (result != null) {
      try {
        await _quoteService.addFixtureTypeOption(result);
        await _loadFixtureTypes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('燈具類型已添加')),
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

  Future<void> _editFixtureType(Map<String, dynamic> option) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _EditFixtureTypeDialog(option: option),
    );

    if (result != null) {
      try {
        await _quoteService.updateFixtureTypeOption(option['id'], result);
        await _loadFixtureTypes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('燈具類型已更新')),
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

  Future<void> _deleteFixtureType(Map<String, dynamic> option) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除燈具類型 "${option['type']}" 嗎？此操作無法撤銷。'),
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
        await _quoteService.deleteFixtureTypeOption(option['id']);
        await _loadFixtureTypes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('燈具類型已刪除')),
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
        title: const Text('燈具類型管理'),
        actions: [
          IconButton(
            onPressed: _addFixtureType,
            icon: const Icon(Icons.add),
            tooltip: '添加燈具類型',
          ),
          IconButton(
            onPressed: _loadFixtureTypes,
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
                        onPressed: _loadFixtureTypes,
                        child: const Text('重試'),
                      ),
                    ],
                  ),
                )
              : _fixtureTypes.isEmpty
                  ? const Center(child: Text('沒有燈具類型'))
                  : ListView.builder(
                      itemCount: _fixtureTypes.length,
                      itemBuilder: (context, index) {
                        final option = _fixtureTypes[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: Icon(
                              option['isMeterBased'] == true
                                  ? Icons.straighten
                                  : Icons.lightbulb_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              option['type'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '數量標籤: ${option['quantityLabel'] ?? ''}',
                                ),
                                Text('單位標籤: ${option['unitLabel'] ?? ''}'),
                                Text(
                                  option['isMeterBased'] == true
                                      ? '以米計算'
                                      : '以數量計算',
                                ),
                        Text(
                          '價格: \$${(option['price'] ?? 0.0).toStringAsFixed(1)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text('預設每單位瓦數: ${option['defaultUnitWatt'] ?? 0} W'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _editFixtureType(option),
                                  icon: const Icon(Icons.edit),
                                  tooltip: '編輯',
                                ),
                                IconButton(
                                  onPressed: () => _deleteFixtureType(option),
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

class _AddFixtureTypeDialog extends StatefulWidget {
  const _AddFixtureTypeDialog();

  @override
  State<_AddFixtureTypeDialog> createState() => _AddFixtureTypeDialogState();
}

class _AddFixtureTypeDialogState extends State<_AddFixtureTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _quantityLabelController = TextEditingController(text: '燈具數量');
  final _unitLabelController = TextEditingController(text: '每顆瓦數 (W)');
  final _priceController = TextEditingController(text: '0.0');
  final _defaultUnitWattController = TextEditingController(text: '0');
  bool _isMeterBased = false;

  @override
  void dispose() {
    _typeController.dispose();
    _quantityLabelController.dispose();
    _unitLabelController.dispose();
    _priceController.dispose();
    _defaultUnitWattController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加燈具類型'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: '類型名稱',
                  hintText: '例如：壁燈',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入類型名稱';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityLabelController,
                decoration: const InputDecoration(
                  labelText: '數量標籤',
                  hintText: '例如：燈具數量、米數',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入數量標籤';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitLabelController,
                decoration: const InputDecoration(
                  labelText: '單位標籤',
                  hintText: '例如：每顆瓦數 (W)、每米瓦數 (W/m)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入單位標籤';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('以米計算（支援小數）'),
                value: _isMeterBased,
                onChanged: (value) {
                  setState(() {
                    _isMeterBased = value ?? false;
                    if (_isMeterBased) {
                      _quantityLabelController.text = '米數';
                      _unitLabelController.text = '每米瓦數 (W/m)';
                    } else {
                      _quantityLabelController.text = '燈具數量';
                      _unitLabelController.text = '每顆瓦數 (W)';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: '價格',
                  hintText: '例如：100.0',
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return '請輸入有效的數字';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _defaultUnitWattController,
                decoration: const InputDecoration(
                  labelText: '預設每單位瓦數 (W)',
                  hintText: '例如：10',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (int.tryParse(value) == null) {
                      return '請輸入有效的整數';
                    }
                  }
                  return null;
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
              final option = FixtureTypeData(
                type: _typeController.text.trim(),
                quantityLabel: _quantityLabelController.text.trim(),
                unitLabel: _unitLabelController.text.trim(),
                isMeterBased: _isMeterBased,
                price: double.tryParse(_priceController.text.trim()) ?? 0.0,
                defaultUnitWatt:
                    int.tryParse(_defaultUnitWattController.text.trim()) ?? 0,
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

class _EditFixtureTypeDialog extends StatefulWidget {
  final Map<String, dynamic> option;

  const _EditFixtureTypeDialog({required this.option});

  @override
  State<_EditFixtureTypeDialog> createState() => _EditFixtureTypeDialogState();
}

class _EditFixtureTypeDialogState extends State<_EditFixtureTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _typeController;
  late final TextEditingController _quantityLabelController;
  late final TextEditingController _unitLabelController;
  late final TextEditingController _priceController;
  late final TextEditingController _defaultUnitWattController;
  late bool _isMeterBased;

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController(text: widget.option['type']);
    _quantityLabelController = TextEditingController(
      text: widget.option['quantityLabel'] ?? '燈具數量',
    );
    _unitLabelController = TextEditingController(
      text: widget.option['unitLabel'] ?? '每顆瓦數 (W)',
    );
    _priceController = TextEditingController(
      text: (widget.option['price'] ?? 0.0).toString(),
    );
    _defaultUnitWattController = TextEditingController(
      text: (widget.option['defaultUnitWatt'] ?? 0).toString(),
    );
    _isMeterBased = widget.option['isMeterBased'] ?? false;
  }

  @override
  void dispose() {
    _typeController.dispose();
    _quantityLabelController.dispose();
    _unitLabelController.dispose();
    _priceController.dispose();
    _defaultUnitWattController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('編輯燈具類型'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: '類型名稱',
                  hintText: '例如：壁燈',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入類型名稱';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityLabelController,
                decoration: const InputDecoration(
                  labelText: '數量標籤',
                  hintText: '例如：燈具數量、米數',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入數量標籤';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitLabelController,
                decoration: const InputDecoration(
                  labelText: '單位標籤',
                  hintText: '例如：每顆瓦數 (W)、每米瓦數 (W/m)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入單位標籤';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('以米計算（支援小數）'),
                value: _isMeterBased,
                onChanged: (value) {
                  setState(() {
                    _isMeterBased = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: '價格',
                  hintText: '例如：100.0',
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return '請輸入有效的數字';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _defaultUnitWattController,
                decoration: const InputDecoration(
                  labelText: '預設每單位瓦數 (W)',
                  hintText: '例如：10',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (int.tryParse(value) == null) {
                      return '請輸入有效的整數';
                    }
                  }
                  return null;
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
                'type': _typeController.text.trim(),
                'quantityLabel': _quantityLabelController.text.trim(),
                'unitLabel': _unitLabelController.text.trim(),
                'isMeterBased': _isMeterBased,
                'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
                'defaultUnitWatt':
                    int.tryParse(_defaultUnitWattController.text.trim()) ?? 0,
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
