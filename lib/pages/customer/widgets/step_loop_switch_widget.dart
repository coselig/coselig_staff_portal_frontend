import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote/quote_models.dart';
import 'loop_card_widget.dart';
import 'switch_card_widget.dart';

class StepLoopSwitchWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '迴路配置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 添加迴路按鈕
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;
            return isSmallScreen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '已配置迴路',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: onAddLoop,
                        icon: const Icon(Icons.add),
                        label: const Text('添加迴路'),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Text(
                        '已配置迴路',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: onAddLoop,
                        icon: const Icon(Icons.add),
                        label: const Text('添加迴路'),
                      ),
                    ],
                  );
          },
        ),
        const SizedBox(height: 16),

        // 迴路列表
        if (loops.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                '尚未添加任何迴路\n點擊上方按鈕添加第一個迴路',
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
          ...loops.asMap().entries.map((entry) {
            final index = entry.key;
            final loop = entry.value;
            return LoopCardWidget(
              index: index,
              loop: loop,
              onUpdateLoop: onUpdateLoop,
              onRemoveLoop: onRemoveLoop,
              onAddFixture: onAddFixtureToLoop,
              onRemoveFixture: onRemoveFixtureFromLoop,
              onEditFixture: onEditFixtureInLoop,
            );
          }),

        const SizedBox(height: 24),
        const Text(
          '開關配置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: onAddSwitch,
              icon: const Icon(Icons.add),
              label: const Text('新增開關'),
            ),
            const SizedBox(width: 16),
            Text(
              '配置開關數 / 迴路數量: ${switches.fold<int>(0, (sum, s) => sum + s.count)} / ${loops.length}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (switches.isEmpty)
          Text(
            '尚未添加任何開關',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          )
        else
          ...switches.asMap().entries.map((entry) {
            final index = entry.key;
            final switchModel = entry.value;
            return SwitchCardWidget(
              index: index,
              switchModel: switchModel,
              onUpdateSwitch: onUpdateSwitch,
              onRemoveSwitch: onRemoveSwitch,
            );
          }),
        const SizedBox(height: 24),
        const Text(
          '其他設備',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...otherDevices.asMap().entries.map((entry) {
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
                    onChanged: (val) => onUpdateOtherDevice(idx, name: val),
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
                      onUpdateOtherDevice(idx, price: parsed);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onRemoveOtherDevice(idx),
                  tooltip: '刪除',
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onAddOtherDevice,
          icon: const Icon(Icons.add),
          label: const Text('新增其他設備'),
        ),
      ],
    );
  }
}