import 'loop_fixture.dart';

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

  int get totalWatt => fixtures.fold(0, (sum, fixture) => sum + fixture.totalWatt);

  double get totalFixturePrice => fixtures.fold(0.0, (sum, fixture) => sum + fixture.price);

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
