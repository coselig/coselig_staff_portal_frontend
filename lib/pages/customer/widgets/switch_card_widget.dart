import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote/quote_models.dart';

class SwitchCardWidget extends StatefulWidget {
  final int index;
  final SwitchModel switchModel;
  final Function(int, SwitchModel) onUpdateSwitch;
  final Function(int) onRemoveSwitch;
  final List<String> spaces;

  const SwitchCardWidget({
    super.key,
    required this.index,
    required this.switchModel,
    required this.onUpdateSwitch,
    required this.onRemoveSwitch,
    required this.spaces,
  });

  @override
  State<SwitchCardWidget> createState() => _SwitchCardWidgetState();
}

class _SwitchCardWidgetState extends State<SwitchCardWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // 標題列：點擊展開/收合
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.switchModel.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (!_isExpanded) ...[
                    Text(
                      'x${widget.switchModel.count} · ${widget.switchModel.fireType}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditSwitchDialog(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => widget.onRemoveSwitch(widget.index),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('數量：${widget.switchModel.count}'),
                  if (widget.switchModel.price > 0)
                    Text('價格：${widget.switchModel.price}'),
                  Text('單火/零火：${widget.switchModel.fireType}'),
                  Text('是否可以聯網：${widget.switchModel.networkable ? '是' : '否'}'),
                  Text('協定類型：${widget.switchModel.protocol}'),
                  Text('顏色：${widget.switchModel.color}'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showEditSwitchDialog(BuildContext context) {
    final nameController = TextEditingController(text: widget.switchModel.name);
    final countController = TextEditingController(
      text: widget.switchModel.count.toString(),
    );
    final priceController = TextEditingController(
      text: widget.switchModel.price.toString(),
    );
    String fireType = widget.switchModel.fireType.isNotEmpty
        ? widget.switchModel.fireType
        : '單火';
    String networkable = widget.switchModel.networkable ? '是' : '否';
    String protocol = widget.switchModel.protocol.isNotEmpty
        ? widget.switchModel.protocol
        : 'MQTT';
    String space = widget.switchModel.space;
    final colorController = TextEditingController(
      text: widget.switchModel.color,
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('編輯開關'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: space,
                  decoration: const InputDecoration(labelText: '所屬空間'),
                  items: widget.spaces
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => space = v ?? '未分類'),
                ),
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
                  initialValue: fireType,
                  decoration: const InputDecoration(labelText: '單火/零火'),
                  items: ['單火', '零火']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => fireType = v ?? '單火'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: networkable,
                  decoration: const InputDecoration(labelText: '是否可以聯網'),
                  items: ['是', '否']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => networkable = v ?? '否'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: protocol,
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
                final updated = widget.switchModel.copyWith(
                  name: nameController.text,
                  count:
                      int.tryParse(countController.text) ??
                      widget.switchModel.count,
                  price:
                      double.tryParse(priceController.text) ??
                      widget.switchModel.price,
                  fireType: fireType,
                  networkable: networkable == '是',
                  protocol: protocol,
                  color: colorController.text,
                  space: space,
                );
                widget.onUpdateSwitch(widget.index, updated);
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
