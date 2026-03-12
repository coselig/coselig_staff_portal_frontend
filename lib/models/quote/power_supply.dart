class PowerSupply {
  String name;
  double wattage;
  String type;
  int inputVoltage;
  double price;

  PowerSupply({
    required this.name,
    this.wattage = 0,
    this.type = 'UHP',
    this.inputVoltage = 110,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'wattage': wattage,
    'type': type,
    'inputVoltage': inputVoltage,
    'price': price,
  };

  factory PowerSupply.fromJson(Map<String, dynamic> json) {
    return PowerSupply(
      name: json['name'] ?? '',
      wattage: (json['wattage'] ?? 0).toDouble(),
      type: (json['type'] ?? 'UHP').toString(),
      inputVoltage:
          (json['inputVoltage'] ?? json['input_voltage'] ?? 110) as int,
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}
