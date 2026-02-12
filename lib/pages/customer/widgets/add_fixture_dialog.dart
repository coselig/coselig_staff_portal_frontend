import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/models/quote_models.dart';
import 'package:coselig_staff_portal/services/quote_service.dart';

class AddFixtureDialog extends StatefulWidget {
  final Function(String, int, double) onAddFixture;

  const AddFixtureDialog({super.key, required this.onAddFixture});

  @override
  State<AddFixtureDialog> createState() => _AddFixtureDialogState();
}

class _AddFixtureDialogState extends State<AddFixtureDialog> {
  String? selectedType;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitWattController = TextEditingController();

  late QuoteService _quoteService;

  @override
  void initState() {
    super.initState();
    _quoteService = Provider.of<QuoteService>(context, listen: false);
    final types = _quoteService.fixtureTypes;
    if (types.isNotEmpty) {
      selectedType = types[0];
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitWattController.dispose();
    super.dispose();
  }

  FixtureTypeData? get _currentTypeData {
    if (selectedType == null) return null;
    return _quoteService.fixtureTypeDataMap[selectedType];
  }

  int _calculateTotalWatt() {
    final typeData = _currentTypeData;
    if (typeData == null) return 0;
    final isMeterBased = typeData.isMeterBased;
    final quantity = isMeterBased
        ? (double.tryParse(quantityController.text) ?? 0)
        : (int.tryParse(quantityController.text) ?? 0).toDouble();
    final unitWatt = (int.tryParse(unitWattController.text) ?? 0).toDouble();
    return (quantity * unitWatt).round();
  }

  double _calculateTotalPrice() {
    final typeData = _currentTypeData;
    if (typeData == null) return 0.0;
    final isMeterBased = typeData.isMeterBased;
    final quantity = isMeterBased
        ? (double.tryParse(quantityController.text) ?? 0)
        : (int.tryParse(quantityController.text) ?? 0).toDouble();
    return quantity * typeData.price;
  }

  @override
  Widget build(BuildContext context) {
    final types = _quoteService.fixtureTypes;

    return StatefulBuilder(
      builder: (context, setState) {
        final typeData = _currentTypeData;
        return AlertDialog(
          title: const Text('添加燈具'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 燈具類型下拉選單
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: '燈具類型',
                  border: OutlineInputBorder(),
                ),
                items: types.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedType = value!;
                    quantityController.clear();
                    unitWattController.clear();
                  });
                },
              ),
              const SizedBox(height: 16),

              // 燈具名稱輸入
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '燈具名稱',
                  border: const OutlineInputBorder(),
                  hintText:
                      '例如：${selectedType ?? ''}A區、${selectedType ?? ''}B區',
                ),
              ),
              const SizedBox(height: 16),

              // 動態輸入欄位基於選擇的類型
              if (typeData != null)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        decoration: InputDecoration(
                          labelText: typeData.quantityLabel,
                          border: const OutlineInputBorder(),
                          hintText: typeData.isMeterBased ? '例如：5.5' : '例如：3',
                        ),
                        keyboardType: typeData.isMeterBased
                            ? const TextInputType.numberWithOptions(
                                decimal: true,
                              )
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
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: unitWattController,
                        decoration: InputDecoration(
                          labelText: typeData.unitLabel,
                          border: const OutlineInputBorder(),
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

              // 總瓦數和價格顯示
              if (quantityController.text.isNotEmpty &&
                  unitWattController.text.isNotEmpty)
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
                      if ((_currentTypeData?.price ?? 0) > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '燈具價格 (${_currentTypeData!.isMeterBased ? "每米" : "每顆"} \$${_currentTypeData!.price.toStringAsFixed(1)}):',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '\$${_calculateTotalPrice().toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final isMeterBased = typeData?.isMeterBased ?? false;
                final quantity = isMeterBased
                    ? (double.tryParse(quantityController.text) ?? 0)
                    : (int.tryParse(quantityController.text) ?? 0).toDouble();
                final unitWatt = int.tryParse(unitWattController.text) ?? 0;
                final totalWatt = _calculateTotalWatt();

                if (name.isNotEmpty &&
                    quantity > 0 &&
                    unitWatt > 0 &&
                    totalWatt > 0) {
                  final totalPrice = _calculateTotalPrice();
                  widget.onAddFixture(name, totalWatt, totalPrice);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('確定'),
            ),
          ],
        );
      },
    );
  }
}
