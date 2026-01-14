import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coselig_staff_portal/widgets/theme_toggle_switch.dart';
import 'package:coselig_staff_portal/services/discovery_service.dart';

class DiscoveryGeneratePage extends StatefulWidget {
  const DiscoveryGeneratePage({super.key});

  @override
  State<DiscoveryGeneratePage> createState() => _DiscoveryGeneratePageState();
}

class _DiscoveryGeneratePageState extends State<DiscoveryGeneratePage> {
  final DiscoveryService _service = DiscoveryService();
  List<String> get brands => _service.brands;
  Map<String, List<String>> get models => _service.models;

  @override
  void initState() {
    super.initState();
    html.document.title = '裝置註冊表生成器';
    _service.addListener(_update);

    // 檢查是否已登入
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _service.fetchConfigurations(); // 加載所有配置列表
    });

    // 監聽Module ID輸入變化
    moduleIdController.addListener(() {
      setState(() {
        _currentModuleId = moduleIdController.text;
        if (_currentModuleId.isNotEmpty) {
          final selectable = _service.getSelectableChannelsForModule(
            selectedBrand,
            selectedModel,
            selectedType,
            _currentModuleId,
          );
          if (!selectable.contains(selectedChannel)) {
            selectedChannel = selectable.isNotEmpty
                ? selectable.first
                : getAvailableChannels(
                    selectedBrand,
                    selectedModel,
                    selectedType,
                  ).first;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    moduleIdController.dispose();
    nameController.dispose();
    tcpController.dispose();
    _service.removeListener(_update);
    super.dispose();
  }

  void _update() {
    setState(() {});
  }

  String selectedBrand = 'sunwave';
  String selectedModel = 'p404';
  String selectedType = 'single';
  String selectedChannel = '1';
  final TextEditingController moduleIdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController tcpController = TextEditingController();

  // Configuration management
  String? _selectedConfiguration = '新配置';

  // 用於跟踪Module ID輸入的狀態
  String _currentModuleId = '';

  List<String> getAvailableChannels(String brand, String model, String type) {
    return _service.getAvailableChannels(brand, model, type);
  }

  List<String> getAvailableTypes(String brand, String model) {
    return _service.getAvailableTypes(brand, model);
  }

  void addDevice() {
    if (moduleIdController.text.isNotEmpty && nameController.text.isNotEmpty) {
      final newDevice = Device(
        brand: selectedBrand,
        model: selectedModel,
        type: selectedType,
        moduleId: moduleIdController.text,
        channel: selectedChannel,
        name: nameController.text,
        tcp: tcpController.text,
      );

      // 檢查是否可以添加裝置
      if (!_service.canAddDevice(newDevice)) {
        // 顯示錯誤信息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('無法添加裝置：此模組ID的所有通道都已被使用'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      _service.addDevice(newDevice);
      moduleIdController.clear();
      nameController.clear();
      tcpController.clear();

      // 自動儲存配置
      _autoSaveConfiguration();
    }
  }

  void removeDevice(String deviceId) {
    _service.removeDevice(deviceId);
    // 自動儲存配置
    _autoSaveConfiguration();
  }

  void editDevice(Device device) {
    // 創建臨時控制器
    final nameController = TextEditingController(text: device.name);
    final tcpController = TextEditingController(text: device.tcp);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('編輯裝置'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: tcpController,
                decoration: const InputDecoration(labelText: 'TCP'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final updatedDevice = Device(
                  id: device.id,
                  brand: device.brand,
                  model: device.model,
                  type: device.type,
                  moduleId: device.moduleId,
                  channel: device.channel,
                  name: nameController.text,
                  tcp: tcpController.text,
                );
                _service.updateDevice(updatedDevice);
                Navigator.of(context).pop();
                // 自動儲存配置
                _autoSaveConfiguration();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  /// 獲取指定模組ID的channel使用情況
  Map<String, dynamic> getModuleChannelStatus(String moduleId, String type) {
    final existingDevices = _service.devices
        .where((d) => d.moduleId == moduleId)
        .toList();
    final usedChannels = existingDevices.map((d) => d.channel).toSet();

    final availableChannels = _service.getSelectableChannelsForModule(
      selectedBrand,
      selectedModel,
      type,
      moduleId,
    );
    final allTokens = _service
        .getAvailableChannels(selectedBrand, selectedModel, type)
        .toSet();

    return {
      'usedChannels': usedChannels.toList()..sort(),
      'availableChannels': availableChannels,
      'totalChannels': allTokens.length,
      'usedCount': usedChannels.length,
    };
  }

  void generateOutput() {
    _service.generateOutput();
  }

  void generateAndCopyOutput() async {
    generateOutput();
    if (_service.generatedOutput.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: _service.generatedOutput));
      // 使用 ScaffoldMessenger 顯示成功訊息
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('輸出內容已生成並複製到剪貼簿')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double baseWidth =
        (MediaQuery.of(context).size.width - 20 - 8 * 80) / 9;
    return Scaffold(
      appBar: AppBar(
        title: const Text('裝置註冊表生成器'),
        actions: const [ThemeToggleSwitch()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Configuration Management
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    // 如果是新配置，彈出對話框輸入名稱
                    if (_selectedConfiguration == '新配置') {
                      final nameController = TextEditingController();
                      final newName = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('保存新配置'),
                          content: TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: '配置名稱',
                              hintText: '請輸入配置名稱',
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
                                if (nameController.text.isNotEmpty) {
                                  Navigator.pop(context, nameController.text);
                                }
                              },
                              child: const Text('保存'),
                            ),
                          ],
                        ),
                      );

                      if (newName != null && newName.isNotEmpty) {
                        if (newName == '新配置') {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('無法使用預設配置名稱')),
                            );
                          }
                          return;
                        }
                        
                        try {
                          await _service.saveConfiguration(newName);
                          setState(() {
                            _selectedConfiguration = newName;
                          });
                          await _service.fetchConfigurations();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('配置保存成功')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('保存配置失敗: $e')),
                            );
                          }
                        }
                      }
                    } else {
                      // 直接保存到當前選擇的配置
                      try {
                        await _service.saveConfiguration(
                          _selectedConfiguration!,
                        );
                        await _service.fetchConfigurations();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('配置保存成功')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('保存配置失敗: $e')));
                        }
                      }
                    }
                  },
                  child: const Text('保存配置'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButton<String>(
                    hint: const Text('選擇配置'),
                    value: _selectedConfiguration,
                    onChanged: (String? newValue) async {
                      if (newValue != null) {
                        setState(() {
                          _selectedConfiguration = newValue;
                        });
                        if (newValue == '新配置') {
                          // 清空設備列表
                          _service.clearDevices();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已清空配置')),
                            );
                          }
                        } else {
                          try {
                            await _service.loadConfiguration(newValue);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('配置加載成功')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('加載配置失敗: $e')),
                              );
                            }
                          }
                        }
                      }
                    },
                    items: [
                      const DropdownMenuItem<String>(
                        value: '新配置',
                        child: Text('新配置'),
                      ),
                      ..._service.configurations.map<DropdownMenuItem<String>>((
                        config,
                      ) {
                        return DropdownMenuItem<String>(
                          value: config.name,
                          child: Text(
                            '${config.name} (創建者: ${config.chineseName})',
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    if (_selectedConfiguration == null ||
                        _selectedConfiguration == '新配置') {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('請先選擇要刪除的配置')),
                        );
                      }
                      return;
                    }
                    
                    // 顯示確認對話框
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('確認刪除'),
                        content: Text('確定要刪除配置 "$_selectedConfiguration" 嗎？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              '刪除',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        await _service.deleteConfiguration(
                          _selectedConfiguration!,
                        );
                        setState(() {
                          _selectedConfiguration = '新配置';
                        });
                        _service.clearDevices();
                        await _service.fetchConfigurations();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('配置刪除成功')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('刪除配置失敗: $e')));
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('刪除配置'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Device List with Drag and Drop
            _buildDeviceListWithDragDrop(),
            const SizedBox(height: 16),
            // Output Display
            SizedBox(
              height: 300, // 固定高度以便滾動
              child: SingleChildScrollView(
                child: Text(
                  _service.generatedOutput,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceListWithDragDrop() {
    return Column(
      children: [
        // 添加設備表單
        _buildAddDeviceForm(),
        const SizedBox(height: 16),
        // 設備列表標題
        _buildDeviceListHeader(),
        // 可拖拉的設備列表
        if (_service.devices.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
            ),
            child: Center(
              child: Text(
                '尚無設備，請添加設備',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
            ),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _service.devices.length,
              onReorder: (oldIndex, newIndex) {
                _service.reorderDevices(oldIndex, newIndex);
                // 自動儲存配置
                _autoSaveConfiguration();
              },
              itemBuilder: (context, index) {
                final device = _service.devices[index];
                return _buildDeviceRow(device, index);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDeviceListHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: _service.devices.isEmpty
            ? BorderRadius.circular(8)
            : const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Icon(
              Icons.drag_handle,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(
            width: 80,
            child: Text('Brand', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(
            width: 80,
            child: Text('Model', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(
            width: 80,
            child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(
            width: 120,
            child: Text(
              'Module ID',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(
            width: 60,
            child: Text(
              'Channel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Expanded(
            child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(
            width: 80,
            child: Text('TCP', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(
            width: 100,
            child: Text('操作', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(Device device, int index) {
    return Container(
      key: ValueKey(device.id ?? 'new_${device.hashCode}'),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: index < _service.devices.length - 1
                ? Theme.of(context).colorScheme.outlineVariant
                : Colors.transparent,
            width: 0.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Icon(
                    Icons.drag_handle,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: 80, child: Text(device.brand)),
                SizedBox(width: 80, child: Text(device.model)),
                SizedBox(width: 80, child: Text(device.type)),
                SizedBox(width: 120, child: Text(device.moduleId)),
                SizedBox(width: 60, child: Text(device.channel)),
                Expanded(child: Text(device.name)),
                SizedBox(width: 80, child: Text(device.tcp)),
                SizedBox(
                  width: 100,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => editDevice(device),
                        tooltip: '編輯',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: () => removeDevice(device.id!),
                        tooltip: '刪除',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddDeviceForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '添加新設備',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Brand',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  value: selectedBrand,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedBrand = newValue!;
                      selectedModel = models[selectedBrand]!.first;
                      List<String> availableTypes = getAvailableTypes(
                        selectedBrand,
                        selectedModel,
                      );
                      if (!availableTypes.contains(selectedType)) {
                        selectedType = availableTypes.first;
                      }
                      selectedChannel = getAvailableChannels(
                        selectedBrand,
                        selectedModel,
                        selectedType,
                      ).first;
                    });
                  },
                  items: brands.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  value: selectedModel,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedModel = newValue!;
                      List<String> availableTypes = getAvailableTypes(
                        selectedBrand,
                        selectedModel,
                      );
                      if (!availableTypes.contains(selectedType)) {
                        selectedType = availableTypes.first;
                      }
                      selectedChannel = getAvailableChannels(
                        selectedBrand,
                        selectedModel,
                        selectedType,
                      ).first;
                    });
                  },
                  items: models[selectedBrand]!.map<DropdownMenuItem<String>>((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  value: selectedType,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedType = newValue!;
                      selectedChannel = getAvailableChannels(
                        selectedBrand,
                        selectedModel,
                        selectedType,
                      ).first;
                    });
                  },
                  items: getAvailableTypes(selectedBrand, selectedModel)
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      })
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: moduleIdController,
                  decoration: const InputDecoration(
                    labelText: 'Module ID',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Channel',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  value: selectedChannel,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedChannel = newValue!;
                    });
                  },
                  items:
                      (_currentModuleId.isNotEmpty
                              ? _service.getSelectableChannelsForModule(
                                  selectedBrand,
                                  selectedModel,
                                  selectedType,
                                  _currentModuleId,
                                )
                              : getAvailableChannels(
                                  selectedBrand,
                                  selectedModel,
                                  selectedType,
                                ))
                          .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          })
                          .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: tcpController,
                  decoration: const InputDecoration(
                    labelText: 'TCP',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: addDevice,
                icon: const Icon(Icons.add),
                label: const Text('添加設備'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: generateAndCopyOutput,
                icon: const Icon(Icons.copy),
                label: const Text('生成並複製'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  String _formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  // 自動儲存配置
  Future<void> _autoSaveConfiguration() async {
    // 只有在選擇了非「新配置」時才自動儲存
    if (_selectedConfiguration != null && _selectedConfiguration != '新配置') {
      try {
        await _service.saveConfiguration(_selectedConfiguration!);
        // 靜默保存，不顯示提示
      } catch (e) {
        // 如果自動儲存失敗，顯示錯誤
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('自動儲存失敗: $e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }
}
