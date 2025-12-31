import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coselig_staff_portal/widgets/theme_toggle_switch.dart';
import 'package:coselig_staff_portal/services/discovery_service.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:provider/provider.dart';

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
      final authService = context.read<AuthService>();
      if (!authService.isLoggedIn) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }
      _service.loadDevices(); // 加載裝置列表
    });

    // 監聽Module ID輸入變化
    moduleIdController.addListener(() {
      setState(() {
        _currentModuleId = moduleIdController.text;
      });
    });
  }

  @override
  void dispose() {
    moduleIdController.dispose();
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

  /// 獲取指定模組ID的channel使用情況
  Map<String, dynamic> getModuleChannelStatus(String moduleId) {
    final existingDevices = _service.devices
        .where((d) => d.moduleId == moduleId)
        .toList();
    final usedChannels = existingDevices.map((d) => d.channel).toSet();

    // 獲取所有可用channel（基於當前選擇的model）
    final allAvailableChannels = <String>{};
    final modelConfig = _service.deviceConfigs[selectedBrand]?[selectedModel];
    if (modelConfig != null) {
      final channelsMap = modelConfig['channels'] as Map<String, dynamic>;
      for (final channels in channelsMap.values) {
        if (channels is List) {
          allAvailableChannels.addAll(channels.cast<String>());
        }
      }
    }

    final availableChannels =
        allAvailableChannels.difference(usedChannels).toList()..sort();

    return {
      'usedChannels': usedChannels.toList()..sort(),
      'availableChannels': availableChannels,
      'totalChannels': allAvailableChannels.length,
      'usedCount': usedChannels.length,
    };
  }

  void generateOutput() {
    _service.generateOutput();
  }

  void copyToClipboard() async {
    if (_service.generatedOutput.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: _service.generatedOutput));
      // 使用 ScaffoldMessenger 顯示成功訊息
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('輸出內容已複製到剪貼簿')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('裝置註冊表生成器'),
        actions: const [ThemeToggleSwitch()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add Device Form
            Row(
              children: [
                // Brand
                Expanded(
                  flex: 1,
                  child: DropdownButton<String>(
                    value: selectedBrand,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedBrand = newValue!;
                        selectedModel = models[selectedBrand]!.first;
                        List<String> availableTypes = getAvailableTypes(selectedBrand, selectedModel);
                        if (!availableTypes.contains(selectedType)) {
                          selectedType = availableTypes.first;
                        }
                        selectedChannel = getAvailableChannels(selectedBrand, selectedModel, selectedType).first;
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
                // Model
                Expanded(
                  flex: 1,
                  child: DropdownButton<String>(
                    value: selectedModel,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedModel = newValue!;
                        List<String> availableTypes = getAvailableTypes(selectedBrand, selectedModel);
                        if (!availableTypes.contains(selectedType)) {
                          selectedType = availableTypes.first;
                        }
                        selectedChannel = getAvailableChannels(selectedBrand, selectedModel, selectedType).first;
                      });
                    },
                    items: models[selectedBrand]!.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                // Type
                Expanded(
                  flex: 1,
                  child: DropdownButton<String>(
                    value: selectedType,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedType = newValue!;
                        selectedChannel = getAvailableChannels(selectedBrand, selectedModel, selectedType).first;
                      });
                    },
                    items: getAvailableTypes(selectedBrand, selectedModel).map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                // Module ID
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: moduleIdController,
                        decoration: const InputDecoration(
                          labelText: 'Module ID',
                        ),
                      ),
                      if (_currentModuleId.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Builder(
                          builder: (context) {
                            final status = getModuleChannelStatus(
                              _currentModuleId,
                            );
                            final usedChannels =
                                status['usedChannels'] as List<String>;
                            final availableChannels =
                                status['availableChannels'] as List<String>;
                            final totalChannels =
                                status['totalChannels'] as int;
                            final usedCount = status['usedCount'] as int;

                            return Text(
                              '已使用: ${usedChannels.join(', ')} | 可用: ${availableChannels.join(', ')} ($usedCount/$totalChannels)',
                              style: TextStyle(
                                fontSize: 12,
                                color: availableChannels.isEmpty
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Channel
                Expanded(
                  flex: 1,
                  child: DropdownButton<String>(
                    value: selectedChannel,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedChannel = newValue!;
                      });
                    },
                    items: getAvailableChannels(selectedBrand, selectedModel, selectedType)
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                // Name
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                ),
                const SizedBox(width: 8),
                // TCP
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: tcpController,
                    decoration: const InputDecoration(labelText: 'TCP'),
                  ),
                ),
                const SizedBox(width: 8),
                // Add Button
                ElevatedButton(
                  onPressed: addDevice,
                  child: const Text('添加'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Device List
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Brand')),
                    DataColumn(label: Text('Model')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Module ID')),
                    DataColumn(label: Text('Channel')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('TCP')),
                    DataColumn(label: Text('Action')),
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
            // Buttons Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: generateOutput,
                    child: const Text('生成輸出'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: copyToClipboard,
                    icon: const Icon(Icons.copy),
                    label: const Text('複製輸出'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Output Display
            Expanded(
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
