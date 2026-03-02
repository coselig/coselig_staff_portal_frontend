import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote/quote_models.dart';

class LoopCardWidget extends StatefulWidget {
  final int index;
  final Loop loop;
  final Function(int, Loop) onUpdateLoop;
  final Function(int) onRemoveLoop;
  final Function(int) onAddFixture;
  final Function(int, int) onRemoveFixture;
  final Function(int, int) onEditFixture;

  const LoopCardWidget({
    super.key,
    required this.index,
    required this.loop,
    required this.onUpdateLoop,
    required this.onRemoveLoop,
    required this.onAddFixture,
    required this.onRemoveFixture,
    required this.onEditFixture,
  });

  @override
  State<LoopCardWidget> createState() => _LoopCardWidgetState();
}

class _LoopCardWidgetState extends State<LoopCardWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // 標題列：點擊展開/收合
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.loop.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // 收合時顯示簡要資訊
                  if (!_isExpanded) ...[
                    Text(
                      '${widget.loop.voltage}V · ${widget.loop.dimmingType} · ${widget.loop.totalWatt}W · ${widget.loop.fixtures.length}燈具',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    onPressed: () => widget.onRemoveLoop(widget.index),
                    icon: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    tooltip: '刪除迴路',
                  ),
                ],
              ),
            ),
          ),
          // 展開的詳細內容
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildExpandedContent(context),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    final loop = widget.loop;
    final index = widget.index;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 迴路設定
        Row(
          children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: loop.voltage,
                    decoration: const InputDecoration(
                      labelText: '電壓 (V)',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 220, child: Text('220V')),
                      DropdownMenuItem(value: 110, child: Text('110V')),
                      DropdownMenuItem(value: 36, child: Text('36V')),
                      DropdownMenuItem(value: 24, child: Text('24V')),
                      DropdownMenuItem(value: 12, child: Text('12V')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                    widget.onUpdateLoop(index, loop.copyWith(voltage: value));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: loop.dimmingType,
                    decoration: const InputDecoration(
                      labelText: '調光類型',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'WRGB', child: Text('WRGB')),
                      DropdownMenuItem(value: 'RGB', child: Text('RGB')),
                      DropdownMenuItem(value: '雙色溫', child: Text('雙色溫')),
                      DropdownMenuItem(value: '單色溫', child: Text('單色溫')),
                      DropdownMenuItem(value: '繼電器', child: Text('繼電器')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                    widget.onUpdateLoop(
                      index,
                      loop.copyWith(dimmingType: value),
                    );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 總瓦數和價格顯示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '總瓦數:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${loop.totalWatt} W',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (loop.totalFixturePrice > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '燈具總價:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '\$${loop.totalFixturePrice.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 燈具列表
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '燈具 (${loop.fixtures.length} 個)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ElevatedButton.icon(
              onPressed: () => widget.onAddFixture(index),
                  icon: const Icon(Icons.add),
                  label: const Text('添加燈具'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (loop.fixtures.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '尚未添加燈具',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              )
            else
              ...loop.fixtures.asMap().entries.map((entry) {
                final fixtureIndex = entry.key;
                final fixture = entry.value;
                final ampere = loop.voltage > 0
                    ? (fixture.totalWatt / loop.voltage)
                    : 0.0;
                return Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fixture.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.bolt,
                                        size: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${fixture.totalWatt} W',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.electrical_services,
                                        size: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.tertiary,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${ampere.toStringAsFixed(2)} A',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.tertiary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (fixture.price > 0)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.attach_money,
                                          size: 14,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '\$${fixture.price.toStringAsFixed(1)}',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () =>
                              widget.onEditFixture(index, fixtureIndex),
                              icon: const Icon(Icons.edit, size: 20),
                              color: Theme.of(context).colorScheme.primary,
                              tooltip: '修改燈具',
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            IconButton(
                              onPressed: () =>
                              widget.onRemoveFixture(index, fixtureIndex),
                              icon: const Icon(Icons.remove_circle,
                                size: 22),
                              color: Theme.of(context).colorScheme.error,
                              tooltip: '移除燈具',
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
      ],
    );
  }
}