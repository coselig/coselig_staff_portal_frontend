import 'package:coselig_staff_portal/models/quote/fixture_allocation.dart';
import 'package:coselig_staff_portal/models/quote/loop_allocation.dart';
import 'package:coselig_staff_portal/models/quote/ampere_check_result.dart';
import 'package:coselig_staff_portal/models/quote/light_fixture.dart';

class Module {
  String model;
  String brand;
  int channelCount;
  bool isDimmable;
  double maxAmperePerChannel;
  double maxAmpereTotal;
  double price;
  List<FixtureAllocation> allocations;
  List<LoopAllocation> loopAllocations;

  Module({
    required this.model,
    this.brand = '',
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
    String? brand,
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
      brand: brand ?? this.brand,
      channelCount: channelCount ?? this.channelCount,
      isDimmable: isDimmable ?? this.isDimmable,
      maxAmperePerChannel: maxAmperePerChannel ?? this.maxAmperePerChannel,
      maxAmpereTotal: maxAmpereTotal ?? this.maxAmpereTotal,
      price: price ?? this.price,
      allocations: allocations ?? this.allocations,
      loopAllocations: loopAllocations ?? this.loopAllocations,
    );
  }

  int get usedChannels =>
      allocations.fold(0, (sum, allocation) => sum + allocation.requiredChannels) +
      loopAllocations.fold(0, (sum, allocation) => sum + allocation.requiredChannels);

  int get availableChannels => channelCount - usedChannels;

  List<double> get channelMaxAmperes {
    List<double> amperes = List.filled(channelCount, 0.0);
    int currentChannel = 0;

    for (final allocation in allocations) {
      final fixture = allocation.fixture;
      final channelsPerFixture = fixture.requiredChannels ~/ fixture.count;
      final amperePerFixture = fixture.watt / fixture.volt;
      for (int i = 0; i < allocation.allocatedCount; i++) {
        for (int j = 0; j < channelsPerFixture && currentChannel < channelCount; j++) {
          amperes[currentChannel] += amperePerFixture;
          currentChannel++;
        }
      }
    }

    for (final allocation in loopAllocations) {
      final loop = allocation.loop;
      final channelsPerLoop = _getChannelsPerLoop(loop.dimmingType);
      final totalWatt = loop.fixtures.fold(0, (sum, fixture) => sum + fixture.totalWatt);
      final amperePerLoop = totalWatt / loop.voltage;
      final amperePerChannel = amperePerLoop / channelsPerLoop;
      for (int i = 0; i < allocation.allocatedCount; i++) {
        for (int j = 0; j < channelsPerLoop && currentChannel < channelCount; j++) {
          amperes[currentChannel] += amperePerChannel;
          currentChannel++;
        }
      }
    }
    return amperes;
  }

  double get totalMaxAmpere => channelMaxAmperes.fold(0.0, (sum, ampere) => sum + ampere);

  bool canAssignFixture(LightFixture fixture, int count) {
    int requiredChannels = count * fixture.requiredChannels ~/ fixture.count;
    return availableChannels >= requiredChannels;
  }

  bool canAssignLoop(loop, int count) {
    int requiredChannels = count * _getChannelsPerLoop(loop.dimmingType);
    return availableChannels >= requiredChannels;
  }

  AmpereCheckResult checkLoopAmpereLimit(loop, int count) {
    final totalWatt = loop.fixtures.fold(0, (sum, fixture) => sum + fixture.totalWatt);
    final totalAmpereForLoop = totalWatt / loop.voltage;
    final channelsPerLoop = _getChannelsPerLoop(loop.dimmingType);
    final amperePerChannel = totalAmpereForLoop / channelsPerLoop;
    if (amperePerChannel > maxAmperePerChannel) {
      return AmpereCheckResult.blocked;
    }
    final currentTotalAmpere = totalMaxAmpere;
    final newTotalAmpere = currentTotalAmpere + totalAmpereForLoop;
    if (newTotalAmpere > maxAmpereTotal) {
      return AmpereCheckResult.blocked;
    }
    if (amperePerChannel > maxAmperePerChannel * 0.8) {
      return AmpereCheckResult.warning;
    }
    if (newTotalAmpere > maxAmpereTotal * 0.8) {
      return AmpereCheckResult.warning;
    }
    return AmpereCheckResult.ok;
  }

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
      'brand': brand,
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
      brand: json['brand'] ?? '',
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
