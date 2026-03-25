import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/services/discovery_service.dart';
import 'package:coselig_staff_portal/utils/icon_utils.dart';

class DeviceConfigManagementPage extends StatefulWidget {
  const DeviceConfigManagementPage({super.key});

  @override
  State<DeviceConfigManagementPage> createState() =>
      _DeviceConfigManagementPageState();
}

class _DeviceConfigManagementPageState
    extends State<DeviceConfigManagementPage> {
  final DiscoveryService _service = DiscoveryService();
  bool _isLoading = true;
  String? _error;

  List<String> _availableBrands() {
    final brands = _service.deviceConfigOptions
        .map((e) => e.brand.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    brands.sort();
    return brands;
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _service.fetchDeviceConfigOptions();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addItem() async {
    final result = await showDialog<DeviceConfigOption>(
      context: context,
      builder: (context) => _DeviceConfigEditDialog(
        availableBrands: _availableBrands(),
      ),
    );
    if (result != null) {
      setState(() => _isLoading = true);
      try {
        await _service.addDeviceConfigOption(result);
        await _loadItems();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('新增失敗: $e')),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editItem(DeviceConfigOption item) async {
    final result = await showDialog<DeviceConfigOption>(
      context: context,
      builder: (context) => _DeviceConfigEditDialog(
        initial: item,
        availableBrands: _availableBrands(),
      ),
    );
    if (result != null && item.id != null) {
      setState(() => _isLoading = true);
      try {
        await _service.updateDeviceConfigOption(item.id!, result.toJson());
        await _loadItems();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('更新失敗: $e')),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteItem(DeviceConfigOption item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除 ${item.brand} / ${item.model} 嗎？'),
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
    if (confirmed == true && item.id != null) {
      setState(() => _isLoading = true);
      try {
        await _service.deleteDeviceConfigOption(item.id!);
        await _loadItems();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('刪除失敗: $e')),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _service.deviceConfigOptions;

    // 按品牌分組
    final groupedByBrand = <String, List<DeviceConfigOption>>{};
    for (final item in items) {
      groupedByBrand.putIfAbsent(item.brand, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('裝置設定管理'),
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
              : items.isEmpty
                  ? const Center(child: Text('沒有裝置設定資料'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: groupedByBrand.entries.map((entry) {
                        final brand = entry.key;
                        final models = entry.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                '品牌: $brand',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            ...models.map(
                              (item) => _buildItemCard(item),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }).toList(),
                    ),
    );
  }

  Widget _buildItemCard(DeviceConfigOption item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(
          item.model,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('類型: ${item.types.join(', ')}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editItem(item),
              tooltip: '編輯',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.red,
              onPressed: () => _deleteItem(item),
              tooltip: '刪除',
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('通道配置 (Channels)'),
                ...item.channels.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Text('${e.key}: ${e.value.join(', ')}'),
                    )),
                const SizedBox(height: 8),
                _buildSectionTitle('通道映射 (Channel Map)'),
                if (item.channelMap.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text('無映射', style: TextStyle(color: Colors.grey)),
                  )
                else
                  ...item.channelMap.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 4),
                        child: Text('${e.key} → ${e.value.join(', ')}'),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

// ===== 編輯對話框 =====

class _DeviceConfigEditDialog extends StatefulWidget {
  final DeviceConfigOption? initial;
  final List<String> availableBrands;

  const _DeviceConfigEditDialog({
    this.initial,
    required this.availableBrands,
  });

  @override
  State<_DeviceConfigEditDialog> createState() =>
      _DeviceConfigEditDialogState();
}

class _DeviceConfigEditDialogState extends State<_DeviceConfigEditDialog> {
  static const String _customBrandOption = '__custom_brand__';

  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late List<String> _types;
  late Map<String, List<String>> _channels;
  late Map<String, List<String>> _channelMap;

  // 用於新增 type
  final TextEditingController _newTypeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _brandController = TextEditingController(text: init?.brand ?? '');
    _modelController = TextEditingController(text: init?.model ?? '');
    _types = List<String>.from(init?.types ?? []);
    _channels = init?.channels.map(
          (k, v) => MapEntry(k, List<String>.from(v)),
        ) ??
        {};
    _channelMap = init?.channelMap.map(
          (k, v) => MapEntry(k, List<String>.from(v)),
        ) ??
        {};
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _newTypeController.dispose();
    super.dispose();
  }

  void _addType() {
    final type = _newTypeController.text.trim();
    if (type.isNotEmpty && !_types.contains(type)) {
      setState(() {
        _types.add(type);
        _channels[type] = [];
      });
      _newTypeController.clear();
    }
  }

  void _removeType(String type) {
    setState(() {
      _types.remove(type);
      _channels.remove(type);
      // 清理 channelMap 中相關的通道
    });
  }

  void _editChannelsForType(String type) async {
    final currentChannels = _channels[type] ?? [];
    final controller =
        TextEditingController(text: currentChannels.join(', '));

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('編輯 "$type" 的通道'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '通道列表',
            hintText: '用逗號分隔，例如: a, b, c',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('確定'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _channels[type] = result
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      });
    }
  }

  void _editChannelMap() async {
    // 構建當前 channelMap 的文字表示
    final lines = _channelMap.entries
        .map((e) => '${e.key}: ${e.value.join(',')}')
        .join('\n');
    final controller = TextEditingController(text: lines);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('編輯通道映射'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: '通道映射',
              hintText: '每行一組，格式: token: ch1,ch2\n例如:\na: 1,2\nb: 3,4',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('確定'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _channelMap.clear();
        for (final line in result.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          final parts = trimmed.split(':');
          if (parts.length >= 2) {
            final key = parts[0].trim();
            final values = parts.sublist(1).join(':').split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
            if (key.isNotEmpty && values.isNotEmpty) {
              _channelMap[key] = values;
            }
          }
        }
      });
    }
  }

  Future<String?> _showBrandInputDialog(String initialValue) async {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增 Brand'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Brand',
            hintText: '請輸入品牌',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final brand = controller.text.trim();
              if (brand.isNotEmpty) {
                Navigator.pop(context, brand);
              }
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBrandSelection(String? newValue) async {
    if (newValue == _customBrandOption) {
      final newBrand = await _showBrandInputDialog(_brandController.text);
      if (newBrand != null && newBrand.isNotEmpty) {
        setState(() {
          _brandController.text = newBrand;
        });
      }
      return;
    }

    setState(() {
      _brandController.text = newValue ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final currentBrand = _brandController.text.trim();
    final brandValue = currentBrand.isEmpty ? null : currentBrand;

    return AlertDialog(
      title: Text(isEdit ? '編輯裝置設定' : '新增裝置設定'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand & Model
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: brandValue,
                      decoration: const InputDecoration(
                        labelText: '品牌 (Brand)',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('選擇品牌'),
                      onChanged: (String? newValue) {
                        _handleBrandSelection(newValue);
                      },
                      items: [
                        ...widget.availableBrands.map<DropdownMenuItem<String>>((value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }),
                        if (currentBrand.isNotEmpty &&
                            !widget.availableBrands.contains(currentBrand))
                          DropdownMenuItem<String>(
                            value: currentBrand,
                            child: Text(currentBrand),
                          ),
                        const DropdownMenuItem<String>(
                          value: _customBrandOption,
                          child: Text('＋新增 Brand'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: '型號 (Model)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Types
              const Text(
                '類型 (Types)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _types.map((type) {
                  return InputChip(
                    label: Text(type),
                    onDeleted: () => _removeType(type),
                    onPressed: () => _editChannelsForType(type),
                    tooltip: '點擊編輯通道，×刪除',
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newTypeController,
                      decoration: const InputDecoration(
                        hintText: '新增類型 (如: dual, single, rgb)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addType(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addType,
                    icon: const Icon(Icons.add_circle),
                    tooltip: '新增類型',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Channels preview
              const Text(
                '通道配置 (Channels)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              if (_channels.isEmpty)
                const Text(
                  '請先新增類型，再點擊類型標籤來編輯通道',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                )
              else
                ..._channels.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 2),
                      child: InkWell(
                        onTap: () => _editChannelsForType(e.key),
                        child: Row(
                          children: [
                            Text(
                              '${e.key}: ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Expanded(
                              child: Text(
                                e.value.isEmpty
                                    ? '(未設定，點擊編輯)'
                                    : e.value.join(', '),
                                style: TextStyle(
                                  color: e.value.isEmpty
                                      ? Colors.orange
                                      : null,
                                ),
                              ),
                            ),
                          Icon(Icons.edit, size: context.scaledIconSize(14)),
                          ],
                        ),
                      ),
                    )),
              const SizedBox(height: 16),

              // Channel Map
              Row(
                children: [
                  const Text(
                    '通道映射 (Channel Map)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _editChannelMap,
                    icon: Icon(Icons.edit, size: context.scaledIconSize(18)),
                    tooltip: '編輯通道映射',
                  ),
                ],
              ),
              if (_channelMap.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    '無映射（如 relay 類型不需要映射）',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                )
              else
                ...(_channelMap.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 2),
                      child: Text('${e.key} → ${e.value.join(', ')}'),
                    ))),
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
            final brand = _brandController.text.trim();
            final model = _modelController.text.trim();
            if (brand.isEmpty || model.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('品牌和型號不可為空')),
              );
              return;
            }
            if (_types.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('至少需要一個類型')),
              );
              return;
            }

            Navigator.of(context).pop(
              DeviceConfigOption(
                brand: brand,
                model: model,
                types: _types,
                channels: _channels,
                channelMap: _channelMap,
              ),
            );
          },
          child: Text(isEdit ? '更新' : '新增'),
        ),
      ],
    );
  }
}
