class PowerSupply {
  String name;
  double price;

  PowerSupply({required this.name, required this.price});

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
      };

  factory PowerSupply.fromJson(Map<String, dynamic> json) {
    return PowerSupply(
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}
