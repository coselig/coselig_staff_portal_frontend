import 'package:coselig_staff_portal/models/quote/loop.dart';

class LoopAllocation {
  Loop loop;
  int allocatedCount;

  LoopAllocation({required this.loop, this.allocatedCount = 1});

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
