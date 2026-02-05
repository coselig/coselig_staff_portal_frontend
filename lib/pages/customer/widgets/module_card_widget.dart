import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote_models.dart';

class ModuleCardWidget extends StatelessWidget {
  final int index;
  final Module module;
  final List<Loop> unassignedLoops;
  final Function(int) onRemoveModule;
  final Function(int, Loop) onAssignLoop;
  final Function(int, int) onRemoveLoop;
  final Function(int, int) onEditLoop;

  const ModuleCardWidget({
    super.key,
    required this.index,
    required this.module,
    required this.unassignedLoops,
    required this.onRemoveModule,
    required this.onAssignLoop,
    required this.onRemoveLoop,
    required this.onEditLoop,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${module.model} 模組',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => onRemoveModule(index),
                  icon: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  tooltip: '刪除此模組',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '通道: ${module.usedChannels}/${module.channelCount} (可用: ${module.availableChannels})',
              style: TextStyle(
                color: module.availableChannels > 0
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              module.isDimmable ? '可調光' : '繼電器控制',
              style: TextStyle(
                color: module.isDimmable
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 16),

            // 已分配的迴路
            if (module.loopAllocations.isNotEmpty) ...[
              const Text(
                '已分配迴路:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...module.loopAllocations.asMap().entries.map((entry) {
                final allocationIndex = entry.key;
                final allocation = entry.value;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '• ${allocation.loop.name} (${allocation.loop.voltage}V, ${allocation.loop.dimmingType})',
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () =>
                              onEditLoop(index, allocationIndex),
                          icon: Icon(
                            Icons.edit,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          iconSize: 20,
                          tooltip: '編輯此迴路',
                        ),
                        IconButton(
                          onPressed: () =>
                              onRemoveLoop(index, allocationIndex),
                          icon: Icon(
                            Icons.remove_circle,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          iconSize: 20,
                          tooltip: '移除此分配',
                        ),
                      ],
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
            ],

            // 添加迴路按鈕
            if (module.availableChannels > 0 && unassignedLoops.isNotEmpty) ...[
              const Text(
                '添加迴路:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: unassignedLoops
                    .where((loop) => module.canAssignLoop(loop, 1))
                    .map((loop) {
                      return ElevatedButton(
                        onPressed: () => onAssignLoop(index, loop),
                        child: Text(
                          '${loop.name} (${loop.voltage}V, ${loop.dimmingType})',
                        ),
                      );
                    })
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}