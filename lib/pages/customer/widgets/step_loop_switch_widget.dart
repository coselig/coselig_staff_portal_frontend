import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote/quote_models.dart';
import 'loop_card_widget.dart';
import 'switch_card_widget.dart';

class StepLoopSwitchWidget extends StatefulWidget {
  final List<Loop> loops;
  final List<SwitchModel> switches;
  final TextEditingController switchCountController;
  final List<OtherDevice> otherDevices;
  final List<String> spaces;
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
  final Function(String) onAddSpace;
  final Function(String) onRemoveSpace;
  final Function(String, String) onRenameSpace;
  final Function(String, int, int) onReorderLoopsInSpace;
  final Function(int, String) onMoveLoopToSpace;

  const StepLoopSwitchWidget({
    super.key,
    required this.loops,
    required this.switches,
    required this.switchCountController,
    required this.otherDevices,
    required this.spaces,
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
    required this.onAddSpace,
    required this.onRemoveSpace,
    required this.onRenameSpace,
    required this.onReorderLoopsInSpace,
    required this.onMoveLoopToSpace,
  });

  @override
  State<StepLoopSwitchWidget> createState() => _StepLoopSwitchWidgetState();
}

class _StepLoopSwitchWidgetState extends State<StepLoopSwitchWidget> {
  late bool _loopsExpanded;
  late bool _switchesExpanded;
  late bool _otherDevicesExpanded;
  final Set<String> _collapsedSpaces = {};

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

  void _showAddSpaceDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增空間'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '空間名稱',
            border: OutlineInputBorder(),
            hintText: '例如：客廳、臥室、廚房',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                widget.onAddSpace(name);
                Navigator.of(context).pop();
              }
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  void _showRenameSpaceDialog(String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重新命名空間'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '空間名稱',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                widget.onRenameSpace(oldName, newName);
                Navigator.of(context).pop();
              }
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSpaceDialog(String spaceName) {
    final loopsInSpace = widget.loops.where((l) => l.space == spaceName).length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除空間'),
        content: Text(
          loopsInSpace > 0
              ? '空間「$spaceName」中有 $loopsInSpace 個迴路，刪除後這些迴路將移至「未分類」。\n確定要刪除嗎？'
              : '確定要刪除空間「$spaceName」嗎？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              widget.onRemoveSpace(spaceName);
              Navigator.of(context).pop();
            },
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  /// 按空間分組迴路，保留原始 index
  Map<String, List<MapEntry<int, Loop>>> _groupLoopsBySpace() {
    final grouped = <String, List<MapEntry<int, Loop>>>{};
    // 先按 spaces 順序建立空 list
    for (final space in widget.spaces) {
      grouped[space] = [];
    }
    // 再填入迴路
    for (int i = 0; i < widget.loops.length; i++) {
      final loop = widget.loops[i];
      grouped.putIfAbsent(loop.space, () => []);
      grouped[loop.space]!.add(MapEntry(i, loop));
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedLoops = _groupLoopsBySpace();

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
              OutlinedButton.icon(
                onPressed: _showAddSpaceDialog,
                icon: const Icon(Icons.room, size: 18),
                label: const Text('新增空間'),
              ),
              const SizedBox(width: 8),
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
          if (widget.loops.isEmpty && widget.spaces.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  '尚未添加任何迴路\n點擊上方按鈕新增空間並添加迴路',
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
            ...groupedLoops.entries.map((spaceEntry) {
              final spaceName = spaceEntry.key;
              final loopsInSpace = spaceEntry.value;
              final isCollapsed = _collapsedSpaces.contains(spaceName);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // 空間標題列（支援拖放迴路到此空間）
                    DragTarget<int>(
                      onWillAcceptWithDetails: (details) {
                        // 只接受來自不同空間的迴路
                        final draggedLoop = widget.loops[details.data];
                        return draggedLoop.space != spaceName;
                      },
                      onAcceptWithDetails: (details) {
                        widget.onMoveLoopToSpace(details.data, spaceName);
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isHovering = candidateData.isNotEmpty;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isCollapsed) {
                                _collapsedSpaces.remove(spaceName);
                              } else {
                                _collapsedSpaces.add(spaceName);
                              }
                            });
                          },
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isHovering
                                  ? Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.15)
                                  : Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withValues(alpha: 0.3),
                              borderRadius: isCollapsed
                                  ? BorderRadius.circular(12)
                                  : const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                              border: isHovering
                                  ? Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isCollapsed
                                      ? Icons.expand_more
                                      : Icons.expand_less,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.room,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  spaceName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${loopsInSpace.length} 迴路)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (isHovering) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '拖放至此',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                if (spaceName != '未分類') ...[
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    onPressed: () =>
                                        _showRenameSpaceDialog(spaceName),
                                    tooltip: '重新命名',
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    onPressed: () =>
                                        _showDeleteSpaceDialog(spaceName),
                                    tooltip: '刪除空間',
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // 展開的迴路列表
                    if (!isCollapsed) ...[
                      if (loopsInSpace.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '此空間尚無迴路',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Column(
                            children: [
                              for (
                                int localIdx = 0;
                                localIdx < loopsInSpace.length;
                                localIdx++
                              )
                                _buildDraggableLoopCard(
                                  key: ValueKey(
                                    'loop_${loopsInSpace[localIdx].key}',
                                  ),
                                  globalIndex: loopsInSpace[localIdx].key,
                                  localIndex: localIdx,
                                  loop: loopsInSpace[localIdx].value,
                                  spaceName: spaceName,
                                  totalInSpace: loopsInSpace.length,
                                ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
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

  Widget _buildDraggableLoopCard({
    required Key key,
    required int globalIndex,
    required int localIndex,
    required Loop loop,
    required String spaceName,
    required int totalInSpace,
  }) {
    final cardContent = Row(
      key: key,
      children: [
        // 拖拉把手
        MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Icon(
              Icons.drag_indicator,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
        Expanded(
          child: LoopCardWidget(
            index: globalIndex,
            loop: loop,
            onUpdateLoop: widget.onUpdateLoop,
            onRemoveLoop: widget.onRemoveLoop,
            onAddFixture: widget.onAddFixtureToLoop,
            onRemoveFixture: widget.onRemoveFixtureFromLoop,
            onEditFixture: widget.onEditFixtureInLoop,
          ),
        ),
      ],
    );

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        if (details.data == globalIndex) return false;
        return true;
      },
      onAcceptWithDetails: (details) {
        final draggedIndex = details.data;
        final draggedLoop = widget.loops[draggedIndex];
        if (draggedLoop.space != spaceName) {
          // 跨空間移動
          widget.onMoveLoopToSpace(draggedIndex, spaceName);
        } else {
          // 同空間內重新排序：找到被拖動的迴路在本空間的 localIndex
          int draggedLocalIdx = -1;
          int count = 0;
          for (int i = 0; i < widget.loops.length; i++) {
            if (widget.loops[i].space == spaceName) {
              if (i == draggedIndex) {
                draggedLocalIdx = count;
                break;
              }
              count++;
            }
          }
          if (draggedLocalIdx >= 0 && draggedLocalIdx != localIndex) {
            int newLocal = localIndex;
            if (draggedLocalIdx < localIndex) {
              newLocal += 1; // ReorderableListView 的慣例
            }
            widget.onReorderLoopsInSpace(spaceName, draggedLocalIdx, newLocal);
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isAccepting = candidateData.isNotEmpty;
        return Draggable<int>(
          data: globalIndex,
          feedback: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              child: Opacity(
                opacity: 0.85,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.drag_indicator,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loop.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: cardContent),
          child: Container(
            decoration: isAccepting
                ? BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      ),
                    ),
                  )
                : null,
            child: cardContent,
          ),
        );
      },
    );
  }
}