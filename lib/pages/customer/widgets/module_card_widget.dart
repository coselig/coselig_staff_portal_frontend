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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${module.brand.isNotEmpty ? '[${module.brand}] ' : ''}${module.model} 模組',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
              '總最大安培: ${module.totalMaxAmpere.toStringAsFixed(2)}A',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
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
            const SizedBox(height: 8),

            // 顯示每個通道的安培信息
            if (module.channelMaxAmperes.any((ampere) => ampere > 0)) ...[
              const Text(
                '各通道最大安培:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: module.channelMaxAmperes.asMap().entries.map((entry) {
                  final channelIndex = entry.key;
                  final ampere = entry.value;
                  final ratio = module.maxAmperePerChannel > 0
                      ? ampere / module.maxAmperePerChannel
                      : 0.0;
                  final isWarning = ratio > 0.8 && ratio <= 1.0;
                  final isOver = ratio > 1.0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOver
                          ? Theme.of(context).colorScheme.errorContainer
                          : isWarning
                          ? Colors.orange.shade100
                          : ampere > 0
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'CH${channelIndex + 1}: ${ampere.toStringAsFixed(2)}/${module.maxAmperePerChannel.toStringAsFixed(1)}A',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOver
                            ? Theme.of(context).colorScheme.onErrorContainer
                            : isWarning
                            ? Colors.orange.shade800
                            : ampere > 0
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

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
                      final ampereCheck = module.checkLoopAmpereLimit(loop, 1);
                      final isBlocked =
                          ampereCheck == AmpereCheckResult.blocked;
                      final showWarning =
                          ampereCheck == AmpereCheckResult.warning;

                      return ElevatedButton(
                        onPressed: isBlocked ? null : () => onAssignLoop(index, loop),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isBlocked
                              ? Colors.red.shade100
                              : showWarning
                                  ? Colors.orange.shade100
                                  : null,
                          foregroundColor: isBlocked
                              ? Colors.red.shade800
                              : showWarning
                                  ? Colors.orange.shade800
                                  : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${loop.name} (${loop.voltage}V, ${loop.dimmingType})',
                            ),
                            if (showWarning) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.warning, size: 16, color: Colors.orange.shade800),
                            ],
                            if (isBlocked) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.block, size: 16, color: Colors.red.shade800),
                            ],
                          ],
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