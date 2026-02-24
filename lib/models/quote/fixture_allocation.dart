import 'light_fixture.dart';

class FixtureAllocation {
  LightFixture fixture;
  int allocatedCount;

  FixtureAllocation({required this.fixture, required this.allocatedCount});

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
