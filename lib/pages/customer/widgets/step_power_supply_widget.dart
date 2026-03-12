import 'package:coselig_staff_portal/models/quote/power_supply.dart';
import 'package:coselig_staff_portal/pages/customer/widgets/power_supply_list_widget.dart';
import 'package:flutter/material.dart';

class StepPowerSupplyWidget extends StatefulWidget {
  final List<PowerSupply> powerSupplies;
  final List<PowerSupply> availableOptions;
  final int moduleCount;
  final ValueChanged<List<PowerSupply>> onChanged;
  final VoidCallback onAutoAssign;

  const StepPowerSupplyWidget({
    super.key,
    required this.powerSupplies,
    required this.availableOptions,
    required this.moduleCount,
    required this.onChanged,
    required this.onAutoAssign,
  });

  @override
  State<StepPowerSupplyWidget> createState() => _StepPowerSupplyWidgetState();
}

class _StepPowerSupplyWidgetState extends State<StepPowerSupplyWidget> {
  late bool _powerSuppliesExpanded;

  @override
  void initState() {
    super.initState();
    _powerSuppliesExpanded = widget.powerSupplies.length <= 3;
  }

  @override
  void didUpdateWidget(covariant StepPowerSupplyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.powerSupplies.length != widget.powerSupplies.length) {
      setState(() {
        _powerSuppliesExpanded = widget.powerSupplies.length <= 3;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '電源供應配置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () {
            setState(() {
              _powerSuppliesExpanded = !_powerSuppliesExpanded;
            });
          },
          child: Row(
            children: [
              Icon(
                _powerSuppliesExpanded ? Icons.expand_less : Icons.expand_more,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '已配置電源供應器 (${widget.powerSupplies.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed:
                    widget.moduleCount > 0 && widget.availableOptions.isNotEmpty
                    ? widget.onAutoAssign
                    : null,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('自動分配'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_powerSuppliesExpanded)
          PowerSupplyListWidget(
            powerSupplies: widget.powerSupplies,
            availableOptions: widget.availableOptions,
            onChanged: widget.onChanged,
          ),
        if (widget.moduleCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '目前共有 ${widget.moduleCount} 個模組，自動分配會嘗試一模組對應一個電源。',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        if (widget.powerSupplies.isNotEmpty) ...[
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
                  '電源供應器總價: \$${widget.powerSupplies.fold<double>(0, (sum, item) => sum + item.price).toStringAsFixed(0)}',
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
