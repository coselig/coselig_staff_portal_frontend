import 'package:flutter/material.dart';

class AddLoopDialog extends StatefulWidget {
  final Function(String) onAddLoop;

  const AddLoopDialog({super.key, required this.onAddLoop});

  @override
  State<AddLoopDialog> createState() => _AddLoopDialogState();
}

class _AddLoopDialogState extends State<AddLoopDialog> {
  final TextEditingController nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加新迴路'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '迴路名稱',
              border: OutlineInputBorder(),
              hintText: '例如：客廳主燈、廚房燈具',
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
            if (nameController.text.trim().isNotEmpty) {
              widget.onAddLoop(nameController.text.trim());
              Navigator.of(context).pop();
            }
          },
          child: const Text('確定'),
        ),
      ],
    );
  }
}