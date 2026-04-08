import 'package:flutter/material.dart';
import 'package:http/browser_client.dart';
import 'dart:convert';
import 'package:coselig_staff_portal/main.dart';
import 'package:coselig_staff_portal/models/device_config.dart';

// Device, DeviceConfiguration, DeviceConfigOption are moved to
// lib/models/device_config.dart and imported above.

class DiscoveryService extends ChangeNotifier {
  final String baseUrl =
      'https://employeeservice.coseligtest.workers.dev'; // 使用與 AuthService 相同的 URL
  final BrowserClient _client = BrowserClient()
    ..withCredentials = true; // 自動處理 cookies
  final List<Device> _devices = [];
  final List<DeviceConfiguration> _configurations = [];
  final List<DeviceConfigOption> _deviceConfigOptions = [];
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
  List<DeviceConfigOption> get deviceConfigOptions =>
      List.unmodifiable(_deviceConfigOptions);
  String get currentConfigurationName => _currentConfigurationName;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Combined map for device configurations: brand -> model -> {'types': [...], 'channels': {type: [...]}, 'channel_map': {token: [atomics]}}
  Map<String, Map<String, Map<String, dynamic>>> get deviceConfigs {
    if (_deviceConfigOptions.isNotEmpty) {
      return _buildDeviceConfigsFromOptions();
    }
    _error ??= '裝置設定選項尚未載入，請檢查網路連線或重新整理';
    return _defaultDeviceConfigs;
  }

  Map<String, Map<String, Map<String, dynamic>>>
  _buildDeviceConfigsFromOptions() {
    final Map<String, Map<String, Map<String, dynamic>>> result = {};
    for (final opt in _deviceConfigOptions) {
      result.putIfAbsent(opt.brand, () => {});
      result[opt.brand]![opt.model] = {
        'types': opt.types,
        'channels': opt.channels,
        'channel_map': opt.channelMap,
      };
    }
    return result;
  }

  final Map<String, Map<String, Map<String, dynamic>>> _defaultDeviceConfigs =
      {};

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
      area: device.area,
      brightMinimum: device.brightMinimum ?? 2,
      colortempMinimum: device.type == 'dual'
          ? (device.colortempMinimum ?? 2200)
          : device.colortempMinimum,
      colortempMaximum: device.type == 'dual'
          ? (device.colortempMaximum ?? 5700)
          : device.colortempMaximum,
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
      final parts = <String>[
        'brand: "${device.brand}"',
        'model: "${device.model}"',
        'type: "${device.type}"',
        'module_id: "${device.moduleId}"',
        'channel: "${device.channel}"',
        'name: "${device.name}"',
        'tcp: "${device.tcp}"',
        'bright_minimum: ${device.brightMinimum ?? 2}',
      ];

      if (device.area != null && device.area!.isNotEmpty) {
        parts.add('area: "${device.area}"');
      }

      if (device.type == 'dual') {
        int minTemp = device.colortempMinimum ?? 2200;
        int maxTemp = device.colortempMaximum ?? 5700;
        int convertedMin = (1000000 / maxTemp).round();
        int convertedMax = (1000000 / minTemp).round();
        parts.add('colortemp_minimum: $convertedMin');
        parts.add('colortemp_maximum: $convertedMax');
      }

      buffer.write('    { ${parts.join(', ')} }');
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
        // 生成 entity ID: light.{type}_{module_id}_{channel}_{tcp}
        final entityId =
            'light.${device.type}_${device.moduleId}_${device.channel}_${device.tcp}';

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
  Future<void> saveConfiguration(String name, {int? caseId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final devicesData = _devices.map((d) => d.toJson()).toList();
      final body = {'name': name, 'devices': devicesData};
      if (caseId != null) body['case_id'] = caseId;
      final response = await _client.post(
        Uri.parse('$baseUrl/api/configurations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
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

  Future<void> loadConfiguration(String name, {int? caseId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var uri = '$baseUrl/api/configurations/load?name=$name';
      if (caseId != null) uri += '&case_id=$caseId';
      final response = await _client.get(Uri.parse(uri));

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

  Future<void> fetchConfigurations({int? caseId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var uri = '$baseUrl/api/configurations';
      if (caseId != null) uri += '?case_id=$caseId';
      final response = await _client.get(Uri.parse(uri));

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

  Future<void> deleteConfiguration(String name, {int? caseId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var uri = '$baseUrl/api/configurations?name=$name';
      if (caseId != null) uri += '&case_id=$caseId';
      final response = await _client.delete(Uri.parse(uri));

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

  // ===== 裝置設定選項 CRUD =====

  Future<void> fetchDeviceConfigOptions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/device-config-options'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final options = data['deviceConfigOptions'] as List;
        _deviceConfigOptions.clear();
        _deviceConfigOptions.addAll(
          options.map((json) => DeviceConfigOption.fromJson(json)).toList(),
        );
        notifyListeners();
      } else if (response.statusCode == 401) {
        _error = 'Unauthorized';
        navigatorKey.currentState?.pushReplacementNamed('/login');
      } else {
        final error = jsonDecode(response.body);
        _error = error['error'] ?? 'Failed to fetch device config options';
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

  Future<List<DeviceConfigOption>> fetchAllDeviceConfigOptions() async {
    await fetchDeviceConfigOptions();
    return List.unmodifiable(_deviceConfigOptions);
  }

  /// Export assembled `deviceConfigs` as compact JSON string.
  String exportDeviceConfigsJson() {
    return jsonEncode(deviceConfigs);
  }

  /// Export a JSON Schema describing brand->model->{types,channels,channel_map}.
  String exportDeviceConfigsJsonSchema() {
    final schema = deviceConfigsJsonSchema();
    return jsonEncode(schema);
  }

  Future<void> addDeviceConfigOption(DeviceConfigOption option) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/device-config-options'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(option.toJson()),
      );

      if (response.statusCode == 201) {
        await fetchDeviceConfigOptions();
      } else {
        final error = jsonDecode(response.body);
        _error = error['error'] ?? 'Failed to add device config option';
        notifyListeners();
        throw Exception(_error);
      }
    } catch (e) {
      _error ??= 'Network error: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDeviceConfigOption(
    int id,
    Map<String, dynamic> data,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/api/device-config-options?id=$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        await fetchDeviceConfigOptions();
      } else {
        final error = jsonDecode(response.body);
        _error = error['error'] ?? 'Failed to update device config option';
        notifyListeners();
        throw Exception(_error);
      }
    } catch (e) {
      _error ??= 'Network error: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteDeviceConfigOption(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/api/device-config-options?id=$id'),
      );

      if (response.statusCode == 200) {
        await fetchDeviceConfigOptions();
      } else {
        final error = jsonDecode(response.body);
        _error = error['error'] ?? 'Failed to delete device config option';
        notifyListeners();
        throw Exception(_error);
      }
    } catch (e) {
      _error ??= 'Network error: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class DeviceConfigOption {
  final int? id;
  final String brand;
  final String model;
  final List<String> types;
  final Map<String, List<String>> channels;
  final Map<String, List<String>> channelMap;
  final String? createdAt;
  final String? updatedAt;

  DeviceConfigOption({
    this.id,
    required this.brand,
    required this.model,
    required this.types,
    required this.channels,
    required this.channelMap,
    this.createdAt,
    this.updatedAt,
  });

  factory DeviceConfigOption.fromJson(Map<String, dynamic> json) {
    return DeviceConfigOption(
      id: json['id'],
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      types: (json['types'] as List?)?.cast<String>() ?? [],
      channels:
          (json['channels'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as List).cast<String>()),
          ) ??
          {},
      channelMap:
          (json['channelMap'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as List).cast<String>()),
          ) ??
          {},
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'brand': brand,
      'model': model,
      'types': types,
      'channels': channels,
      'channelMap': channelMap,
    };
  }
}