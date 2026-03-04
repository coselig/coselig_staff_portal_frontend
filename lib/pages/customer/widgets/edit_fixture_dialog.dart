import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/models/quote/quote_models.dart';
import 'package:coselig_staff_portal/services/quote_service.dart';
import 'package:coselig_staff_portal/utils/icon_utils.dart';

const String _customFixtureType = '自訂燈具';

class EditFixtureDialog extends StatefulWidget {
  final LoopFixture fixture;
  final Function(LoopFixture) onUpdateFixture;

  const EditFixtureDialog({
    super.key,
    required this.fixture,
    required this.onUpdateFixture,
  });

  @override
  State<EditFixtureDialog> createState() => _EditFixtureDialogState();
}

class _EditFixtureDialogState extends State<EditFixtureDialog> {
  late String? selectedType;
  late TextEditingController nameController;
  late TextEditingController quantityController;
  late TextEditingController unitWattController;
  late TextEditingController priceController;

  late QuoteService _quoteService;

  /// 是否有類型資訊（新格式）
  bool get _hasTypeInfo => widget.fixture.fixtureType != null;

  @override
  void initState() {
    super.initState();
    _quoteService = Provider.of<QuoteService>(context, listen: false);

    final fixture = widget.fixture;

    // 初始化類型
    if (_hasTypeInfo) {
      selectedType = fixture.fixtureType;
    } else {
      // 舊資料沒有類型，嘗試從名稱推斷
      final types = _quoteService.fixtureTypes;
      if (types.contains(fixture.name)) {
        selectedType = fixture.name;
      } else {
        selectedType = _customFixtureType;
      }
    }

    nameController = TextEditingController(text: fixture.name);

    // 初始化數量
    if (fixture.quantity != null) {
      final q = fixture.quantity!;
      // 如果是整數就不顯示小數
      quantityController = TextEditingController(
        text: q == q.roundToDouble()
            ? q.toInt().toString()
            : q.toStringAsFixed(1),
      );
    } else {
      quantityController = TextEditingController();
    }

    // 初始化單位瓦數
    if (fixture.unitWatt != null) {
      unitWattController = TextEditingController(
        text: fixture.unitWatt.toString(),
      );
    } else {
      unitWattController = TextEditingController();
    }

    // 價格（只在自訂時使用手動輸入）
    priceController = TextEditingController(
      text: fixture.price > 0 ? fixture.price.toStringAsFixed(1) : '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitWattController.dispose();
    priceController.dispose();
    super.dispose();
  }

  bool get _isCustom => selectedType == _customFixtureType;

  FixtureTypeData? get _currentTypeData {
    if (selectedType == null || _isCustom) return null;
    return _quoteService.fixtureTypeDataMap[selectedType];
  }

  int _getUnitWatt() {
    if (_isCustom) {
      return int.tryParse(unitWattController.text) ?? 0;
    }
    return _currentTypeData?.defaultUnitWatt ?? 0;
  }

  bool get _isMeterBased => _currentTypeData?.isMeterBased ?? false;

  double _getQuantity() {
    if (_isMeterBased) {
      return double.tryParse(quantityController.text) ?? 0;
    }
    return (int.tryParse(quantityController.text) ?? 0).toDouble();
  }

  int _calculateTotalWatt() {
    final quantity = _getQuantity();
    final unitWatt = _getUnitWatt().toDouble();
    return (quantity * unitWatt).round();
  }

  double _calculateTotalPrice() {
    final typeData = _currentTypeData;
    if (typeData == null) {
      return double.tryParse(priceController.text) ?? 0.0;
    }
    final quantity = _getQuantity();
    return quantity * typeData.price;
  }

  String _getFixtureName() {
    if (_isCustom) {
      return nameController.text.trim();
    }
    return selectedType ?? '';
  }

  bool _canShowSummary() {
    if (_isCustom) {
      return quantityController.text.isNotEmpty &&
          unitWattController.text.isNotEmpty;
    }
    return quantityController.text.isNotEmpty && _getUnitWatt() > 0;
  }

  bool _canSubmit() {
    final name = _getFixtureName();
    final quantity = _getQuantity();
    final unitWatt = _getUnitWatt();
    final totalWatt = _calculateTotalWatt();
    return name.isNotEmpty && quantity > 0 && unitWatt > 0 && totalWatt > 0;
  }

  @override
  Widget build(BuildContext context) {
    final types = _quoteService.fixtureTypes;
    final allTypes = [...types, _customFixtureType];

    return StatefulBuilder(
      builder: (context, setState) {
        final typeData = _currentTypeData;
        return AlertDialog(
          title: const Text('修改燈具'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 燈具類型下拉選單
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: '燈具類型',
                    border: OutlineInputBorder(),
                  ),
                  items: allTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(
                        type,
                        style: type == _customFixtureType
                            ? TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontStyle: FontStyle.italic,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                      quantityController.clear();
                      unitWattController.clear();
                      priceController.clear();
                      if (!_isCustom) {
                        nameController.text = value;
                      } else {
                        nameController.clear();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // 自訂燈具：顯示名稱和每單位瓦數輸入欄
                if (_isCustom) ...[
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '燈具名稱',
                      border: OutlineInputBorder(),
                      hintText: '例如：壁燈、檯燈',
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          decoration: const InputDecoration(
                            labelText: '燈具數量',
                            border: OutlineInputBorder(),
                            hintText: '例如：3',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: unitWattController,
                          decoration: const InputDecoration(
                            labelText: '每單位瓦數 (W)',
                            border: OutlineInputBorder(),
                            hintText: '例如：10',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: '價格 (選填)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (value) => setState(() {}),
                  ),
                ],

                // 預設燈具：只顯示數量輸入欄
                if (!_isCustom && typeData != null) ...[
                  // 顯示預設的每單位瓦數資訊
                  if (typeData.defaultUnitWatt > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: context.scaledIconSize(16),
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${typeData.isMeterBased ? "每米" : "每單位"} ${typeData.defaultUnitWatt} W',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (typeData.price > 0) ...[
                            const SizedBox(width: 16),
                            Text(
                              '${typeData.isMeterBased ? "每米" : "每顆"} \$${typeData.price.toStringAsFixed(1)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (typeData.defaultUnitWatt > 0) const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: typeData.quantityLabel,
                      border: const OutlineInputBorder(),
                      hintText: typeData.isMeterBased ? '例如：5.5' : '例如：3',
                    ),
                    keyboardType: typeData.isMeterBased
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.number,
                    inputFormatters: typeData.isMeterBased
                        ? [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ]
                        : [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => setState(() {}),
                  ),
                ],

                // 總瓦數和價格顯示
                if (_canShowSummary())
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '總瓦數:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${_calculateTotalWatt()} W',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        if (_calculateTotalPrice() > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isCustom
                                    ? '價格:'
                                    : '燈具價格 (${typeData!.isMeterBased ? "每米" : "每顆"} \$${typeData.price.toStringAsFixed(1)}):',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '\$${_calculateTotalPrice().toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: _canSubmit()
                  ? () {
                      final name = _getFixtureName();
                      final totalWatt = _calculateTotalWatt();
                      final totalPrice = _calculateTotalPrice();
                      final quantity = _getQuantity();
                      final unitWatt = _getUnitWatt();
                      widget.onUpdateFixture(
                        LoopFixture(
                          name: name,
                          totalWatt: totalWatt,
                          price: totalPrice,
                          fixtureType: selectedType,
                          quantity: quantity,
                          unitWatt: unitWatt,
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  : null,
              child: const Text('確定'),
            ),
          ],
        );
      },
    );
  }
}
