import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote_models.dart';
import 'module_card_widget.dart';

class Step2Widget extends StatelessWidget {
  final List<Module> modules;
  final VoidCallback onAddModule;
  final Function(int) onRemoveModule;
  final Function(int, Loop) onAssignLoopToModule;
  final Function(int, int) onRemoveLoopFromModule;
  final Function(int, int) onEditLoopInModule;
  final List<Loop> unassignedLoops;

  const Step2Widget({
    super.key,
    required this.modules,
    required this.onAddModule,
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
                      ElevatedButton.icon(
                        onPressed: onAddModule,
                        icon: const Icon(Icons.add),
                        label: const Text('添加模組'),
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
                      ElevatedButton.icon(
                        onPressed: onAddModule,
                        icon: const Icon(Icons.add),
                        label: const Text('添加模組'),
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
      ],
    );
  }
}