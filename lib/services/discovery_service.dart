import 'package:flutter/material.dart';
import 'package:http/browser_client.dart';
import 'dart:convert';
import 'package:coselig_staff_portal/main.dart';

class DeviceConfiguration {
  final int id;
  final int userId;
  final String name;
  final String chineseName;
  final String userName;
  final String createdAt;
  final String updatedAt;
  final List<Device>? devices;

  DeviceConfiguration({
    required this.id,
    required this.userId,
    required this.name,
    required this.chineseName,
    required this.userName,
    required this.createdAt,
    required this.updatedAt,
    this.devices,
  });

  factory DeviceConfiguration.fromJson(Map<String, dynamic> json) {
    return DeviceConfiguration(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      chineseName: json['chinese_name'] ?? json['user_name'] ?? 'Unknown',
      userName: json['user_name'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      devices: json['devices'] != null
          ? (jsonDecode(json['devices']) as List)
                .map((d) => Device.fromJson(d))
                .toList()
          : null,
    );
  }
}

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
  final List<DeviceConfiguration> _configurations = [];
  String _generatedOutput = '';
  String _currentConfigurationName = '新配置';
  bool _isLoading = false;
  String? _error;

  String get generatedOutput => _generatedOutput;
  List<String> get brands => deviceConfigs.keys.toList();
  Map<String, List<String>> get models => deviceConfigs.map(
    (brand, modelsMap) => MapEntry(brand, modelsMap.keys.toList()),
  );

  List<Device> get devices => List.unmodifiable(_devices);
  List<DeviceConfiguration> get configurations =>
      List.unmodifiable(_configurations);
  String get currentConfigurationName => _currentConfigurationName;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Combined map for device configurations: brand -> model -> {'types': [...], 'channels': {type: [...]}, 'channel_map': {token: [atomics]}}
  final Map<String, Map<String, Map<String, dynamic>>> deviceConfigs = {
    'sunwave': {
      'p404': {
        'types': ['dual', 'single', 'rgb'],
        'channels': {
          'dual': ['a', 'b'],
          'single': ['1', '2', '3', '4'],
          'rgb': ['x'],
        },
        'channel_map': {
          'a': ['1', '2'],
          'b': ['3', '4'],
          'x': ['1', '2', '3'],
        },
      },
      'p210': {
        'types': ['dual', 'single'],
        'channels': {
          'dual': ['a'],
          'single': ['1', '2'],
        },
        'channel_map': {
          'a': ['1', '2'],
        },
      },
      'U4': {
        'types': ['dual', 'single', 'rgb'],
        'channels': {
          'dual': ['a', 'b'],
          'single': ['1', '2', '3', '4'],
          'rgb': ['x'],
        },
        'channel_map': {
          'a': ['1', '2'],
          'b': ['3', '4'],
          'x': ['1', '2', '3'],
        },
      },
      'R8A': {
        'types': ['relay'],
        'channels': {
          'relay': ['1', '2', '3', '4', '5', '6', '7', '8'],
        },
        'channel_map': {},
      },
      'R410': {
        'types': ['relay'],
        'channels': {
          'relay': ['1', '2', '3', '4'],
        },
        'channel_map': {},
      },
    },
    'guo': {
      'p805': {
        'types': ['dual', 'single'],
        'channels': {
          'dual': ['a', 'b', 'c', 'd'],
          'single': ['1', '2', '3', '4', '5', '6', '7', '8'],
        },
        'channel_map': {
          'a': ['1', '2'],
          'b': ['3', '4'],
          'c': ['5', '6'],
          'd': ['7', '8'],
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

  // Expand a channel token into its underlying atomic channels.
  // E.g. 'x' -> ['1','2','3'], 'a' -> ['1','2'].
  List<String> _expandChannel(String brand, String model, String channel) {
    final modelConfig = deviceConfigs[brand]?[model];
    if (modelConfig == null) return [channel];
    final channelMap = modelConfig['channel_map'] as Map<String, dynamic>?;
    if (channelMap != null && channelMap.containsKey(channel)) {
      final mapped = channelMap[channel];
      if (mapped is List) return mapped.cast<String>();
    }
    return [channel];
  }

  /// 返回在指定模組 (moduleId) 下，針對某個 type 可選的 channel tokens（已過濾被佔用的）
  List<String> getSelectableChannelsForModule(
    String brand,
    String model,
    String type,
    String moduleId,
  ) {
    final tokens =
        deviceConfigs[brand]?[model]?['channels']?[type] as List<String>? ??
        ['1'];

    // 已被佔用的 atomic channels
    final existingDevices = _devices
        .where((d) => d.moduleId == moduleId)
        .toList();
    final usedAtoms = <String>{};
    for (final d in existingDevices) {
      usedAtoms.addAll(_expandChannel(d.brand, d.model, d.channel));
    }

    final selectable = <String>[];
    for (final token in tokens) {
      final required = _expandChannel(brand, model, token).toSet();
      // token 可選的條件：它所需的 atomic channels 與已用的 atomic channels 沒有交集
      if (required.intersection(usedAtoms).isEmpty) {
        selectable.add(token);
      }
    }
    return selectable;
  }

  /// 檢查是否可以添加指定的裝置
  /// 規則改為：以 atomic channel (擴展後) 為粒度。如果 newDevice 需要的所有 atomic channels 都未被佔用，則允許添加
  bool canAddDevice(Device newDevice) {
    // 獲取該模組ID的所有現有裝置
    final existingDevices = _devices
        .where((d) => d.moduleId == newDevice.moduleId)
        .toList();

    if (existingDevices.isEmpty) {
      return true;
    }

    // 獲取該 model 的 atomic channels（所有 token 擴展後的聯集）
    final allAvailableAtoms = <String>{};
    final modelConfig = deviceConfigs[newDevice.brand]?[newDevice.model];
    if (modelConfig != null) {
      final channelsMap = modelConfig['channels'] as Map<String, dynamic>;
      for (final channels in channelsMap.values) {
        if (channels is List) {
          for (final token in channels.cast<String>()) {
            allAvailableAtoms.addAll(
              _expandChannel(newDevice.brand, newDevice.model, token),
            );
          }
        }
      }
    }

    // 如果沒有配置，默認允許
    if (allAvailableAtoms.isEmpty) {
      return true;
    }

    // 計算已被佔用的 atomic channels
    final usedAtoms = <String>{};
    for (final d in existingDevices) {
      usedAtoms.addAll(_expandChannel(d.brand, d.model, d.channel));
    }

    final availableAtoms = allAvailableAtoms.difference(usedAtoms);

    // newDevice 需要的 atomic channels
    final requiredAtoms = _expandChannel(
      newDevice.brand,
      newDevice.model,
      newDevice.channel,
    ).toSet();

    // 只有當 newDevice 所需的所有 atomic channels 都是可用的，才能添加
    return requiredAtoms.difference(availableAtoms).isEmpty;
  }

  void addDevice(Device device) {
    // 在發送API請求前進行邏輯檢查
    if (!canAddDevice(device)) {
      _error = '無法添加裝置：模組ID的所有通道都已被使用';
      notifyListeners();
      return;
    }

    // 本地添加裝置，不再呼叫後端 API
    // 生成一個本地 ID
    final newDevice = Device(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      brand: device.brand,
      model: device.model,
      type: device.type,
      moduleId: device.moduleId,
      channel: device.channel,
      name: device.name,
      tcp: device.tcp,
    );
    _devices.add(newDevice);
    notifyListeners();
  }

  void removeDevice(String deviceId) {
    _devices.removeWhere((device) => device.id == deviceId);
    notifyListeners();
  }

  /// 重新排序設備列表
  void reorderDevices(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final device = _devices.removeAt(oldIndex);
    _devices.insert(newIndex, device);
    notifyListeners();
  }

  /// 向上移動設備
  void moveDeviceUp(int index) {
    if (index > 0) {
      final device = _devices.removeAt(index);
      _devices.insert(index - 1, device);
      notifyListeners();
    }
  }

  /// 向下移動設備
  void moveDeviceDown(int index) {
    if (index < _devices.length - 1) {
      final device = _devices.removeAt(index);
      _devices.insert(index + 1, device);
      notifyListeners();
    }
  }

  void updateDevice(Device device) {
    if (device.id == null) return;

    final index = _devices.indexWhere((d) => d.id == device.id);
    if (index != -1) {
      _devices[index] = device;
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

  String generateYamlOutput() {
    StringBuffer buffer = StringBuffer();

    buffer.writeln('views:');
    buffer.writeln('  - type: sections');
    buffer.writeln('    max_columns: 4');
    buffer.writeln('    title: $_currentConfigurationName');
    buffer.writeln('    path: unknown');
    buffer.writeln('    sections:');

    // 按照 tcp 分組（tcp: "1" 為一組，其他可以分更多組）
    final groupedByTcp = <String, List<Device>>{};
    for (final device in _devices) {
      final tcpKey = device.tcp.isEmpty ? '未分組' : device.tcp;
      groupedByTcp.putIfAbsent(tcpKey, () => []).add(device);
    }

    // 為每個 TCP 組生成一個 section
    for (final entry in groupedByTcp.entries) {
      final tcpGroup = entry.key;
      final devices = entry.value;

      buffer.writeln('      - type: grid');
      buffer.writeln('        cards:');
      buffer.writeln('          - type: heading');
      buffer.writeln('            heading_style: title');
      buffer.writeln('            heading: TCP $tcpGroup');

      // 為每個設備生成一個 tile
      for (final device in devices) {
        // 生成 entity ID: light.{type}_{module_id}_{channel}
        final entityId =
            'light.${device.type}_${device.moduleId}_${device.channel}';

        buffer.writeln('          - type: tile');
        buffer.writeln('            entity: $entityId');
        buffer.writeln('            name: ${device.name}');
        buffer.writeln('            vertical: false');
        buffer.writeln('            features_position: bottom');
        buffer.writeln('            features:');
        buffer.writeln('              - type: light-brightness');

        // dual 類型添加色溫控制
        if (device.type == 'dual') {
          buffer.writeln('              - type: light-color-temp');
        }
      }
    }

    _generatedOutput = buffer.toString();
    notifyListeners();
    return _generatedOutput;
  }

  // Configuration management
  Future<void> saveConfiguration(String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final devicesData = _devices.map((d) => d.toJson()).toList();
      final response = await _client.post(
        Uri.parse('$baseUrl/api/configurations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'devices': devicesData}),
      );

      if (response.statusCode == 200) {
        // Success
      } else if (response.statusCode == 401) {
        _error = 'Unauthorized';
        navigatorKey.currentState?.pushReplacementNamed('/login');
      } else {
        final error = jsonDecode(response.body);
        _error = error['error'] ?? 'Failed to save configuration';
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

  Future<void> loadConfiguration(String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/configurations/load?name=$name'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final devicesData = data['devices'] as List;
        _devices.clear();
        _devices.addAll(
          devicesData.map((json) => Device.fromJson(json)).toList(),
        );
        notifyListeners();
      } else if (response.statusCode == 401) {
        _error = 'Unauthorized';
        navigatorKey.currentState?.pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      } else {
        final error = jsonDecode(response.body);
        _error = error['error'] ?? 'Failed to load configuration';
        notifyListeners();
        throw Exception(_error);
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchConfigurations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/configurations'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final configs = data['configurations'] as List;
        _configurations.clear();
        _configurations.addAll(
          configs.map((json) => DeviceConfiguration.fromJson(json)).toList(),
        );
        notifyListeners();
      } else if (response.statusCode == 401) {
        _error = 'Unauthorized';
        navigatorKey.currentState?.pushReplacementNamed('/login');
      } else {
        final error = jsonDecode(response.body);
        _error = error['error'] ?? 'Failed to get configurations';
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

  Future<List<String>> getConfigurationNames() async {
    await fetchConfigurations();
    return _configurations.map((config) => config.name).toList();
  }

  Future<void> deleteConfiguration(String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/api/configurations?name=$name'),
      );

      if (response.statusCode == 200) {
        // Success
      } else if (response.statusCode == 401) {
        _error = 'Unauthorized';
        navigatorKey.currentState?.pushReplacementNamed('/login');
      } else {
        final error = jsonDecode(response.body);
        _error = error['error'] ?? 'Failed to delete configuration';
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

  // 清空設備列表
  void clearDevices() {
    _devices.clear();
    notifyListeners();
  }

  // 設置當前配置名稱
  void setConfigurationName(String name) {
    _currentConfigurationName = name;
    notifyListeners();
  }
}