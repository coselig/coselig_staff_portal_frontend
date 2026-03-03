class LoopFixture {
  String name;
  int totalWatt;
  double price;
  /// 燈具類型（例如 '軌道燈'、'燈帶'），'自訂燈具' 或 null（舊資料）
  String? fixtureType;

  /// 數量（米數或燈具數量）
  double? quantity;

  /// 每單位瓦數
  int? unitWatt;

  LoopFixture({
    required this.name,
    required this.totalWatt,
    this.price = 0.0,
    this.fixtureType,
    this.quantity,
    this.unitWatt,
  });

  LoopFixture copyWith({
    String? name,
    int? totalWatt,
    double? price,
    String? fixtureType,
    double? quantity,
    int? unitWatt,
  }) {
    return LoopFixture(
      name: name ?? this.name,
      totalWatt: totalWatt ?? this.totalWatt,
      price: price ?? this.price,
      fixtureType: fixtureType ?? this.fixtureType,
      quantity: quantity ?? this.quantity,
      unitWatt: unitWatt ?? this.unitWatt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'totalWatt': totalWatt,
      'price': price,
      if (fixtureType != null) 'fixtureType': fixtureType,
      if (quantity != null) 'quantity': quantity,
      if (unitWatt != null) 'unitWatt': unitWatt,
    };
  }

  factory LoopFixture.fromJson(Map<String, dynamic> json) {
    return LoopFixture(
      name: json['name'] ?? '',
      totalWatt: json['totalWatt'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      fixtureType: json['fixtureType'],
      quantity: json['quantity'] != null
          ? (json['quantity'] as num).toDouble()
          : null,
      unitWatt: json['unitWatt'] != null
          ? (json['unitWatt'] as num).toInt()
          : null,
    );
  }
}
