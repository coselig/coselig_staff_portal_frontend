import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote/quote_models.dart';
import 'loop_card_widget.dart';
import 'switch_card_widget.dart';

class StepLoopSwitchWidget extends StatefulWidget {
  final List<Loop> loops;
  final List<SwitchModel> switches;
  final TextEditingController switchCountController;
  final List<OtherDevice> otherDevices;
  final VoidCallback onAddLoop;
  final VoidCallback onAddSwitch;
  final Function(int) onRemoveLoop;
  final Function(int, Loop) onUpdateLoop;
  final Function(int) onAddFixtureToLoop;
  final Function(int, int) onRemoveFixtureFromLoop;
  final Function(int, int) onEditFixtureInLoop;
  final Function(int, SwitchModel) onUpdateSwitch;
  final Function(int) onRemoveSwitch;
  final VoidCallback onAddOtherDevice;
  final Function(int) onRemoveOtherDevice;
  final Function(int, {String? name, double? price}) onUpdateOtherDevice;

  const StepLoopSwitchWidget({
    super.key,
    required this.loops,
    required this.switches,
    required this.switchCountController,
    required this.otherDevices,
    required this.onAddLoop,
    required this.onAddSwitch,
    required this.onRemoveLoop,
    required this.onUpdateLoop,
    required this.onAddFixtureToLoop,
    required this.onRemoveFixtureFromLoop,
    required this.onEditFixtureInLoop,
    required this.onUpdateSwitch,
    required this.onRemoveSwitch,
    required this.onAddOtherDevice,
    required this.onRemoveOtherDevice,
    required this.onUpdateOtherDevice,
  });

  @override
  State<StepLoopSwitchWidget> createState() => _StepLoopSwitchWidgetState();
}

class _StepLoopSwitchWidgetState extends State<StepLoopSwitchWidget> {
  late bool _loopsExpanded;
  late bool _switchesExpanded;
  late bool _otherDevicesExpanded;

  @override
  void initState() {
    super.initState();
    _loopsExpanded = widget.loops.length <= 3;
    _switchesExpanded = widget.switches.length <= 3;
    _otherDevicesExpanded = widget.otherDevices.length <= 3;
  }

  @override
  void didUpdateWidget(covariant StepLoopSwitchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loops.length != widget.loops.length) {
      setState(() => _loopsExpanded = widget.loops.length <= 3);
    }
    if (oldWidget.switches.length != widget.switches.length) {
      setState(() => _switchesExpanded = widget.switches.length <= 3);
    }
    if (oldWidget.otherDevices.length != widget.otherDevices.length) {
      setState(() => _otherDevicesExpanded = widget.otherDevices.length <= 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== 已配置迴路區塊 =====
        InkWell(
          onTap: () => setState(() => _loopsExpanded = !_loopsExpanded),
          child: Row(
            children: [
              Icon(
                _loopsExpanded ? Icons.expand_less : Icons.expand_more,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '已配置迴路 (${widget.loops.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: widget.onAddLoop,
                icon: const Icon(Icons.add),
                label: const Text('添加迴路'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        if (_loopsExpanded) ...[
          if (widget.loops.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  '尚未添加任何迴路\n點擊上方按鈕添加第一個迴路',
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
            ...widget.loops.asMap().entries.map((entry) {
              final index = entry.key;
              final loop = entry.value;
              return LoopCardWidget(
                index: index,
                loop: loop,
                onUpdateLoop: widget.onUpdateLoop,
                onRemoveLoop: widget.onRemoveLoop,
                onAddFixture: widget.onAddFixtureToLoop,
                onRemoveFixture: widget.onRemoveFixtureFromLoop,
                onEditFixture: widget.onEditFixtureInLoop,
              );
            }),
        ],

        const SizedBox(height: 24),

        // ===== 開關配置區塊 =====
        InkWell(
          onTap: () => setState(() => _switchesExpanded = !_switchesExpanded),
          child: Row(
            children: [
              Icon(
                _switchesExpanded ? Icons.expand_less : Icons.expand_more,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '開關配置 (${widget.switches.fold<int>(0, (sum, s) => sum + s.count)} / ${widget.loops.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: widget.onAddSwitch,
                icon: const Icon(Icons.add),
                label: const Text('新增開關'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        if (_switchesExpanded) ...[
          if (widget.switches.isEmpty)
            Text(
              '尚未添加任何開關',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            )
          else
            ...widget.switches.asMap().entries.map((entry) {
              final index = entry.key;
              final switchModel = entry.value;
              return SwitchCardWidget(
                index: index,
                switchModel: switchModel,
                onUpdateSwitch: widget.onUpdateSwitch,
                onRemoveSwitch: widget.onRemoveSwitch,
              );
            }),
        ],

        const SizedBox(height: 24),

        // ===== 其他設備區塊 =====
        InkWell(
          onTap: () =>
              setState(() => _otherDevicesExpanded = !_otherDevicesExpanded),
          child: Row(
            children: [
              Icon(
                _otherDevicesExpanded ? Icons.expand_less : Icons.expand_more,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '其他設備 (${widget.otherDevices.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: widget.onAddOtherDevice,
                icon: const Icon(Icons.add),
                label: const Text('新增其他設備'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        if (_otherDevicesExpanded) ...[
          ...widget.otherDevices.asMap().entries.map((entry) {
            final idx = entry.key;
            final device = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: device.name,
                      decoration: const InputDecoration(
                        labelText: '設備名稱',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) =>
                          widget.onUpdateOtherDevice(idx, name: val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: device.price == 0
                          ? ''
                          : device.price.toString(),
                      decoration: const InputDecoration(
                        labelText: '價格',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val) ?? 0;
                        widget.onUpdateOtherDevice(idx, price: parsed);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => widget.onRemoveOtherDevice(idx),
                    tooltip: '刪除',
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}