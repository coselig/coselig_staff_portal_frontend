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
    String fireType = '單火';
    String networkable = '否';
    String protocol = 'MQTT';
    final colorController = TextEditingController();

    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('新增開關'),
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
              final model = SwitchModel(
                name: nameController.text,
                count: int.tryParse(countController.text) ?? 1,
                price: double.tryParse(priceController.text) ?? 0.0,
                fireType: fireType,
                networkable: networkable == '是',
                protocol: protocol,
                color: colorController.text,
              );
              onAddSwitch(model);
              Navigator.of(context).pop();
            },
            child: const Text('新增'),
          ),
        ],
      ),
    );
  }
}
