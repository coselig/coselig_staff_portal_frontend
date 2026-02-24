class LightFixture {
  String name;
  int count = 1;
  int watt = 10;
  int volt = 12;
  bool isCustomVolt = false;
  String dimmingType = 'WRGB';
  bool needsRelay = false;
  String relayType = '大功率';

  LightFixture({
    required this.name,
    int? count,
    int? watt,
    int? volt,
    bool? isCustomVolt,
    String? dimmingType,
    bool? needsRelay,
    String? relayType,
  }) {
    this.count = count ?? this.count;
    this.watt = watt ?? this.watt;
    this.volt = volt ?? this.volt;
    this.isCustomVolt = isCustomVolt ?? this.isCustomVolt;
    this.dimmingType = dimmingType ?? this.dimmingType;
    this.needsRelay = needsRelay ?? this.needsRelay;
    this.relayType = relayType ?? this.relayType;
  }

  LightFixture copyWith({
    String? name,
    int? count,
    int? watt,
    int? volt,
    bool? isCustomVolt,
    String? dimmingType,
    bool? needsRelay,
    String? relayType,
  }) {
    return LightFixture(
      name: name ?? this.name,
      count: count ?? this.count,
      watt: watt ?? this.watt,
      volt: volt ?? this.volt,
      isCustomVolt: isCustomVolt ?? this.isCustomVolt,
      dimmingType: dimmingType ?? this.dimmingType,
      needsRelay: needsRelay ?? this.needsRelay,
      relayType: relayType ?? this.relayType,
    );
  }

  int get requiredChannels {
    int channelsPerFixture;
    switch (dimmingType) {
      case 'WRGB':
        channelsPerFixture = 4;
        break;
      case 'RGB':
        channelsPerFixture = 3;
        break;
      case '雙色溫':
        channelsPerFixture = 2;
        break;
      case '單色溫':
      case '繼電器':
        channelsPerFixture = 1;
        break;
      default:
        channelsPerFixture = 1;
    }
    return count * channelsPerFixture;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'count': count,
      'watt': watt,
      'volt': volt,
      'isCustomVolt': isCustomVolt,
      'dimmingType': dimmingType,
      'needsRelay': needsRelay,
      'relayType': relayType,
    };
  }

  factory LightFixture.fromJson(Map<String, dynamic> json) {
    return LightFixture(
      name: json['name'] ?? '',
      count: json['count'] ?? 1,
      watt: json['watt'] ?? 10,
      volt: json['volt'] ?? 12,
      isCustomVolt: json['isCustomVolt'] ?? false,
      dimmingType: json['dimmingType'] ?? 'WRGB',
      needsRelay: json['needsRelay'] ?? false,
      relayType: json['relayType'] ?? '大功率',
    );
  }
}
