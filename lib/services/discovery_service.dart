import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'dart:convert';
import 'package:coselig_staff_portal/main.dart';

class Device {
  String? id; // 數據庫ID，對於新裝置為 null
  String brand;
  String model;
  String type;
  String moduleId;
  String channel;
  String name;
  String tcp;

  Device({
    this.id,
    required this.brand,
    required this.model,
    required this.type,
    required this.moduleId,
    required this.channel,
    required this.name,
    required this.tcp,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id']?.toString(),
      brand: json['brand'],
      model: json['model'],
      type: json['type'],
      moduleId: json['module_id'],
      channel: json['channel'],
      name: json['name'],
      tcp: json['tcp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
  final String baseUrl =
      'https://employeeservice.coseligtest.workers.dev'; // 使用與 AuthService 相同的 URL
  final BrowserClient _client = BrowserClient()
    ..withCredentials = true; // 自動處理 cookies
  final List<Device> _devices = [];
  String _generatedOutput = '';
  bool _isLoading = false;
  String? _error;

  String get generatedOutput => _generatedOutput;
  List<String> get brands => deviceConfigs.keys.toList();
  Map<String, List<String>> get models => deviceConfigs.map(
    (brand, modelsMap) => MapEntry(brand, modelsMap.keys.toList()),
  );

  List<Device> get devices => List.unmodifiable(_devices);
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  List<String> getAvailableChannels(String brand, String model, String type) {
    final channelsMap = deviceConfigs[brand]?[model]?['channels'] as Map<String, dynamic>?;
    return (channelsMap?[type] as List<String>?) ?? ['1'];
  }

  List<String> getAvailableTypes(String brand, String model) {
    return deviceConfigs[brand]?[model]?['types'] as List<String>? ?? ['dual', 'single'];
  }

  /// 檢查是否可以添加指定的裝置
  /// 規則：同一個模組ID的所有可用channel都必須被使用完才能阻止添加
  bool canAddDevice(Device newDevice) {
    // 獲取該模組ID的所有現有裝置
    final existingDevices = _devices
        .where((d) => d.moduleId == newDevice.moduleId)
        .toList();

    if (existingDevices.isEmpty) {
      // 如果沒有現有裝置，可以添加
      return true;
    }

    // 獲取該model的所有可用channel（所有type的channel的聯集）
    final allAvailableChannels = <String>{};
    final modelConfig = deviceConfigs[newDevice.brand]?[newDevice.model];
    if (modelConfig != null) {
      final channelsMap = modelConfig['channels'] as Map<String, dynamic>;
      for (final channels in channelsMap.values) {
        if (channels is List) {
          allAvailableChannels.addAll(channels.cast<String>());
        }
      }
    }

    // 如果沒有配置，默認允許
    if (allAvailableChannels.isEmpty) {
      return true;
    }

    // 獲取已被使用的channel
    final usedChannels = existingDevices.map((d) => d.channel).toSet();

    // 檢查是否還有未使用的channel
    final availableChannels = allAvailableChannels.difference(usedChannels);

    // 如果還有可用的channel，就可以添加新裝置
    return availableChannels.isNotEmpty;
  }

  Future<void> addDevice(Device device) async {
    // 在發送API請求前進行邏輯檢查
    if (!canAddDevice(device)) {
      _error = '無法添加裝置：模組ID的所有通道都已被使用';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/devices'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(device.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newDevice = Device.fromJson(data['device']);
        _devices.add(newDevice);
        notifyListeners();
      } else if (response.statusCode == 401) {
        _error = 'Unauthorized';
        navigatorKey.currentState?.pushReplacementNamed('/login');
      } else {
        final error = jsonDecode(response.body);
        _error = error['error'] ?? 'Failed to add device';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeDevice(String deviceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/api/devices?id=$deviceId'),
      );

      if (response.statusCode == 200) {
        _devices.removeWhere((device) => device.id == deviceId);
        notifyListeners();
      } else if (response.statusCode == 401) {
        _error = 'Unauthorized';
        navigatorKey.currentState?.pushReplacementNamed('/login');
      } else {
        final error = jsonDecode(response.body);
        _error = error['error'] ?? 'Failed to delete device';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
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

  Future<void> loadDevices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.get(Uri.parse('$baseUrl/api/devices'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final devicesData = data['devices'] as List;
        _devices.clear();
        _devices.addAll(devicesData.map((json) => Device.fromJson(json)));
        notifyListeners();
      } else if (response.statusCode == 401) {
        _error = 'Unauthorized';
        // Redirect to login
        navigatorKey.currentState?.pushReplacementNamed('/login');
      } else {
        final error = jsonDecode(response.body);
        _error = error['error'] ?? 'Failed to load devices';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveDevices() async {
    // Devices are saved in real-time via addDevice/removeDevice
    // This method can be used for any additional save operations if needed
    notifyListeners();
  }
}