import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coselig_staff_portal/models/quote_models.dart';

class AddFixtureDialog extends StatefulWidget {
  final Function(String, int) onAddFixture;

  const AddFixtureDialog({super.key, required this.onAddFixture});

  @override
  State<AddFixtureDialog> createState() => _AddFixtureDialogState();
}

class _AddFixtureDialogState extends State<AddFixtureDialog> {
  String selectedType = fixtureTypes[0];
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitWattController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitWattController.dispose();
    super.dispose();
  }

  int _calculateTotalWatt() {
    final isMeterBased = fixtureTypeData[selectedType]!.isMeterBased;
    final quantity = isMeterBased
        ? (double.tryParse(quantityController.text) ?? 0)
        : (int.tryParse(quantityController.text) ?? 0).toDouble();
    final unitWatt = (int.tryParse(unitWattController.text) ?? 0).toDouble();
    return (quantity * unitWatt).round();
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
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
              items: fixtureTypes.map((type) {
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
                hintText: '例如：${selectedType}A區、${selectedType}B區',
              ),
            ),
            const SizedBox(height: 16),

            // 動態輸入欄位基於選擇的類型
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: fixtureTypeData[selectedType]!.quantityLabel,
                      border: const OutlineInputBorder(),
                      hintText: fixtureTypeData[selectedType]!.isMeterBased
                          ? '例如：5.5'
                          : '例如：3',
                    ),
                    keyboardType: fixtureTypeData[selectedType]!.isMeterBased
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.number,
                    inputFormatters: fixtureTypeData[selectedType]!.isMeterBased
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
                      labelText: fixtureTypeData[selectedType]!.unitLabel,
                      border: const OutlineInputBorder(),
                      hintText: '例如：10',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => setState(() {}),
                  ),
                ),
              ],
            ),

            // 總瓦數顯示
            if (quantityController.text.isNotEmpty && unitWattController.text.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
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
              final isMeterBased = fixtureTypeData[selectedType]!.isMeterBased;
              final quantity = isMeterBased
                  ? (double.tryParse(quantityController.text) ?? 0)
                  : (int.tryParse(quantityController.text) ?? 0).toDouble();
              final unitWatt = int.tryParse(unitWattController.text) ?? 0;
              final totalWatt = _calculateTotalWatt();

              if (name.isNotEmpty && quantity > 0 && unitWatt > 0 && totalWatt > 0) {
                widget.onAddFixture(name, totalWatt);
                Navigator.of(context).pop();
              }
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
}