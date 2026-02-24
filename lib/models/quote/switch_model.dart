class SwitchModel {
  int? id;
  String name;
  double price;
  int count;
  String fireType;
  bool networkable;
  String protocol;
  String color;

  SwitchModel({
    this.id,
    required this.name,
    required this.price,
    required this.count,
    this.fireType = '',
    this.networkable = false,
    this.protocol = '',
    this.color = '',
  });

  SwitchModel copyWith({
    int? id,
    String? name,
    double? price,
    int? count,
    String? fireType,
    bool? networkable,
    String? protocol,
    String? color,
  }) {
    return SwitchModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      count: count ?? this.count,
      fireType: fireType ?? this.fireType,
      networkable: networkable ?? this.networkable,
      protocol: protocol ?? this.protocol,
      color: color ?? this.color,
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
    };
  }

  factory SwitchModel.fromJson(Map<String, dynamic> json) {
    return SwitchModel(
      id: json['id'],
      name: json['name'] ?? '',
      price: json['price']?.toDouble() ?? 0.0,
      count: json['count'] ?? 1,
      fireType: json['fireType'] ?? '',
      networkable:
          json['networkable'] == true ||
          json['networkable'] == 1 ||
          json['networkable'] == '是',
      protocol: json['protocol'] ?? '',
      color: json['color'] ?? '',
    );
  }
}
