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
    _service.loadDevices(); // 加載裝置列表
  }

  @override
  void dispose() {
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

  List<String> getAvailableChannels(String brand, String model, String type) {
    return _service.getAvailableChannels(brand, model, type);
  }

  List<String> getAvailableTypes(String brand, String model) {
    return _service.getAvailableTypes(brand, model);
  }

  void addDevice() {
    if (moduleIdController.text.isNotEmpty &&
        nameController.text.isNotEmpty) {
      _service.addDevice(
        Device(
          brand: selectedBrand,
          model: selectedModel,
          type: selectedType,
          moduleId: moduleIdController.text,
          channel: selectedChannel,
          name: nameController.text,
          tcp: tcpController.text,
        ),
      );
      moduleIdController.clear();
      nameController.clear();
      tcpController.clear();
    }
  }

  void removeDevice(String deviceId) {
    _service.removeDevice(deviceId);
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
                  child: TextField(
                    controller: moduleIdController,
                    decoration: const InputDecoration(labelText: 'Module ID'),
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
              child: ListView.builder(
                itemCount: _service.devices.length,
                itemBuilder: (context, index) {
                  var device = _service.devices[index];
                  return ListTile(
                    title: Text('${device.brand} ${device.model} - ${device.type} - ${device.name}'),
                    subtitle: Text('Module: ${device.moduleId}, Channel: ${device.channel}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => removeDevice(device.id!),
                    ),
                  );
                },
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
