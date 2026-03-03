import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote/quote_models.dart';

class AddSwitchDialog extends StatelessWidget {
  final Function(SwitchModel) onSelectSwitch;
  final List<SwitchModel> switchOptions;
  final int loopCount;
  final List<String> spaces;

  const AddSwitchDialog({
    super.key,
    required this.onSelectSwitch,
    required this.switchOptions,
    required this.loopCount,
    required this.spaces,
  });

  @override
  Widget build(BuildContext context) {
    SwitchModel? selectedSwitch;
    String selectedSpace = spaces.isNotEmpty ? spaces.first : '未分類';

    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('選擇開關'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedSpace,
              decoration: const InputDecoration(labelText: '所屬空間'),
              items: spaces
                  .map(
                    (space) =>
                        DropdownMenuItem(value: space, child: Text(space)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => selectedSpace = value ?? '未分類');
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SwitchModel>(
              decoration: const InputDecoration(labelText: '選擇一個開關'),
              items: switchOptions
                  .map(
                    (switchModel) => DropdownMenuItem(
                      value: switchModel,
                      child: Text(switchModel.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => selectedSwitch = value);
              },
            ),
            if (selectedSwitch != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  '配置開關數 / 迴路數量: ${selectedSwitch!.count} / $loopCount',
                  style: const TextStyle(fontSize: 14),
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
            onPressed: selectedSwitch != null
                ? () {
                    onSelectSwitch(
                      selectedSwitch!.copyWith(space: selectedSpace),
                    );
                    Navigator.of(context).pop();
                  }
                : null,
            child: const Text('選擇'),
          ),
        ],
      ),
    );
  }
}
