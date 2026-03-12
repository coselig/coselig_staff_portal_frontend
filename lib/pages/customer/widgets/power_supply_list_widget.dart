import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote/power_supply.dart';

class PowerSupplyListWidget extends StatefulWidget {
  final List<PowerSupply> powerSupplies;
  final List<PowerSupply> availableOptions;
  final Function(List<PowerSupply>) onChanged;

  const PowerSupplyListWidget({
    super.key,
    required this.powerSupplies,
    required this.availableOptions,
    required this.onChanged,
  });

  @override
  State<PowerSupplyListWidget> createState() => _PowerSupplyListWidgetState();
}

class _PowerSupplyListWidgetState extends State<PowerSupplyListWidget> {
  late List<PowerSupply> _items;

  List<PowerSupply> _cloneList(List<PowerSupply> source) {
    return List<PowerSupply>.from(
      source.map(
        (e) => PowerSupply(
          name: e.name,
          wattage: e.wattage,
          type: e.type,
          inputVoltage: e.inputVoltage,
          supportsBothInputs: e.supportsBothInputs,
          price: e.price,
        ),
      ),
    );
  }

  String _optionKey(PowerSupply option) {
    return '${option.name}|${option.type}|${option.inputVoltage}|${option.supportsBothInputs ? 1 : 0}|${option.wattage}|${option.price}';
  }

  PowerSupply _copyOption(PowerSupply option) {
    return PowerSupply(
      name: option.name,
      wattage: option.wattage,
      type: option.type,
      inputVoltage: option.inputVoltage,
      supportsBothInputs: option.supportsBothInputs,
      price: option.price,
    );
  }

  String? _resolveSelectedKey(PowerSupply item) {
    if (widget.availableOptions.isEmpty) return null;
    for (final option in widget.availableOptions) {
      if (option.name == item.name &&
          option.type == item.type &&
          option.inputVoltage == item.inputVoltage &&
          option.supportsBothInputs == item.supportsBothInputs &&
          option.wattage == item.wattage) {
        return _optionKey(option);
      }
    }
    return _optionKey(widget.availableOptions.first);
  }

  @override
  void initState() {
    super.initState();
    _items = _cloneList(widget.powerSupplies);
  }

  @override
  void didUpdateWidget(covariant PowerSupplyListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.powerSupplies != widget.powerSupplies) {
      _items = _cloneList(widget.powerSupplies);
    }
  }

  void _addItem() {
    if (widget.availableOptions.isEmpty) return;
    setState(() {
      _items.add(_copyOption(widget.availableOptions.first));
    });
    widget.onChanged(_cloneList(_items));
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    widget.onChanged(_cloneList(_items));
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
              onPressed: widget.availableOptions.isEmpty ? null : _addItem,
              tooltip: '新增電源項目',
            ),
          ],
        ),
        if (widget.availableOptions.isEmpty)
          Text(
            '尚無可用電源選項，請先由管理員建立電源供應器資料',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ..._items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final selectedKey = _resolveSelectedKey(item);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedKey,
                      decoration: const InputDecoration(labelText: '電源選項'),
                      isExpanded: true,
                      items: widget.availableOptions
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: _optionKey(option),
                              child: Text(
                                '${option.name} (${option.type} / ${option.inputVoltageLabel}V / ${option.wattage.toStringAsFixed(0)}W)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        final selected = widget.availableOptions.firstWhere(
                          (option) => _optionKey(option) == value,
                        );
                        setState(() {
                          _items[idx] = _copyOption(selected);
                        });
                        widget.onChanged(_cloneList(_items));
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '類型: ${item.type}    輸入: ${item.inputVoltageLabel}V    瓦數: ${item.wattage.toStringAsFixed(0)}W    價格: ${item.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
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
