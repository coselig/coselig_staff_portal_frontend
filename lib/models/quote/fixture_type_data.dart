class FixtureTypeData {
  final int? id;
  final String type;
  final String quantityLabel;
  final String unitLabel;
  final bool isMeterBased;
  final double price;
  final int defaultUnitWatt;

  const FixtureTypeData({
    this.id,
    required this.type,
    required this.quantityLabel,
    required this.unitLabel,
    this.isMeterBased = false,
    this.price = 0.0,
    this.defaultUnitWatt = 0,
  });
}

const Map<String, FixtureTypeData> defaultFixtureTypeData = {
  '軌道燈': FixtureTypeData(
    type: '軌道燈',
    quantityLabel: '燈具數量',
    unitLabel: '每顆瓦數 (W)',
    defaultUnitWatt: 10,
  ),
  '燈帶': FixtureTypeData(
    type: '燈帶',
    quantityLabel: '米數',
    unitLabel: '每米瓦數 (W/m)',
    isMeterBased: true,
    defaultUnitWatt: 14,
  ),
  '崁燈': FixtureTypeData(
    type: '崁燈',
    quantityLabel: '燈具數量',
    unitLabel: '每顆瓦數 (W)',
    defaultUnitWatt: 10,
  ),
  '射燈': FixtureTypeData(
    type: '射燈',
    quantityLabel: '燈具數量',
    unitLabel: '每顆瓦數 (W)',
    defaultUnitWatt: 7,
  ),
  '吊燈': FixtureTypeData(
    type: '吊燈',
    quantityLabel: '燈具數量',
    unitLabel: '每顆瓦數 (W)',
    defaultUnitWatt: 40,
  ),
};
