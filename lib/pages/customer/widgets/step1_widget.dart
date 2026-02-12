import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coselig_staff_portal/models/quote_models.dart';
import 'loop_card_widget.dart';

class Step1Widget extends StatelessWidget {
  final List<Loop> loops;
  final TextEditingController switchCountController;
  final TextEditingController otherDevicesController;
  final VoidCallback onAddLoop;
  final Function(int) onRemoveLoop;
  final Function(int, Loop) onUpdateLoop;
  final Function(int) onAddFixtureToLoop;
  final Function(int, int) onRemoveFixtureFromLoop;

  const Step1Widget({
    super.key,
    required this.loops,
    required this.switchCountController,
    required this.otherDevicesController,
    required this.onAddLoop,
    required this.onRemoveLoop,
    required this.onUpdateLoop,
    required this.onAddFixtureToLoop,
    required this.onRemoveFixtureFromLoop,
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
            );
          }),

        const SizedBox(height: 24),
        const Text(
          '開關配置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: switchCountController,
          decoration: const InputDecoration(
            labelText: '開關數量',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 24),
        const Text(
          '其他設備',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: otherDevicesController,
          decoration: const InputDecoration(
            labelText: '其他感應器、設備 (例如：冷氣、窗簾等)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}