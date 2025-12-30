import 'package:flutter/material.dart';

class Device {
  String brand;
  String model;
  String type;
  String moduleId;
  String channel;
  String name;

  Device({
    required this.brand,
    required this.model,
    required this.type,
    required this.moduleId,
    required this.channel,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'model': model,
      'type': type,
      'module_id': moduleId,
      'channel': channel,
      'name': name,
    };
  }
}

class DiscoveryGeneratePage extends StatefulWidget {
  const DiscoveryGeneratePage({super.key});

  @override
  State<DiscoveryGeneratePage> createState() => _DiscoveryGeneratePageState();
}

class _DiscoveryGeneratePageState extends State<DiscoveryGeneratePage> {
  final List<Device> devices = [];
  final List<String> deviceTypes = ['dual', 'single', 'wrgb', 'rgb', 'relay'];
  final List<String> brands = ['sunwave', 'guo'];
  final Map<String, List<String>> models = {
    'sunwave': ['p404', 'p210', 'R410', 'R8A', 'U4'],
    'guo': ['p805'],
  };

  String selectedBrand = 'sunwave';
  String selectedModel = 'p404';
  String selectedType = 'single';
  String selectedChannel = '1';
  final TextEditingController moduleIdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  String generatedOutput = '';

  List<String> getAvailableChannels(String brand, String model, String type) {
    if (brand == 'sunwave') {
      if (model == 'p404') {
        switch (type) {
          case 'dual':
            return ['a', 'b'];
          case 'single':
            return ['1', '2', '3', '4'];
          case 'wrgb':
          case 'rgb':
            return ['x'];
          default:
            return ['1'];
        }
      } else if (model == 'p210') {
        switch (type) {
          case 'dual':
            return ['a'];
          case 'single':
            return ['1', '2'];
          default:
            return ['1'];
        }
      } else if (model == 'U4') {
        switch (type) {
          case 'dual':
            return ['a', 'b'];
          case 'single':
            return ['1', '2', '3', '4'];
          case 'wrgb':
          case 'rgb':
            return ['x'];
          default:
            return ['1'];
        }
      } else if (model == 'R8A' || model == 'R410') {
        if (type == 'relay') {
          if (model == 'R8A') {
            return ['1', '2', '3', '4', '5', '6', '7', '8'];
          } else if (model == 'R410') {
            return ['1', '2', '3', '4'];
          }
        }
        return ['1'];
      }
    }
    // Default for other models
    return ['1'];
  }

  List<String> getAvailableTypes(String brand, String model) {
    if (brand == 'sunwave') {
      if (model == 'R8A' || model == 'R410') {
        return ['relay'];
      } else if (model == 'p404' || model == 'U4') {
        return ['dual', 'single', 'wrgb', 'rgb'];
      } else {
        return ['dual', 'single'];
      }
    }
    return ['dual', 'single'];
  }

  void addDevice() {
    if (moduleIdController.text.isNotEmpty &&
        nameController.text.isNotEmpty) {
      setState(() {
        devices.add(Device(
          brand: selectedBrand,
          model: selectedModel,
          type: selectedType,
          moduleId: moduleIdController.text,
          channel: selectedChannel,
          name: nameController.text,
        ));
        moduleIdController.clear();
        nameController.clear();
      });
    }
  }

  void removeDevice(int index) {
    setState(() {
      devices.removeAt(index);
    });
  }

  void generateOutput() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('msg.devices = [');
    for (int i = 0; i < devices.length; i++) {
      var device = devices[i];
      buffer.write('    { brand: "${device.brand}", model: "${device.model}", type: "${device.type}", module_id: "${device.moduleId}", channel: "${device.channel}", name: "${device.name}" }');
      if (i < devices.length - 1) {
        buffer.writeln(',');
      } else {
        buffer.writeln();
      }
    }
    buffer.writeln('];');
    buffer.writeln('return msg;');
    setState(() {
      generatedOutput = buffer.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('裝置註冊表生成器'),
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
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  var device = devices[index];
                  return ListTile(
                    title: Text('${device.brand} ${device.model} - ${device.type} - ${device.name}'),
                    subtitle: Text('Module: ${device.moduleId}, Channel: ${device.channel}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => removeDevice(index),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Generate Button
            ElevatedButton(
              onPressed: generateOutput,
              child: const Text('生成輸出'),
            ),
            const SizedBox(height: 16),
            // Output Display
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  generatedOutput,
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
