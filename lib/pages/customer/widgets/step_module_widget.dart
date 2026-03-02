import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote/quote_models.dart';
import 'module_card_widget.dart';

class StepModuleWidget extends StatefulWidget {
  final List<Module> modules;
  final VoidCallback onAddModule;
  final VoidCallback onAutoAssign;
  final Function(int) onRemoveModule;
  final Function(int, Loop) onAssignLoopToModule;
  final Function(int, int) onRemoveLoopFromModule;
  final Function(int, int) onEditLoopInModule;
  final List<Loop> unassignedLoops;

  const StepModuleWidget({
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
  State<StepModuleWidget> createState() => _StepModuleWidgetState();
}

class _StepModuleWidgetState extends State<StepModuleWidget> {
  late bool _modulesExpanded;

  @override
  void initState() {
    super.initState();
    _modulesExpanded = widget.modules.length <= 3;
  }

  @override
  void didUpdateWidget(covariant StepModuleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.modules.length != widget.modules.length) {
      setState(() {
        _modulesExpanded = widget.modules.length <= 3;
      });
    }
  }

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
        InkWell(
          onTap: () => setState(() => _modulesExpanded = !_modulesExpanded),
          child: Row(
            children: [
              Icon(
                _modulesExpanded ? Icons.expand_less : Icons.expand_more,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '已配置模組 (${widget.modules.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: widget.onAutoAssign,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('自動分配'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: widget.onAddModule,
                icon: const Icon(Icons.add),
                label: const Text('添加模組'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_modulesExpanded) ...[
          if (widget.modules.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  '尚未添加任何模組\n點擊上方按鈕添加第一個模組',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            )
          else
            ...widget.modules.asMap().entries.map((entry) {
              final index = entry.key;
              final module = entry.value;
              return ModuleCardWidget(
                index: index,
                module: module,
                unassignedLoops: widget.unassignedLoops,
                onRemoveModule: widget.onRemoveModule,
                onAssignLoop: widget.onAssignLoopToModule,
                onRemoveLoop: widget.onRemoveLoopFromModule,
                onEditLoop: widget.onEditLoopInModule,
              );
            }),
        ],
        if (widget.modules.isNotEmpty) ...[
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
                  '模組總價: \$${widget.modules.fold<double>(0, (sum, m) => sum + m.price).toStringAsFixed(0)}',
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