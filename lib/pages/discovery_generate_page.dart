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
      _service.loadDevices(); // 加載裝置列表
      _loadConfigurationNames(); // 加載配置名稱列表
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
    configNameController.dispose();
    _service.removeListener(_update);
    super.dispose();
  }

  void _update() {
    setState(() {});
  }

  Future<void> _loadConfigurationNames() async {
    try {
      final names = await _service.getConfigurationNames();
      setState(() {
        _configurationNames = ['新配置', ...names];
        // 如果當前選擇的配置不在列表中，重置為新配置
        if (!_configurationNames.contains(_selectedConfiguration)) {
          _selectedConfiguration = '新配置';
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('無法加載配置: $e')),
        );
      }
      // 即使加載失敗，也要提供新配置選項
      setState(() {
        _configurationNames = ['新配置'];
        _selectedConfiguration = '新配置';
      });
    }
  }

  String selectedBrand = 'sunwave';
  String selectedModel = 'p404';
  String selectedType = 'single';
  String selectedChannel = '1';
  final TextEditingController moduleIdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController tcpController = TextEditingController();
  final TextEditingController configNameController = TextEditingController();

  // Configuration management
  List<String> _configurationNames = [];
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
    if (moduleIdController.text.isNotEmpty &&
        nameController.text.isNotEmpty) {
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
    }
  }

  void removeDevice(String deviceId) {
    _service.removeDevice(deviceId);
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
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: configNameController,
                    decoration: const InputDecoration(labelText: '配置名稱'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    if (configNameController.text.isNotEmpty) {
                      if (configNameController.text == '新配置') {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('無法使用預設配置名稱')),
                          );
                        }
                        return;
                      }
                      try {
                        await _service.saveConfiguration(configNameController.text);
                        configNameController.clear();
                        await _loadConfigurationNames();
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
                    items: _configurationNames.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    if (configNameController.text.isNotEmpty) {
                      if (configNameController.text == '新配置') {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('無法刪除預設配置')),
                          );
                        }
                        return;
                      }
                      try {
                        await _service.deleteConfiguration(configNameController.text);
                        configNameController.clear();
                        await _loadConfigurationNames();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('配置刪除成功')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('刪除配置失敗: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('刪除配置'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Device List
            SizedBox(
              width: MediaQuery.of(context).size.width - 20,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 80.0,
                  columns: [
                    DataColumn(
                      label: SizedBox(
                        width:
                            (MediaQuery.of(context).size.width - 20 - 8 * 80) /
                            9,
                        child: DropdownButton<String>(
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
                          items: brands.map<DropdownMenuItem<String>>((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                            width:
                                (MediaQuery.of(context).size.width -
                                    20 -
                                    8 * 80) /
                                9,
                            child: DropdownButton<String>(
                              value: selectedModel,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedModel = newValue!;
                                  List<String> availableTypes =
                                      getAvailableTypes(
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
                                  .map<DropdownMenuItem<String>>((
                                    String value,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  })
                                  .toList(),
                            ),
                          ),
                        ),
                    DataColumn(
                      label: SizedBox(
                            width:
                                (MediaQuery.of(context).size.width -
                                    20 -
                                    8 * 80) /
                                9,
                            child: DropdownButton<String>(
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
                              items:
                                  getAvailableTypes(
                                    selectedBrand,
                                    selectedModel,
                                  ).map<DropdownMenuItem<String>>((
                                    String value,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                    DataColumn(
                      label: SizedBox(
                            width:
                                (MediaQuery.of(context).size.width -
                                    20 -
                                    8 * 80) /
                                9,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: moduleIdController,
                                  decoration: const InputDecoration(
                                    labelText: 'Module ID',
                                  ),
                                ),
                            // if (_currentModuleId.isNotEmpty) ...[
                            //   const SizedBox(height: 4),
                            //   Builder(
                            //     builder: (context) {
                            //       final status = getModuleChannelStatus(
                            //         _currentModuleId,
                            //         selectedType,
                            //       );
                            //       final usedChannels =
                            //           status['usedChannels']
                            //               as List<String>;
                            //       final availableChannels =
                            //           status['availableChannels']
                            //               as List<String>;
                            //       final totalChannels =
                            //           status['totalChannels'] as int;
                            //       final usedCount =
                            //           status['usedCount'] as int;

                            //       return Text(
                            //         '已使用: ${usedChannels.join(', ')} | 可用: ${availableChannels.join(', ')} ($usedCount/$totalChannels)',
                            //         style: TextStyle(
                            //           fontSize: 12,
                            //           color: availableChannels.isEmpty
                            //               ? Colors.red
                            //               : Colors.green,
                            //         ),
                            //       );
                            //     },
                            //   ),
                            // ],
                              ],
                            ),
                          ),
                        ),
                    DataColumn(
                      label: SizedBox(
                            width: baseWidth * 0.4,
                            child: DropdownButton<String>(
                              value: selectedChannel,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedChannel = newValue!;
                                });
                              },
                              items:
                                  (_currentModuleId.isNotEmpty
                                          ? _service
                                                .getSelectableChannelsForModule(
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
                                      .map<DropdownMenuItem<String>>((
                                        String value,
                                      ) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      })
                                      .toList(),
                            ),
                          ),
                        ),
                    DataColumn(
                      label: SizedBox(
                            width:
                                (MediaQuery.of(context).size.width -
                                    20 -
                                    8 * 80) /
                                9,
                            child: TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                              ),
                            ),
                          ),
                        ),
                    DataColumn(
                      label: SizedBox(
                            width: baseWidth * 0.4,
                            child: TextField(
                              controller: tcpController,
                              decoration: const InputDecoration(
                                labelText: 'TCP',
                              ),
                            ),
                          ),
                        ),
                    DataColumn(
                      label: ElevatedButton(
                            onPressed: addDevice,
                            child: const Text('添加'),
                      ),
                    ),
                    DataColumn(
                      label: ElevatedButton.icon(
                            onPressed: generateAndCopyOutput,
                            icon: const Icon(Icons.copy),
                            label: const Text('生成並複製輸出'),
                      ),
                    ),
                  ],
                  rows: _service.devices.map((device) {
                      return DataRow(
                        cells: [
                          DataCell(Text(device.brand)),
                          DataCell(Text(device.model)),
                          DataCell(Text(device.type)),
                          DataCell(Text(device.moduleId)),
                          DataCell(Text(device.channel)),
                          DataCell(Text(device.name)),
                          DataCell(Text(device.tcp)),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => editDevice(device),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => removeDevice(device.id!),
                            ),
                          ),
                        ],
                      );
                  }).toList(),
                ),
              ),
            ),
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
}
