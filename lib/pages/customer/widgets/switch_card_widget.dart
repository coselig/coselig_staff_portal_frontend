import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote_models.dart';

class SwitchCardWidget extends StatelessWidget {
  final int index;
  final SwitchModel switchModel;
  final Function(int, SwitchModel) onUpdateSwitch;
  final Function(int) onRemoveSwitch;

  const SwitchCardWidget({
    super.key,
    required this.index,
    required this.switchModel,
    required this.onUpdateSwitch,
    required this.onRemoveSwitch,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    switchModel.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // 編輯開關
                    _showEditSwitchDialog(context);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => onRemoveSwitch(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('數量：${switchModel.count}'),
            Text('位置：${switchModel.location}'),
            if (switchModel.price > 0) Text('價格：${switchModel.price}'),
          ],
        ),
      ),
    );
  }

  void _showEditSwitchDialog(BuildContext context) {
    final nameController = TextEditingController(text: switchModel.name);
    final countController = TextEditingController(text: switchModel.count.toString());
    final priceController = TextEditingController(text: switchModel.price.toString());
    final locationController = TextEditingController(text: switchModel.location);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('編輯開關'),
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
              final updated = switchModel.copyWith(
                name: nameController.text,
                count: int.tryParse(countController.text) ?? switchModel.count,
                price: double.tryParse(priceController.text) ?? switchModel.price,
                location: locationController.text,
              );
              onUpdateSwitch(index, updated);
              Navigator.of(context).pop();
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }
}
