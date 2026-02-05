import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote_models.dart';

class LoopCardWidget extends StatelessWidget {
  final int index;
  final Loop loop;
  final Function(int, Loop) onUpdateLoop;
  final Function(int) onRemoveLoop;
  final Function(int) onAddFixture;
  final Function(int, int) onRemoveFixture;

  const LoopCardWidget({
    super.key,
    required this.index,
    required this.loop,
    required this.onUpdateLoop,
    required this.onRemoveLoop,
    required this.onAddFixture,
    required this.onRemoveFixture,
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
            // 迴路標題和刪除按鈕
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loop.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => onRemoveLoop(index),
                  icon: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  tooltip: '刪除迴路',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 迴路設定
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: loop.voltage,
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
                      if (value != null) {
                        onUpdateLoop(index, loop.copyWith(voltage: value));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: loop.dimmingType,
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
                      if (value != null) {
                        onUpdateLoop(index, loop.copyWith(dimmingType: value));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 總瓦數顯示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '總瓦數:',
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${loop.totalWatt} W',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 燈具列表
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '燈具 (${loop.fixtures.length} 個)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => onAddFixture(index),
                  icon: const Icon(Icons.add),
                  label: const Text('添加燈具'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (loop.fixtures.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '尚未添加燈具',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              )
            else
              ...loop.fixtures.asMap().entries.map((entry) {
                final fixtureIndex = entry.key;
                final fixture = entry.value;
                return Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fixture.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${fixture.totalWatt} W',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              onRemoveFixture(index, fixtureIndex),
                          icon: Icon(
                            Icons.remove_circle,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          iconSize: 20,
                          tooltip: '移除燈具',
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}