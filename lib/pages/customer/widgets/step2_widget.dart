import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote_models.dart';
import 'module_card_widget.dart';

class Step2Widget extends StatelessWidget {
  final List<Module> modules;
  final VoidCallback onAddModule;
  final VoidCallback onAutoAssign;
  final Function(int) onRemoveModule;
  final Function(int, Loop) onAssignLoopToModule;
  final Function(int, int) onRemoveLoopFromModule;
  final Function(int, int) onEditLoopInModule;
  final List<Loop> unassignedLoops;

  const Step2Widget({
    super.key,
    required this.modules,
    required this.onAddModule,
    required this.onAutoAssign,
    required this.onRemoveModule,
    required this.onAssignLoopToModule,
    required this.onRemoveLoopFromModule,
    required this.onEditLoopInModule,
    required this.unassignedLoops,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '模組配置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;
            return isSmallScreen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '已配置模組',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: onAddModule,
                            icon: const Icon(Icons.add),
                            label: const Text('添加模組'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onAutoAssign,
                            icon: const Icon(Icons.auto_fix_high),
                            label: const Text('自動分配'),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '已配置模組',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: onAutoAssign,
                            icon: const Icon(Icons.auto_fix_high),
                            label: const Text('自動分配'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: onAddModule,
                            icon: const Icon(Icons.add),
                            label: const Text('添加模組'),
                          ),
                        ],
                      ),
                    ],
                  );
          },
        ),
        const SizedBox(height: 16),
        if (modules.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                '尚未添加任何模組\n點擊上方按鈕添加第一個模組',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          )
        else
          ...modules.asMap().entries.map((entry) {
            final index = entry.key;
            final module = entry.value;
            return ModuleCardWidget(
              index: index,
              module: module,
              unassignedLoops: unassignedLoops,
              onRemoveModule: onRemoveModule,
              onAssignLoop: onAssignLoopToModule,
              onRemoveLoop: onRemoveLoopFromModule,
              onEditLoop: onEditLoopInModule,
            );
          }),
        if (modules.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.attach_money,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '模組總價: \$${modules.fold<double>(0, (sum, m) => sum + m.price).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}