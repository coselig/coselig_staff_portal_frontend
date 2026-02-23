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
            if (switchModel.price > 0) Text('價格：${switchModel.price}'),
            Text('單火/零火：${switchModel.fireType}'),
            Text('是否可以聯網：${switchModel.networkable ? '是' : '否'}'),
            Text('協定類型：${switchModel.protocol}'),
            Text('顏色：${switchModel.color}'),
          ],
        ),
      ),
    );
  }

  void _showEditSwitchDialog(BuildContext context) {
    final nameController = TextEditingController(text: switchModel.name);
    final countController = TextEditingController(text: switchModel.count.toString());
    final priceController = TextEditingController(text: switchModel.price.toString());
    String fireType = switchModel.fireType.isNotEmpty
        ? switchModel.fireType
        : '單火';
    String networkable = switchModel.networkable ? '是' : '否';
    String protocol = switchModel.protocol.isNotEmpty
        ? switchModel.protocol
        : 'MQTT';
    final colorController = TextEditingController(text: switchModel.color);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('編輯開關'),
          content: SingleChildScrollView(
            child: Column(
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
                DropdownButtonFormField<String>(
                  value: fireType,
                  decoration: const InputDecoration(labelText: '單火/零火'),
                  items: ['單火', '零火']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => fireType = v ?? '單火'),
                ),
                DropdownButtonFormField<String>(
                  value: networkable,
                  decoration: const InputDecoration(labelText: '是否可以聯網'),
                  items: ['是', '否']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => networkable = v ?? '否'),
                ),
                DropdownButtonFormField<String>(
                  value: protocol,
                  decoration: const InputDecoration(labelText: '協定類型'),
                  items: ['MQTT', 'zigbee', '藍芽', 'matter']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => protocol = v ?? 'MQTT'),
                ),
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(labelText: '顏色'),
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
              onPressed: () {
                final updated = switchModel.copyWith(
                  name: nameController.text,
                  count:
                      int.tryParse(countController.text) ?? switchModel.count,
                  price:
                      double.tryParse(priceController.text) ??
                      switchModel.price,
                  fireType: fireType,
                  networkable: networkable == '是',
                  protocol: protocol,
                  color: colorController.text,
                );
                onUpdateSwitch(index, updated);
                Navigator.of(context).pop();
              },
              child: const Text('儲存'),
            ),
          ],
        ),
      ),
    );
  }
}
