import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote_models.dart';

class AddSwitchDialog extends StatelessWidget {
  final Function(SwitchModel) onAddSwitch;

  const AddSwitchDialog({super.key, required this.onAddSwitch});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final countController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    final locationController = TextEditingController();

    return AlertDialog(
      title: const Text('新增開關'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: '名稱'),
          ),
          TextField(
            controller: countController,
            decoration: const InputDecoration(labelText: '數量'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: priceController,
            decoration: const InputDecoration(labelText: '價格'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: locationController,
            decoration: const InputDecoration(labelText: '位置'),
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
            final model = SwitchModel(
              name: nameController.text,
              count: int.tryParse(countController.text) ?? 1,
              price: double.tryParse(priceController.text) ?? 0.0,
              location: locationController.text,
            );
            onAddSwitch(model);
            Navigator.of(context).pop();
          },
          child: const Text('新增'),
        ),
      ],
    );
  }
}
