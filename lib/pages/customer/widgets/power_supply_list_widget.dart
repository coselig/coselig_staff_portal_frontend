import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote/power_supply.dart';

class PowerSupplyListWidget extends StatefulWidget {
  final List<PowerSupply> powerSupplies;
  final Function(List<PowerSupply>) onChanged;

  const PowerSupplyListWidget({
    super.key,
    required this.powerSupplies,
    required this.onChanged,
  });

  @override
  State<PowerSupplyListWidget> createState() => _PowerSupplyListWidgetState();
}

class _PowerSupplyListWidgetState extends State<PowerSupplyListWidget> {
  late List<PowerSupply> _items;

  @override
  void initState() {
    super.initState();
    _items = List<PowerSupply>.from(widget.powerSupplies.map((e) => PowerSupply(name: e.name, price: e.price)));
  }

  @override
  void didUpdateWidget(covariant PowerSupplyListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.powerSupplies != widget.powerSupplies) {
      _items = List<PowerSupply>.from(widget.powerSupplies.map((e) => PowerSupply(name: e.name, price: e.price)));
    }
  }

  void _addItem() {
    setState(() {
      _items.add(PowerSupply(name: '', price: 0));
    });
    widget.onChanged(List<PowerSupply>.from(_items));
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    widget.onChanged(List<PowerSupply>.from(_items));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('電源供應配置', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addItem,
              tooltip: '新增電源項目',
            ),
          ],
        ),
        ..._items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.name,
                  decoration: const InputDecoration(labelText: '名稱'),
                  onChanged: (v) {
                    setState(() {
                      item.name = v;
                    });
                    widget.onChanged(List<PowerSupply>.from(_items));
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: TextFormField(
                  initialValue: item.price.toString(),
                  decoration: const InputDecoration(labelText: '價格'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    setState(() {
                      item.price = double.tryParse(v) ?? 0;
                    });
                    widget.onChanged(List<PowerSupply>.from(_items));
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _removeItem(idx),
                tooltip: '刪除',
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}
