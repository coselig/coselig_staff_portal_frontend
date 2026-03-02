import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote/material_item.dart';

class ItemListWidget extends StatefulWidget {
  final String title;
  final String addTooltip;
  final List<MaterialItem> items;
  final Function(List<MaterialItem>) onChanged;

  const ItemListWidget({
    super.key,
    required this.title,
    required this.items,
    required this.onChanged,
    this.addTooltip = '新增項目',
  });

  @override
  State<ItemListWidget> createState() => _ItemListWidgetState();
}

class _ItemListWidgetState extends State<ItemListWidget> {
  late List<MaterialItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List<MaterialItem>.from(
      widget.items.map((e) => MaterialItem(name: e.name, price: e.price)),
    );
  }

  @override
  void didUpdateWidget(covariant ItemListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _items = List<MaterialItem>.from(
        widget.items.map((e) => MaterialItem(name: e.name, price: e.price)),
      );
    }
  }

  void _addItem() {
    setState(() {
      _items.add(MaterialItem(name: '', price: 0));
    });
    widget.onChanged(List<MaterialItem>.from(_items));
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    widget.onChanged(List<MaterialItem>.from(_items));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addItem,
              tooltip: widget.addTooltip,
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
                  decoration: const InputDecoration(labelText: '品項名稱'),
                  onChanged: (v) {
                    setState(() {
                      item.name = v;
                    });
                    widget.onChanged(List<MaterialItem>.from(_items));
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: TextFormField(
                  initialValue: item.price.toString(),
                  decoration: const InputDecoration(labelText: '品項價格'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    setState(() {
                      item.price = double.tryParse(v) ?? 0;
                    });
                    widget.onChanged(List<MaterialItem>.from(_items));
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
        }),
      ],
    );
  }
}
