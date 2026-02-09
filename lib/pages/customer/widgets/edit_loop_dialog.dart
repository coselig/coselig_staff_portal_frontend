import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote_models.dart';

class EditLoopDialog extends StatefulWidget {
  final Loop loop;
  final Function(Loop) onUpdateLoop;

  const EditLoopDialog({super.key, required this.loop, required this.onUpdateLoop});

  @override
  State<EditLoopDialog> createState() => _EditLoopDialogState();
}

class _EditLoopDialogState extends State<EditLoopDialog> {
  late TextEditingController nameController;
  late int selectedVoltage;
  late String selectedDimmingType;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.loop.name);
    selectedVoltage = widget.loop.voltage;
    selectedDimmingType = widget.loop.dimmingType;
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('編輯迴路'),
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
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: selectedVoltage,
              decoration: const InputDecoration(
                labelText: '電壓 (V)',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 220, child: Text('220V')),
                DropdownMenuItem(value: 110, child: Text('110V')),
                DropdownMenuItem(value: 36, child: Text('36V')),
                DropdownMenuItem(value: 24, child: Text('24V')),
                DropdownMenuItem(value: 12, child: Text('12V')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedVoltage = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedDimmingType,
              decoration: const InputDecoration(
                labelText: '調光類型',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'WRGB', child: Text('WRGB')),
                DropdownMenuItem(value: 'RGB', child: Text('RGB')),
                DropdownMenuItem(value: '雙色溫', child: Text('雙色溫')),
                DropdownMenuItem(value: '單色溫', child: Text('單色溫')),
                DropdownMenuItem(value: '繼電器', child: Text('繼電器')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedDimmingType = value!;
                });
              },
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
              if (name.isNotEmpty) {
                final updatedLoop = widget.loop.copyWith(
                  name: name,
                  voltage: selectedVoltage,
                  dimmingType: selectedDimmingType,
                );
                widget.onUpdateLoop(updatedLoop);
                Navigator.of(context).pop();
              }
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
}