class OtherDevice {
  String name;
  double price;

  OtherDevice({required this.name, required this.price});

  factory OtherDevice.fromJson(Map<String, dynamic> json) {
    return OtherDevice(
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
      };
}
