// 安培數檢查結果枚舉
enum AmpereCheckResult {
  ok, // 可以正常加入
  warning, // 超過80%，警告但允許加入
  blocked, // 超過最大限制，不允許加入
}

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

  // 獲取燈具需要的總通道數 (數量 × 單個燈具需要的通道數)
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

class FixtureAllocation {
  LightFixture fixture;
  int allocatedCount;

  FixtureAllocation({required this.fixture, required this.allocatedCount});

  // 獲取本次分配需要的通道數
  int get requiredChannels {
    int channelsPerFixture;
    switch (fixture.dimmingType) {
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
    return allocatedCount * channelsPerFixture;
  }

  FixtureAllocation copyWith({LightFixture? fixture, int? allocatedCount}) {
    return FixtureAllocation(
      fixture: fixture ?? this.fixture,
      allocatedCount: allocatedCount ?? this.allocatedCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fixture': fixture.toJson(),
      'allocatedCount': allocatedCount,
    };
  }

  factory FixtureAllocation.fromJson(Map<String, dynamic> json) {
    return FixtureAllocation(
      fixture: LightFixture.fromJson(json['fixture']),
      allocatedCount: json['allocatedCount'] ?? 0,
    );
  }
}

class LoopAllocation {
  Loop loop;
  int allocatedCount; // 分配的迴路數量（通常為1，因為一個迴路對應一個模組通道組）

  LoopAllocation({required this.loop, this.allocatedCount = 1});

  // 獲取本次分配需要的通道數（基於迴路的調光類型）
  int get requiredChannels {
    int channelsPerLoop;
    switch (loop.dimmingType) {
      case 'WRGB':
        channelsPerLoop = 4;
        break;
      case 'RGB':
        channelsPerLoop = 3;
        break;
      case '雙色溫':
        channelsPerLoop = 2;
        break;
      case '單色溫':
      case '繼電器':
        channelsPerLoop = 1;
        break;
      default:
        channelsPerLoop = 1;
    }
    return allocatedCount * channelsPerLoop;
  }

  LoopAllocation copyWith({Loop? loop, int? allocatedCount}) {
    return LoopAllocation(
      loop: loop ?? this.loop,
      allocatedCount: allocatedCount ?? this.allocatedCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loop': loop.toJson(),
      'allocatedCount': allocatedCount,
    };
  }

  factory LoopAllocation.fromJson(Map<String, dynamic> json) {
    return LoopAllocation(
      loop: Loop.fromJson(json['loop']),
      allocatedCount: json['allocatedCount'] ?? 1,
    );
  }
}

class ModuleOption {
  final String model;
  final int channelCount;
  final bool isDimmable;
  final double maxAmperePerChannel;
  final double maxAmpereTotal;
  final double price;

  const ModuleOption({
    required this.model,
    required this.channelCount,
    required this.isDimmable,
    required this.maxAmperePerChannel,
    required this.maxAmpereTotal,
    this.price = 0.0,
  });
}

class Module {
  String model;
  int channelCount;
  bool isDimmable;
  double maxAmperePerChannel;
  double maxAmpereTotal;
  double price;
  List<FixtureAllocation> allocations;
  List<LoopAllocation> loopAllocations;

  Module({
    required this.model,
    required this.channelCount,
    required this.isDimmable,
    required this.maxAmperePerChannel,
    required this.maxAmpereTotal,
    this.price = 0.0,
    this.allocations = const [],
    this.loopAllocations = const [],
  });

  Module copyWith({
    String? model,
    int? channelCount,
    bool? isDimmable,
    double? maxAmperePerChannel,
    double? maxAmpereTotal,
    double? price,
    List<FixtureAllocation>? allocations,
    List<LoopAllocation>? loopAllocations,
  }) {
    return Module(
      model: model ?? this.model,
      channelCount: channelCount ?? this.channelCount,
      isDimmable: isDimmable ?? this.isDimmable,
      maxAmperePerChannel: maxAmperePerChannel ?? this.maxAmperePerChannel,
      maxAmpereTotal: maxAmpereTotal ?? this.maxAmpereTotal,
      price: price ?? this.price,
      allocations: allocations ?? this.allocations,
      loopAllocations: loopAllocations ?? this.loopAllocations,
    );
  }

  // 獲取已使用的通道數
  int get usedChannels =>
      allocations.fold(
        0,
        (sum, allocation) => sum + allocation.requiredChannels,
      ) +
      loopAllocations.fold(
        0,
        (sum, allocation) => sum + allocation.requiredChannels,
      );

  // 獲取可用通道數
  int get availableChannels => channelCount - usedChannels;

  // 獲取每個通道的最大安培數（基於分配的燈具和迴路）
  List<double> get channelMaxAmperes {
    List<double> amperes = List.filled(channelCount, 0.0);
    int currentChannel = 0;

    // 處理燈具分配
    for (final allocation in allocations) {
      final fixture = allocation.fixture;
      final channelsPerFixture = fixture.requiredChannels ~/ fixture.count;
      final amperePerFixture = fixture.watt / fixture.volt; // 安培 = 瓦特 / 電壓

      for (int i = 0; i < allocation.allocatedCount; i++) {
        for (
          int j = 0;
          j < channelsPerFixture && currentChannel < channelCount;
          j++
        ) {
          amperes[currentChannel] += amperePerFixture;
          currentChannel++;
        }
      }
    }

    // 處理迴路分配
    for (final allocation in loopAllocations) {
      final loop = allocation.loop;
      final channelsPerLoop = _getChannelsPerLoop(loop.dimmingType);
      final totalWatt = loop.fixtures.fold(
        0,
        (sum, fixture) => sum + fixture.totalWatt,
      );
      final amperePerLoop = totalWatt / loop.voltage; // 總安培 = 總瓦特 / 電壓

      // 將總安培平均分配到各個通道
      final amperePerChannel = amperePerLoop / channelsPerLoop;

      for (int i = 0; i < allocation.allocatedCount; i++) {
        for (
          int j = 0;
          j < channelsPerLoop && currentChannel < channelCount;
          j++
        ) {
          amperes[currentChannel] += amperePerChannel;
          currentChannel++;
        }
      }
    }

    return amperes;
  }

  // 獲取模組總最大安培
  double get totalMaxAmpere =>
      channelMaxAmperes.fold(0.0, (sum, ampere) => sum + ampere);

  // 檢查是否可以分配指定數量的燈具
  bool canAssignFixture(LightFixture fixture, int count) {
    int requiredChannels = count * fixture.requiredChannels ~/ fixture.count;
    return availableChannels >= requiredChannels;
  }

  // 檢查是否可以分配迴路
  bool canAssignLoop(Loop loop, int count) {
    int requiredChannels = count * _getChannelsPerLoop(loop.dimmingType);
    return availableChannels >= requiredChannels;
  }

  // 檢查迴路分配的安培數狀態
  AmpereCheckResult checkLoopAmpereLimit(Loop loop, int count) {
    // 計算新迴路需要的總安培數
    final totalWatt = loop.fixtures.fold(
      0,
      (sum, fixture) => sum + fixture.totalWatt,
    );
    final totalAmpereForLoop = totalWatt / loop.voltage;

    // 計算迴路需要的通道數
    final channelsPerLoop = _getChannelsPerLoop(loop.dimmingType);

    // 計算每個通道的安培數
    final amperePerChannel = totalAmpereForLoop / channelsPerLoop;

    // 檢查是否超過每通道最大安培限制
    if (amperePerChannel > maxAmperePerChannel) {
      return AmpereCheckResult.blocked;
    }

    // 模擬加入新迴路後的總安培數
    final currentTotalAmpere = totalMaxAmpere;
    final newTotalAmpere = currentTotalAmpere + totalAmpereForLoop;

    // 檢查是否超過模組總最大安培限制
    if (newTotalAmpere > maxAmpereTotal) {
      return AmpereCheckResult.blocked;
    }

    // 檢查單個迴路是否超過每通道80%警告線
    if (amperePerChannel > maxAmperePerChannel * 0.8) {
      return AmpereCheckResult.warning;
    }

    // 檢查模組總安培是否超過80%警告線
    if (newTotalAmpere > maxAmpereTotal * 0.8) {
      return AmpereCheckResult.warning;
    }

    return AmpereCheckResult.ok;
  }

  // 獲取迴路需要的通道數
  int _getChannelsPerLoop(String dimmingType) {
    switch (dimmingType) {
      case 'WRGB':
        return 4;
      case 'RGB':
        return 3;
      case '雙色溫':
        return 2;
      case '單色溫':
      case '繼電器':
        return 1;
      default:
        return 1;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'channelCount': channelCount,
      'isDimmable': isDimmable,
      'maxAmperePerChannel': maxAmperePerChannel,
      'maxAmpereTotal': maxAmpereTotal,
      'price': price,
      'allocations': allocations.map((a) => a.toJson()).toList(),
      'loopAllocations': loopAllocations.map((l) => l.toJson()).toList(),
    };
  }

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      model: json['model'] ?? '',
      channelCount: json['channelCount'] ?? 0,
      isDimmable: json['isDimmable'] ?? true,
      maxAmperePerChannel: json['maxAmperePerChannel']?.toDouble() ?? 0.0,
      maxAmpereTotal: json['maxAmpereTotal']?.toDouble() ?? 0.0,
      price: json['price']?.toDouble() ?? 0.0,
      allocations: (json['allocations'] as List?)?.map((a) => FixtureAllocation.fromJson(a)).toList() ?? [],
      loopAllocations: (json['loopAllocations'] as List?)?.map((l) => LoopAllocation.fromJson(l)).toList() ?? [],
    );
  }
}

// 燈具類型選項（靜態預設值，作為後備）
const List<String> defaultFixtureTypes = [
  '軌道燈',
  '燈帶',
  '崁燈',
  '射燈',
  '吊燈',
];

class FixtureTypeData {
  final int? id;
  final String type;
  final String quantityLabel;
  final String unitLabel;
  final bool isMeterBased;

  const FixtureTypeData({
    this.id,
    required this.type,
    required this.quantityLabel,
    required this.unitLabel,
    this.isMeterBased = false,
  });
}

const Map<String, FixtureTypeData> defaultFixtureTypeData = {
  '軌道燈': FixtureTypeData(
    type: '軌道燈',
    quantityLabel: '燈具數量',
    unitLabel: '每顆瓦數 (W)',
  ),
  '燈帶': FixtureTypeData(
    type: '燈帶',
    quantityLabel: '米數',
    unitLabel: '每米瓦數 (W/m)',
    isMeterBased: true,
  ),
  '崁燈': FixtureTypeData(
    type: '崁燈',
    quantityLabel: '燈具數量',
    unitLabel: '每顆瓦數 (W)',
  ),
  '射燈': FixtureTypeData(
    type: '射燈',
    quantityLabel: '燈具數量',
    unitLabel: '每顆瓦數 (W)',
  ),
  '吊燈': FixtureTypeData(
    type: '吊燈',
    quantityLabel: '燈具數量',
    unitLabel: '每顆瓦數 (W)',
  ),
};

class LoopFixture {
  String name;
  int totalWatt;

  LoopFixture({
    required this.name,
    required this.totalWatt});

  LoopFixture copyWith({
    String? name,
    int? totalWatt,
  }) {
    return LoopFixture(
      name: name ?? this.name,
      totalWatt: totalWatt ?? this.totalWatt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'totalWatt': totalWatt,
    };
  }

  factory LoopFixture.fromJson(Map<String, dynamic> json) {
    return LoopFixture(
      name: json['name'] ?? '',
      totalWatt: json['totalWatt'] ?? 0,
    );
  }
}

class Loop {
  String name;
  int voltage;
  String dimmingType;
  List<LoopFixture> fixtures;

  Loop({
    required this.name,
    this.voltage = 12,
    this.dimmingType = 'WRGB',
    this.fixtures = const [],
  });

  Loop copyWith({
    String? name,
    int? voltage,
    String? dimmingType,
    List<LoopFixture>? fixtures,
  }) {
    return Loop(
      name: name ?? this.name,
      voltage: voltage ?? this.voltage,
      dimmingType: dimmingType ?? this.dimmingType,
      fixtures: fixtures ?? this.fixtures,
    );
  }

  // 獲取總瓦數
  int get totalWatt =>
      fixtures.fold(0, (sum, fixture) => sum + fixture.totalWatt);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'voltage': voltage,
      'dimmingType': dimmingType,
      'fixtures': fixtures.map((f) => f.toJson()).toList(),
    };
  }

  factory Loop.fromJson(Map<String, dynamic> json) {
    return Loop(
      name: json['name'] ?? '',
      voltage: json['voltage'] ?? 12,
      dimmingType: json['dimmingType'] ?? 'WRGB',
      fixtures: (json['fixtures'] as List?)?.map((f) => LoopFixture.fromJson(f)).toList() ?? [],
    );
  }
}