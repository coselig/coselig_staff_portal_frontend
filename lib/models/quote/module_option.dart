class ModuleOption {
  final String model;
  final String brand;
  final int channelCount;
  final bool isDimmable;
  final double maxAmperePerChannel;
  final double maxAmpereTotal;
  final double price;

  const ModuleOption({
    required this.model,
    this.brand = '',
    required this.channelCount,
    required this.isDimmable,
    required this.maxAmperePerChannel,
    required this.maxAmpereTotal,
    this.price = 0.0,
  });
}
