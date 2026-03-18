import 'package:coselig_staff_portal/models/device_config.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coselig_staff_portal/widgets/app_drawer.dart';
import 'package:coselig_staff_portal/services/discovery_service.dart';
import 'package:coselig_staff_portal/utils/icon_utils.dart';


class DiscoveryGeneratePage extends StatefulWidget {
  const DiscoveryGeneratePage({super.key});

  @override
  State<DiscoveryGeneratePage> createState() => _DiscoveryGeneratePageState();
}

class _DiscoveryGeneratePageState extends State<DiscoveryGeneratePage> {
  static const String _customAreaOption = '__custom_area__';
  static const String _customTcpOption = '__custom_tcp__';
  static const String _customModuleIdOption = '__custom_module_id__';

  final DiscoveryService _service = DiscoveryService();
  List<String> get brands => _service.brands;
  Map<String, List<String>> get models => _service.models;

  String selectedBrand = 'sunwave';
  String selectedModel = 'p404';
  String selectedType = 'single';
  String selectedChannel = '1';
  final TextEditingController moduleIdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController tcpController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController brightController = TextEditingController();
  final TextEditingController ctMinController = TextEditingController();
  final TextEditingController ctMaxController = TextEditingController();

  // Configuration management
  String? _selectedConfiguration = '新配置';

  // 用於跟踪Module ID輸入的狀態
  String _currentModuleId = '';

  @override
  void initState() {
    super.initState();
    html.document.title = '裝置註冊表生成器';
    _service.addListener(_update);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _service.fetchConfigurations();
      _service.fetchDeviceConfigOptions();
    });

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
    areaController.dispose();
    brightController.dispose();
    ctMinController.dispose();
    ctMaxController.dispose();
    _service.removeListener(_update);
    super.dispose();
  }

  void _update() {
    setState(() {});
  }

  List<String> getAvailableChannels(String brand, String model, String type) {
    return _service.getAvailableChannels(brand, model, type);
  }

  List<String> getAvailableTypes(String brand, String model) {
    return _service.getAvailableTypes(brand, model);
  }

  List<String> getAvailableAreas() {
    final areas = _service.devices
        .map((d) => d.area?.trim())
        .whereType<String>()
        .where((a) => a.isNotEmpty)
        .toSet()
        .toList();
    areas.sort();
    return areas;
  }

  List<String> getAvailableTcps() {
    final tcps = _service.devices
        .map((d) => d.tcp.trim())
        .where((tcp) => tcp.isNotEmpty)
        .toSet()
        .toList();
    tcps.sort();
    return tcps;
  }

  List<String> getAvailableModuleIds() {
    final moduleIds = _service.devices
        .map((d) => d.moduleId.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    moduleIds.sort();
    return moduleIds;
  }

  Future<String?> _showAreaInputDialog(String initialValue) async {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增 Area'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Area',
            hintText: '請輸入 Area',
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
              final area = controller.text.trim();
              if (area.isNotEmpty) {
                Navigator.pop(context, area);
              }
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showTcpInputDialog(String initialValue) async {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增 TCP'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'TCP',
            hintText: '請輸入 TCP',
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
              final tcp = controller.text.trim();
              if (tcp.isNotEmpty) {
                Navigator.pop(context, tcp);
              }
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showModuleIdInputDialog(String initialValue) async {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增 Module ID'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Module ID',
            hintText: '請輸入 Module ID',
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
              final moduleId = controller.text.trim();
              if (moduleId.isNotEmpty) {
                Navigator.pop(context, moduleId);
              }
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAreaSelection(
    String? newValue,
    TextEditingController controller, {
    VoidCallback? refresh,
  }) async {
    if (newValue == _customAreaOption) {
      final newArea = await _showAreaInputDialog(controller.text);
      if (newArea != null && newArea.isNotEmpty) {
        controller.text = newArea;
        if (refresh != null) {
          refresh();
        } else if (mounted) {
          setState(() {});
        }
      }
      return;
    }

    controller.text = newValue ?? '';
    if (refresh != null) {
      refresh();
    } else if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleTcpSelection(
    String? newValue,
    TextEditingController controller, {
    VoidCallback? refresh,
  }) async {
    if (newValue == _customTcpOption) {
      final newTcp = await _showTcpInputDialog(controller.text);
      if (newTcp != null && newTcp.isNotEmpty) {
        controller.text = newTcp;
        if (refresh != null) {
          refresh();
        } else if (mounted) {
          setState(() {});
        }
      }
      return;
    }

    controller.text = newValue ?? '';
    if (refresh != null) {
      refresh();
    } else if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleModuleIdSelection(String? newValue) async {
    if (newValue == _customModuleIdOption) {
      final newModuleId = await _showModuleIdInputDialog(moduleIdController.text);
      if (newModuleId != null && newModuleId.isNotEmpty) {
        moduleIdController.text = newModuleId;
        if (mounted) {
          setState(() {});
        }
      }
      return;
    }

    moduleIdController.text = newValue ?? '';
    if (mounted) {
      setState(() {});
    }
  }

  void addDevice() {
    if (moduleIdController.text.isNotEmpty) {
      final String deviceName = nameController.text.isNotEmpty
          ? nameController.text
          : "$selectedModel ${moduleIdController.text}_$selectedChannel";
      final int? bright = int.tryParse(brightController.text);
      final int? ctMin = int.tryParse(ctMinController.text);
      final int? ctMax = int.tryParse(ctMaxController.text);

      final newDevice = Device(
        brand: selectedBrand,
        model: selectedModel,
        type: selectedType,
        moduleId: moduleIdController.text,
        channel: selectedChannel,
        name: deviceName,
        tcp: tcpController.text.isNotEmpty ? tcpController.text : "1",
        area: areaController.text.isNotEmpty ? areaController.text : null,
        brightMinimum: bright,
        colortempMinimum: ctMin,
        colortempMaximum: ctMax,
      );

      if (!_service.canAddDevice(newDevice)) {
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
      areaController.clear();
      brightController.clear();
      ctMinController.clear();
      ctMaxController.clear();

      _autoSaveConfiguration();
    }
  }

  void removeDevice(String deviceId) {
    _service.removeDevice(deviceId);
    _autoSaveConfiguration();
  }

  void editDevice(Device device) {
    final nameController = TextEditingController(text: device.name);
    final tcpController = TextEditingController(text: device.tcp);
    final areaController = TextEditingController(text: device.area ?? '');
    final brightController = TextEditingController(
      text: device.brightMinimum?.toString() ?? '',
    );
    final ctMinController = TextEditingController(
      text: device.colortempMinimum?.toString() ?? '',
    );
    final ctMaxController = TextEditingController(
      text: device.colortempMaximum?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final availableAreas = getAvailableAreas();
            final availableTcps = getAvailableTcps();
            final currentArea = areaController.text.trim();
            final areaValue = currentArea.isEmpty ? null : currentArea;
            final currentTcp = tcpController.text.trim();
            final tcpValue = currentTcp.isEmpty ? null : currentTcp;

            return AlertDialog(
              title: const Text('編輯裝置'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  DropdownButtonFormField<String>(
                    value: tcpValue,
                    decoration: const InputDecoration(
                      labelText: 'TCP',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    hint: const Text('選擇 TCP'),
                    onChanged: (String? newValue) {
                      _handleTcpSelection(
                        newValue,
                        tcpController,
                        refresh: () => setDialogState(() {}),
                      );
                    },
                    items: [
                      ...availableTcps.map<DropdownMenuItem<String>>((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }),
                      if (currentTcp.isNotEmpty &&
                          !availableTcps.contains(currentTcp))
                        DropdownMenuItem<String>(
                          value: currentTcp,
                          child: Text(currentTcp),
                        ),
                      const DropdownMenuItem<String>(
                        value: _customTcpOption,
                        child: Text('＋新增 TCP'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: areaValue,
                    decoration: const InputDecoration(
                      labelText: 'Area',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    hint: const Text('選擇 Area'),
                    onChanged: (String? newValue) {
                      _handleAreaSelection(
                        newValue,
                        areaController,
                        refresh: () => setDialogState(() {}),
                      );
                    },
                    items: [
                      ...availableAreas.map<DropdownMenuItem<String>>((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }),
                      if (currentArea.isNotEmpty &&
                          !availableAreas.contains(currentArea))
                        DropdownMenuItem<String>(
                          value: currentArea,
                          child: Text(currentArea),
                        ),
                      const DropdownMenuItem<String>(
                        value: _customAreaOption,
                        child: Text('＋新增 Area'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: brightController,
                    decoration: const InputDecoration(
                      labelText: '最低亮度 (bright_minimum)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  if (device.type == 'dual') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: ctMinController,
                      decoration: const InputDecoration(
                        labelText: '最低色溫 (colortemp_minimum)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ctMaxController,
                      decoration: const InputDecoration(
                        labelText: '最高色溫 (colortemp_maximum)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
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
                      name: nameController.text.isNotEmpty
                          ? nameController.text
                          : "${device.model} ${device.moduleId} - ${device.channel}",
                      tcp: tcpController.text.isNotEmpty
                          ? tcpController.text
                          : "1",
                      area: areaController.text.isNotEmpty
                          ? areaController.text
                          : null,
                      brightMinimum: int.tryParse(brightController.text),
                      colortempMinimum: device.type == 'dual'
                          ? int.tryParse(ctMinController.text)
                          : null,
                      colortempMaximum: device.type == 'dual'
                          ? int.tryParse(ctMaxController.text)
                          : null,
                    );
                    _service.updateDevice(updatedDevice);
                    Navigator.of(context).pop();
                    _autoSaveConfiguration();
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
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

  void generateYamlOutput() {
    _service.generateYamlOutput();
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

  void generateAndCopyYamlOutput() async {
    generateYamlOutput();
    if (_service.generatedOutput.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: _service.generatedOutput));
      // 使用 ScaffoldMessenger 顯示成功訊息
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('YAML 配置已生成並複製到剪貼簿')));
      }
    }
  }

  void exportDeviceConfigsFile() {
    try {
      final json = _service.exportDeviceConfigsJson();
      final blob = html.Blob([json], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final filename = '${_service.currentConfigurationName.replaceAll(' ', '_')}_device_configs.json';
      final _ = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已下載 deviceConfigs JSON')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('匯出失敗: $e')));
    }
  }

  void exportDeviceConfigsSchemaFile() {
    try {
      final schema = _service.exportDeviceConfigsJsonSchema();
      final blob = html.Blob([schema], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final filename = 'device_configs.schema.json';
      final _ = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已下載 deviceConfigs JSON Schema')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('匯出 Schema 失敗: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('裝置註冊表生成器'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: '開啟選單',
          ),
        ),
        actions: [
          // 配置選擇下拉選單
          DropdownButton<String>(
            hint: const Text('選擇配置', style: TextStyle(color: Colors.white)),
            value: _selectedConfiguration,
            dropdownColor: Theme.of(context).primaryColor,
            style: const TextStyle(color: Colors.white),
            underline: Container(),
            onChanged: (String? newValue) async {
              if (newValue != null) {
                setState(() {
                  _selectedConfiguration = newValue;
                });
                _service.setConfigurationName(newValue);
                if (newValue == '新配置') {
                  // 清空設備列表
                  _service.clearDevices();
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('已清空配置')));
                  }
                } else {
                  try {
                    await _service.loadConfiguration(newValue);
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('配置加載成功')));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('加載配置失敗: $e')));
                    }
                  }
                }
              }
            },
            items: [
              const DropdownMenuItem<String>(value: '新配置', child: Text('新配置')),
              ..._service.configurations.map<DropdownMenuItem<String>>((
                config,
              ) {
                return DropdownMenuItem<String>(
                  value: config.name,
                  child: Text('${config.name} (創建者: ${config.chineseName})'),
                );
              }),
            ],
          ),
          // 保存按鈕
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: '保存配置',
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
                    _service.setConfigurationName(newName);
                    await _service.fetchConfigurations();
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('配置保存成功')));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('保存配置失敗: $e')));
                    }
                  }
                }
              } else {
                // 直接保存到當前選擇的配置
                try {
                  await _service.saveConfiguration(_selectedConfiguration!);
                  await _service.fetchConfigurations();
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('配置保存成功')));
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
          ),
          // 刪除按鈕
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: '刪除配置',
            onPressed: () async {
              if (_selectedConfiguration == null ||
                  _selectedConfiguration == '新配置') {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('請先選擇要刪除的配置')));
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
                  await _service.deleteConfiguration(_selectedConfiguration!);
                  setState(() {
                    _selectedConfiguration = '新配置';
                  });
                  _service.clearDevices();
                  await _service.fetchConfigurations();
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('配置刪除成功')));
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
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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

  Widget _buildHeaderLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildRowText(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
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
              size: context.scaledIconSize(20),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildHeaderLabel('Brand'),
          ),
          Expanded(
            flex: 2,
            child: _buildHeaderLabel('Model'),
          ),
          Expanded(
            flex: 2,
            child: _buildHeaderLabel('Type'),
          ),
          Expanded(
            flex: 3,
            child: _buildHeaderLabel('Module ID'),
          ),
          Expanded(
            flex: 2,
            child: _buildHeaderLabel('Channel'),
          ),
          Expanded(
            flex: 3,
            child: _buildHeaderLabel('Name'),
          ),
          Expanded(
            flex: 2,
            child: _buildHeaderLabel('TCP'),
          ),
          Expanded(
            flex: 2,
            child: _buildHeaderLabel('Area'),
          ),
          SizedBox(
            width: 100,
            child: _buildHeaderLabel('操作'),
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
                    size: context.scaledIconSize(20),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(flex: 2, child: _buildRowText(device.brand)),
                Expanded(flex: 2, child: _buildRowText(device.model)),
                Expanded(flex: 2, child: _buildRowText(device.type)),
                Expanded(flex: 3, child: _buildRowText(device.moduleId)),
                Expanded(flex: 2, child: _buildRowText(device.channel)),
                Expanded(flex: 3, child: _buildRowText(device.name)),
                Expanded(flex: 2, child: _buildRowText(device.tcp)),
                Expanded(flex: 2, child: _buildRowText(device.area ?? '')),
                SizedBox(
                  width: 100,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          size: context.scaledIconSize(18),
                        ),
                        onPressed: () => editDevice(device),
                        tooltip: '編輯',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.delete, size: context.scaledIconSize(18)),
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
    final availableAreas = getAvailableAreas();
    final availableTcps = getAvailableTcps();
    final availableModuleIds = getAvailableModuleIds();
    final currentModuleId = moduleIdController.text.trim();
    final moduleIdValue = currentModuleId.isEmpty ? null : currentModuleId;
    final currentArea = areaController.text.trim();
    final areaValue = currentArea.isEmpty ? null : currentArea;
    final currentTcp = tcpController.text.trim();
    final tcpValue = currentTcp.isEmpty ? null : currentTcp;

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
          Text(
            '添加新設備',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final includeDual = selectedType == 'dual';

              final baseWidths = <String, double>{
                'brand': 140,
                'model': 140,
                'type': 90,
                'module': 140,
                'channel': 80,
                'name': 150,
                'tcp': 90,
                'area': 100,
                'bright': 90,
                'ctMin': 90,
                'ctMax': 90,
                'addBtn': 120,
                'genBtn': 150,
              };

              final minWidths = <String, double>{
                'brand': 120,
                'model': 120,
                'type': 90,
                'module': 180,
                'channel': 85,
                'name': 160,
                'tcp': 130,
                'area': 140,
                'bright': 110,
                'ctMin': 110,
                'ctMax': 110,
                'addBtn': 130,
                'genBtn': 150,
              };

              final keys = <String>[
                'brand',
                'model',
                'type',
                'module',
                'channel',
                'name',
                'tcp',
                'area',
                'bright',
                if (includeDual) 'ctMin',
                if (includeDual) 'ctMax',
                'addBtn',
                'genBtn',
              ];

              final totalBaseWidth = keys
                  .map((k) => baseWidths[k] ?? 0)
                  .fold<double>(0, (sum, w) => sum + w);
              final totalSpacing = spacing * (keys.length - 1);
              final availableForWidgets = constraints.maxWidth - totalSpacing;
              final shouldScale = constraints.maxWidth >= 1100;
              final scale = shouldScale
                  ? (availableForWidgets / totalBaseWidth).clamp(0.72, 1.0)
                  : 1.0;

              double w(String key) {
                final base = baseWidths[key] ?? 120;
                final min = minWidths[key] ?? base;
                final scaled = base * scale;
                return scaled < min ? min : scaled;
              }

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: w('brand'),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Brand',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      initialValue: selectedBrand,
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
                      items: brands
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(
                    width: w('model'),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      initialValue: selectedModel,
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
                      items: models[selectedBrand]!
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(
                    width: w('type'),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      initialValue: selectedType,
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
                      }).toList(),
                    ),
                  ),
                  SizedBox(
                    width: w('module'),
                    child: DropdownButtonFormField<String>(
                      initialValue: moduleIdValue,
                      decoration: const InputDecoration(
                        labelText: 'Module ID',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      hint: const Text('選擇 Module ID'),
                      onChanged: (String? newValue) {
                        _handleModuleIdSelection(newValue);
                      },
                      items: [
                        ...availableModuleIds
                            .map<DropdownMenuItem<String>>((value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }),
                        if (currentModuleId.isNotEmpty &&
                            !availableModuleIds.contains(currentModuleId))
                          DropdownMenuItem<String>(
                            value: currentModuleId,
                            child: Text(currentModuleId),
                          ),
                        const DropdownMenuItem<String>(
                          value: _customModuleIdOption,
                          child: Text('＋新增 Module ID'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: w('channel'),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Channel',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      initialValue: selectedChannel,
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
                  SizedBox(
                    width: w('name'),
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: w('tcp'),
                    child: DropdownButtonFormField<String>(
                      initialValue: tcpValue,
                      decoration: const InputDecoration(
                        labelText: 'TCP',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      hint: const Text('選擇 TCP'),
                      onChanged: (String? newValue) {
                        _handleTcpSelection(newValue, tcpController);
                      },
                      items: [
                        ...availableTcps.map<DropdownMenuItem<String>>((value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }),
                        if (currentTcp.isNotEmpty &&
                            !availableTcps.contains(currentTcp))
                          DropdownMenuItem<String>(
                            value: currentTcp,
                            child: Text(currentTcp),
                          ),
                        const DropdownMenuItem<String>(
                          value: _customTcpOption,
                          child: Text('＋新增 TCP'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: w('area'),
                    child: DropdownButtonFormField<String>(
                      initialValue: areaValue,
                      decoration: const InputDecoration(
                        labelText: 'Area',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      hint: const Text('選擇 Area'),
                      onChanged: (String? newValue) {
                        _handleAreaSelection(newValue, areaController);
                      },
                      items: [
                        ...availableAreas
                            .map<DropdownMenuItem<String>>((value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }),
                        if (currentArea.isNotEmpty &&
                            !availableAreas.contains(currentArea))
                          DropdownMenuItem<String>(
                            value: currentArea,
                            child: Text(currentArea),
                          ),
                        const DropdownMenuItem<String>(
                          value: _customAreaOption,
                          child: Text('＋新增 Area'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: w('bright'),
                    child: TextField(
                      controller: brightController,
                      decoration: const InputDecoration(
                        labelText: '最低亮度',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  if (includeDual)
                    SizedBox(
                      width: w('ctMin'),
                      child: TextField(
                        controller: ctMinController,
                        decoration: const InputDecoration(
                          labelText: '色溫最小',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  if (includeDual)
                    SizedBox(
                      width: w('ctMax'),
                      child: TextField(
                        controller: ctMaxController,
                        decoration: const InputDecoration(
                          labelText: '色溫最大',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  SizedBox(
                    width: w('addBtn'),
                    child: ElevatedButton.icon(
                      onPressed: addDevice,
                      icon: const Icon(Icons.add),
                      label: const Text('添加設備'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 20,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: w('genBtn'),
                    child: ElevatedButton.icon(
                      onPressed: generateAndCopyOutput,
                      icon: const Icon(Icons.copy),
                      label: const Text('生成裝置設定'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
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
