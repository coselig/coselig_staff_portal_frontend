import 'switch_gang.dart';

class SwitchModel {
  int? id;
  String name;
  double price;
  int count;
  String fireType;
  bool networkable;
  String protocol;
  String color;
  bool sceneCapable;
  String space;
  List<SwitchGang> gangs;

  SwitchModel({
    this.id,
    required this.name,
    required this.price,
    required this.count,
    this.fireType = '',
    this.networkable = false,
    this.protocol = '',
    this.color = '',
    this.sceneCapable = false,
    this.space = '未分類',
    List<SwitchGang>? gangs,
  }) : gangs = gangs ?? List.generate(count, (_) => SwitchGang());

  /// 所有切控制的迴路名稱（展平）
  List<String> get allControlledLoopNames =>
      gangs.expand((g) => g.controlledLoopNames).toList();

  SwitchModel copyWith({
    int? id,
    String? name,
    double? price,
    int? count,
    String? fireType,
    bool? networkable,
    String? protocol,
    String? color,
    bool? sceneCapable,
    String? space,
    List<SwitchGang>? gangs,
  }) {
    final newCount = count ?? this.count;
    var newGangs = gangs ?? this.gangs.map((g) => g.copyWith()).toList();
    // 當切數變更時，調整 gangs 列表長度
    if (newGangs.length < newCount) {
      newGangs = [
        ...newGangs,
        ...List.generate(newCount - newGangs.length, (_) => SwitchGang()),
      ];
    } else if (newGangs.length > newCount) {
      newGangs = newGangs.sublist(0, newCount);
    }
    return SwitchModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      count: newCount,
      fireType: fireType ?? this.fireType,
      networkable: networkable ?? this.networkable,
      protocol: protocol ?? this.protocol,
      color: color ?? this.color,
      sceneCapable: sceneCapable ?? this.sceneCapable,
      space: space ?? this.space,
      gangs: newGangs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'price': price,
      'count': count,
      'fireType': fireType,
      'networkable': networkable,
      'protocol': protocol,
      'color': color,
      'sceneCapable': sceneCapable,
      'space': space,
      'gangs': gangs.map((g) => g.toJson()).toList(),
    };
  }

  factory SwitchModel.fromJson(Map<String, dynamic> json) {
    final count = json['count'] ?? 1;
    List<SwitchGang> gangs;

    if (json['gangs'] != null) {
      gangs = (json['gangs'] as List)
          .map((g) => SwitchGang.fromJson(g as Map<String, dynamic>))
          .toList();
    } else if (json['controlledLoopNames'] != null) {
      // 向後相容：舊格式的 controlledLoopNames 放到第一切
      final oldNames = (json['controlledLoopNames'] as List)
          .map((e) => e.toString())
          .toList();
      gangs = List.generate(count, (i) {
        if (i == 0 && oldNames.isNotEmpty) {
          return SwitchGang(controlledLoopNames: oldNames);
        }
        return SwitchGang();
      });
    } else {
      gangs = List.generate(count, (_) => SwitchGang());
    }

    // 確保 gangs 長度與 count 一致
    if (gangs.length < count) {
      gangs = [
        ...gangs,
        ...List.generate(count - gangs.length, (_) => SwitchGang()),
      ];
    } else if (gangs.length > count) {
      gangs = gangs.sublist(0, count);
    }

    return SwitchModel(
      id: json['id'],
      name: json['name'] ?? '',
      price: json['price']?.toDouble() ?? 0.0,
      count: count,
      fireType: json['fireType'] ?? json['fire_type'] ?? '',
      networkable:
          json['networkable'] == true ||
          json['networkable'] == 1 ||
          json['networkable'] == '是',
      protocol: json['protocol'] ?? '',
      color: json['color'] ?? '',
      sceneCapable:
          json['sceneCapable'] == true ||
          json['sceneCapable'] == 1 ||
          json['scene_capable'] == true ||
          json['scene_capable'] == 1 ||
          json['sceneCapable'] == '是',
      space: json['space'] ?? '未分類',
      gangs: gangs,
    );
  }
}
