import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/utils/icon_utils.dart';

class AddLoopDialog extends StatefulWidget {
  final Function(String name, String space) onAddLoop;
  final List<String> spaces;

  const AddLoopDialog({
    super.key,
    required this.onAddLoop,
    required this.spaces,
  });

  @override
  State<AddLoopDialog> createState() => _AddLoopDialogState();
}

class _AddLoopDialogState extends State<AddLoopDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController newSpaceController = TextEditingController();
  String? _selectedSpace;
  bool _isCreatingNewSpace = false;

  @override
  void initState() {
    super.initState();
    if (widget.spaces.isNotEmpty) {
      _selectedSpace = widget.spaces.first;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    newSpaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加新迴路'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 空間選擇
          if (!_isCreatingNewSpace) ...[
            DropdownButtonFormField<String>(
              value: _selectedSpace,
              decoration: const InputDecoration(
                labelText: '所屬空間',
                border: OutlineInputBorder(),
              ),
              items: widget.spaces.map((space) {
                return DropdownMenuItem(value: space, child: Text(space));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedSpace = value);
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() => _isCreatingNewSpace = true);
                },
                icon: Icon(Icons.add, size: context.scaledIconSize(16)),
                label: const Text('新增空間'),
              ),
            ),
          ] else ...[
            TextField(
              controller: newSpaceController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '新空間名稱',
                border: OutlineInputBorder(),
                hintText: '例如：客廳、臥室、廚房',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() => _isCreatingNewSpace = false);
                },
                icon: Icon(Icons.arrow_back, size: context.scaledIconSize(16)),
                label: const Text('選擇既有空間'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '迴路名稱',
              border: OutlineInputBorder(),
              hintText: '例如：主燈、崁燈、燈帶',
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
            if (name.isEmpty) return;

            String space;
            if (_isCreatingNewSpace) {
              space = newSpaceController.text.trim();
              if (space.isEmpty) return;
            } else {
              space = _selectedSpace ?? '未分類';
            }

            widget.onAddLoop(name, space);
            Navigator.of(context).pop();
          },
          child: const Text('確定'),
        ),
      ],
    );
  }
}