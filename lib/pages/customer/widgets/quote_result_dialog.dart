import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote_models.dart';

class QuoteResultDialog extends StatelessWidget {
  final List<Loop> loops;
  final List<Module> modules;
  final String switchCount;
  final String otherDevices;
  final String powerSupply;
  final String boardMaterials;
  final String wiring;

  const QuoteResultDialog({
    super.key,
    required this.loops,
    required this.modules,
    required this.switchCount,
    required this.otherDevices,
    required this.powerSupply,
    required this.boardMaterials,
    required this.wiring,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('估價摘要'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '設備配置：',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '開關：${switchCount.isNotEmpty ? '$switchCount個' : '未配置'}',
            ),
            if (otherDevices.isNotEmpty)
              Text('其他設備：$otherDevices'),
            const SizedBox(height: 16),
            const Text(
              '迴路配置：',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (loops.isEmpty)
              const Text('尚未配置任何迴路')
            else ...[
              Text('總共 ${loops.length} 個迴路：'),
              const SizedBox(height: 8),
              ...loops.map(
                (loop) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ${loop.name} (${loop.voltage}V, ${loop.dimmingType}, 總瓦數: ${loop.totalWatt}W)',
                    ),
                    if (loop.fixtures.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      ...loop.fixtures.map(
                        (fixture) => Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            '- ${fixture.name}: ${fixture.totalWatt}W${fixture.price > 0 ? ' (價格: \$${fixture.price.toStringAsFixed(1)})' : ''}',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              '模組配置：',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (modules.isEmpty)
              const Text('尚未配置任何模組')
            else ...[
              Text('總共 ${modules.length} 個模組：'),
              const SizedBox(height: 8),
              ...modules.map(
                (module) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ${module.model} (${module.channelCount}通道, ${module.isDimmable ? '可調光' : '繼電器控制'})',
                    ),
                    if (module.allocations.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      ...module.allocations.map(
                        (allocation) => Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            '- ${allocation.fixture.name}: ${allocation.allocatedCount}個',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (powerSupply.isNotEmpty)
              Text('電源：$powerSupply'),
            if (boardMaterials.isNotEmpty)
              Text('板材：$boardMaterials'),
            if (wiring.isNotEmpty)
              Text('線材：$wiring'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('確定'),
        ),
      ],
    );
  }
}