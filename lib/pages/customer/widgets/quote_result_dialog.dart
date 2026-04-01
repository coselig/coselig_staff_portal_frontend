import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote/quote_models.dart';

class QuoteResultDialog extends StatelessWidget {
  final List<Loop> loops;
  final List<Module> modules;
  final String switchCount;
  final List<OtherDevice> otherDevices;
  final List<PowerSupply> powerSupplies;
  final List<MaterialItem> boardMaterials;
  final List<MaterialItem> wiring;

  // 樣態選項
  final bool ceilingHasLn;
  final bool ceilingHasMaintenanceHole;
  final bool switchHasLn;
  final List<Widget>? actions;

  const QuoteResultDialog({
    super.key,
    required this.loops,
    required this.modules,
    required this.switchCount,
    required this.otherDevices,
    required this.powerSupplies,
    required this.boardMaterials,
    required this.wiring,
    required this.ceilingHasLn,
    required this.ceilingHasMaintenanceHole,
    required this.switchHasLn,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    // 計算各項總價
    final totalFixturePrice = loops.fold(
      0.0,
      (sum, loop) => sum + loop.totalFixturePrice,
    );
    final totalModulePrice = modules.fold(
      0.0,
      (sum, module) => sum + module.price,
    );
    final totalPowerSupplyPrice = powerSupplies.fold(
      0.0,
      (sum, ps) => sum + ps.price,
    );
    final totalOtherDevicePrice = otherDevices.fold(
      0.0,
      (sum, d) => sum + d.price,
    );
    final totalBoardMaterialPrice = boardMaterials.fold(
      0.0,
      (sum, m) => sum + m.price,
    );
    final totalWiringPrice = wiring.fold(0.0, (sum, m) => sum + m.price);
    final grandTotal =
        totalFixturePrice +
        totalModulePrice +
        totalPowerSupplyPrice +
        totalOtherDevicePrice +
        totalBoardMaterialPrice +
        totalWiringPrice;

    return AlertDialog(
      title: const Text('估價摘要'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 總價摘要卡片
            if (grandTotal > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '價格總覽',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (totalFixturePrice > 0)
                      _buildPriceRow(
                        context,
                        '燈具總價',
                        totalFixturePrice,
                        Theme.of(context).colorScheme.secondary,
                      ),
                    if (totalModulePrice > 0)
                      _buildPriceRow(
                        context,
                        '模組總價',
                        totalModulePrice,
                        Theme.of(context).colorScheme.tertiary,
                      ),
                    if (totalPowerSupplyPrice > 0)
                      _buildPriceRow(
                        context,
                        '電源總價',
                        totalPowerSupplyPrice,
                        Theme.of(context).colorScheme.primary,
                      ),
                    if (totalOtherDevicePrice > 0)
                      _buildPriceRow(
                        context,
                        '其他設備總價',
                        totalOtherDevicePrice,
                        Theme.of(context).colorScheme.primary,
                      ),
                    if (totalBoardMaterialPrice > 0)
                      _buildPriceRow(
                        context,
                        '板材/配電箱總價',
                        totalBoardMaterialPrice,
                        Theme.of(context).colorScheme.primary,
                      ),
                    if (totalWiringPrice > 0)
                      _buildPriceRow(
                        context,
                        '線材總價',
                        totalWiringPrice,
                        Theme.of(context).colorScheme.primary,
                      ),
                    Divider(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer.withValues(alpha: 0.3),
                    ),
                    _buildPriceRow(
                      context,
                      '合計',
                      grandTotal,
                      Theme.of(context).colorScheme.primary,
                      isBold: true,
                    ),
                  ],
                ),
              ),

            // 樣態選項摘要
            const Text('樣態選擇：', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('天花版有LN：${ceilingHasLn ? '是' : '否'}'),
            Text('天花版有維修孔：${ceilingHasMaintenanceHole ? '是' : '否'}'),
            Text('開關有LN：${switchHasLn ? '是' : '否'}'),
            const SizedBox(height: 16),
            const Text(
              '設備配置：',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '開關：${switchCount.isNotEmpty ? '$switchCount個' : '未配置'}',
            ),
            if (otherDevices.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('其他設備：'),
                  ...otherDevices.map(
                    (d) => Text('• ${d.name}：${d.price.toStringAsFixed(0)} 元'),
                  ),
                ],
              ),
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
                      '• ${loop.name} (${loop.voltage}V, ${loop.dimmingType}, 總瓦數: ${loop.totalWatt}W${loop.totalFixturePrice > 0 ? ', 燈具價: \$${loop.totalFixturePrice.toStringAsFixed(1)}' : ''})',
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
                      '• ${module.model} (${module.channelCount}通道, ${module.isDimmable ? '可調光' : '繼電器控制'}${module.price > 0 ? ', \$${module.price.toStringAsFixed(1)}' : ''})',
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
            if (powerSupplies.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('電源：'),
                  ...powerSupplies.map(
                    (ps) => Text('- ${ps.name}：${ps.price}元'),
                  ),
                ],
              ),
            if (boardMaterials.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('板材、配電箱：'),
                  ...boardMaterials.map(
                    (m) => Text('- ${m.name}：${m.price.toStringAsFixed(0)} 元'),
                  ),
                ],
              ),
            if (wiring.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('線材：'),
                  ...wiring.map(
                    (m) => Text('- ${m.name}：${m.price.toStringAsFixed(0)} 元'),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions:
          actions ??
          [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('確定'),
            ),
          ],
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    String label,
    double price,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            '\$${price.toStringAsFixed(1)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isBold ? 18 : 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
