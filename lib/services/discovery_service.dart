import 'package:flutter/material.dart';

class Device {
  String brand;
  String model;
  String type;
  String moduleId;
  String channel;
  String name;
  String tcp;

  Device({
    required this.brand,
    required this.model,
    required this.type,
    required this.moduleId,
    required this.channel,
    required this.name,
    required this.tcp,
  });

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'model': model,
      'type': type,
      'module_id': moduleId,
      'channel': channel,
      'name': name,
      'tcp': tcp,
    };
  }
}

class DiscoveryService extends ChangeNotifier {
  final List<Device> _devices = [];
  String _generatedOutput = '';

  String get generatedOutput => _generatedOutput;
  List<String> get brands => deviceConfigs.keys.toList();
  Map<String, List<String>> get models => deviceConfigs.map(
    (brand, modelsMap) => MapEntry(brand, modelsMap.keys.toList()),
  );

  // Combined map for device configurations: brand -> model -> {'types': [...], 'channels': {type: [...]}}
  final Map<String, Map<String, Map<String, dynamic>>> deviceConfigs = {
    'sunwave': {
      'p404': {
        'types': ['dual', 'single', 'wrgb', 'rgb'],
        'channels': {
          'dual': ['a', 'b'],
          'single': ['1', '2', '3', '4'],
          'wrgb': ['x'],
          'rgb': ['x'],
        },
      },
      'p210': {
        'types': ['dual', 'single'],
        'channels': {
          'dual': ['a'],
          'single': ['1', '2'],
        },
      },
      'U4': {
        'types': ['dual', 'single', 'wrgb', 'rgb'],
        'channels': {
          'dual': ['a', 'b'],
          'single': ['1', '2', '3', '4'],
          'wrgb': ['x'],
          'rgb': ['x'],
        },
      },
      'R8A': {
        'types': ['relay'],
        'channels': {
          'relay': ['1', '2', '3', '4', '5', '6', '7', '8'],
        },
      },
      'R410': {
        'types': ['relay'],
        'channels': {
          'relay': ['1', '2', '3', '4'],
        },
      },
    },
    'guo': {
      'p805': {
        'types': ['dual', 'single'],
        'channels': {
          'dual': ['a', 'b'],
          'single': ['1', '2', '3', '4'],
        },
      },
    },
  };

  List<Device> get devices => List.unmodifiable(_devices);

  List<String> getAvailableChannels(String brand, String model, String type) {
    final channelsMap = deviceConfigs[brand]?[model]?['channels'] as Map<String, dynamic>?;
    return (channelsMap?[type] as List<String>?) ?? ['1'];
  }

  List<String> getAvailableTypes(String brand, String model) {
    return deviceConfigs[brand]?[model]?['types'] as List<String>? ?? ['dual', 'single'];
  }

  void addDevice(Device device) {
    _devices.add(device);
    notifyListeners();
  }

  void removeDevice(int index) {
    if (index >= 0 && index < _devices.length) {
      _devices.removeAt(index);
      notifyListeners();
    }
  }

  String generateOutput() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('msg.devices = [');
    for (int i = 0; i < _devices.length; i++) {
      var device = _devices[i];
      buffer.write(
        '    { brand: "${device.brand}", model: "${device.model}", type: "${device.type}", module_id: "${device.moduleId}", channel: "${device.channel}", name: "${device.name}", tcp: "${device.tcp}" }',
      );
      if (i < _devices.length - 1) {
        buffer.writeln(',');
      } else {
        buffer.writeln();
      }
    }
    buffer.writeln('];');
    buffer.writeln('return msg;');
    _generatedOutput = buffer.toString();
    notifyListeners();
    return _generatedOutput;
  }

  // Future methods for database integration
  Future<void> loadDevices() async {
    // TODO: Load from database
    notifyListeners();
  }

  Future<void> saveDevices() async {
    // TODO: Save to database
    notifyListeners();
  }
}