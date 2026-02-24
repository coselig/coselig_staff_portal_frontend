class LoopFixture {
  String name;
  int totalWatt;
  double price;

  LoopFixture({
    required this.name,
    required this.totalWatt,
    this.price = 0.0,
  });

  LoopFixture copyWith({
    String? name,
    int? totalWatt,
    double? price,
  }) {
    return LoopFixture(
      name: name ?? this.name,
      totalWatt: totalWatt ?? this.totalWatt,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'totalWatt': totalWatt,
      'price': price,
    };
  }

  factory LoopFixture.fromJson(Map<String, dynamic> json) {
    return LoopFixture(
      name: json['name'] ?? '',
      totalWatt: json['totalWatt'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }
}
