import 'dart:convert';

class DeviceConfiguration {
  final int id;
  final int userId;
  final int? caseId;
  final String name;
  final String chineseName;
  final String userName;
  final String createdAt;
  final String updatedAt;
  final List<Device>? devices;

  DeviceConfiguration({
    required this.id,
    required this.userId,
    this.caseId,
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
      caseId: json['case_id'] != null
          ? (json['case_id'] is int
                ? json['case_id']
                : int.tryParse(json['case_id'].toString()))
          : null,
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
  String? id;
  String brand;
  String model;
  String type;
  String moduleId;
  String channel;
  String name;
  String tcp;
  String? area;
  int? brightMinimum;
  int? colortempMinimum;
  int? colortempMaximum;

  Device({
    this.id,
    required this.brand,
    required this.model,
    required this.type,
    required this.moduleId,
    required this.channel,
    required this.name,
    required this.tcp,
    this.area,
    this.brightMinimum,
    this.colortempMinimum,
    this.colortempMaximum,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    final type = json['type'] as String? ?? '';
    final parsedBright = parseInt(json['bright_minimum']) ?? 2;
    final parsedCtMin = parseInt(json['colortemp_minimum']);
    final parsedCtMax = parseInt(json['colortemp_maximum']);

    return Device(
      id: json['id']?.toString(),
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      type: type,
      moduleId: json['module_id'] ?? '',
      channel: json['channel'] ?? '',
      name: json['name'] ?? '',
      tcp: json['tcp'] ?? '',
      brightMinimum: parsedBright,
      area: json['area'] as String?,
      colortempMinimum: type == 'dual' ? (parsedCtMin ?? 2200) : parsedCtMin,
      colortempMaximum: type == 'dual' ? (parsedCtMax ?? 5700) : parsedCtMax,
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
      if (area != null && area!.isNotEmpty) 'area': area,
      if (brightMinimum != null) 'bright_minimum': brightMinimum,
      if (colortempMinimum != null) 'colortemp_minimum': colortempMinimum,
      if (colortempMaximum != null) 'colortemp_maximum': colortempMaximum,
    };
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
      channels: (json['channels'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as List).cast<String>()),
          ) ??
          {},
      channelMap: (json['channelMap'] as Map<String, dynamic>?)?.map(
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

Map<String, dynamic> deviceConfigsJsonSchema() {
  return {
    r"$schema": "http://json-schema.org/draft-07/schema#",
    'type': 'object',
    'additionalProperties': {
      'type': 'object',
      'additionalProperties': {
        'type': 'object',
        'properties': {
          'types': {
            'type': 'array',
            'items': {'type': 'string'},
          },
          'channels': {
            'type': 'object',
            'additionalProperties': {
              'type': 'array',
              'items': {'type': 'string'},
            },
          },
          'channel_map': {
            'type': 'object',
            'additionalProperties': {
              'type': 'array',
              'items': {'type': 'string'},
            },
          },
        },
        'required': ['types', 'channels', 'channel_map'],
      },
    },
  };
}
