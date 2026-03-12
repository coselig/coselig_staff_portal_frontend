class PowerSupply {
  String name;
  double wattage;
  String type;
  int inputVoltage;
  bool supportsBothInputs;
  double price;

  PowerSupply({
    required this.name,
    this.wattage = 0,
    this.type = 'UHP',
    this.inputVoltage = 110,
    this.supportsBothInputs = false,
    required this.price,
  });

  String get inputVoltageLabel =>
      supportsBothInputs ? '110/220' : '$inputVoltage';

  Map<String, dynamic> toJson() => {
    'name': name,
    'wattage': wattage,
    'type': type,
    'inputVoltage': inputVoltage,
    'supportsBothInputs': supportsBothInputs,
    'price': price,
  };

  factory PowerSupply.fromJson(Map<String, dynamic> json) {
    return PowerSupply(
      name: json['name'] ?? '',
      wattage: (json['wattage'] ?? 0).toDouble(),
      type: (json['type'] ?? 'UHP').toString(),
      inputVoltage:
          (json['inputVoltage'] ?? json['input_voltage'] ?? 110) as int,
      supportsBothInputs:
          json['supportsBothInputs'] == true ||
          json['supports_both_inputs'] == 1,
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}
