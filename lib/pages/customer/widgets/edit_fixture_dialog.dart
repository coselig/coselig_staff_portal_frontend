import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coselig_staff_portal/models/quote_models.dart';

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
  late TextEditingController nameController;
  late TextEditingController totalWattController;
  late TextEditingController priceController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.fixture.name);
    totalWattController = TextEditingController(
      text: widget.fixture.totalWatt.toString(),
    );
    priceController = TextEditingController(
      text: widget.fixture.price > 0
          ? widget.fixture.price.toStringAsFixed(1)
          : '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    totalWattController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('修改燈具'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '燈具名稱',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: totalWattController,
            decoration: const InputDecoration(
              labelText: '總瓦數 (W)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: priceController,
            decoration: const InputDecoration(
              labelText: '價格 (選填)',
              border: OutlineInputBorder(),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            onChanged: (_) => setState(() {}),
          ),
          // 預覽
          if (totalWattController.text.isNotEmpty)
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
                        '${int.tryParse(totalWattController.text) ?? 0} W',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (priceController.text.isNotEmpty &&
                      (double.tryParse(priceController.text) ?? 0) > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '價格:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '\$${(double.tryParse(priceController.text) ?? 0).toStringAsFixed(1)}',
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
            final totalWatt = int.tryParse(totalWattController.text) ?? 0;
            final price = double.tryParse(priceController.text) ?? 0.0;

            if (name.isNotEmpty && totalWatt > 0) {
              widget.onUpdateFixture(
                widget.fixture.copyWith(
                  name: name,
                  totalWatt: totalWatt,
                  price: price,
                ),
              );
              Navigator.of(context).pop();
            }
          },
          child: const Text('確定'),
        ),
      ],
    );
  }
}
