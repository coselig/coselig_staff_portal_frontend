import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/models/quote/quote_models.dart';
import 'package:coselig_staff_portal/utils/icon_utils.dart';

class SwitchCardWidget extends StatefulWidget {
  final int index;
  final SwitchModel switchModel;
  final Function(int, SwitchModel) onUpdateSwitch;
  final Function(int) onRemoveSwitch;
  final List<String> spaces;
  final List<Loop> loops;

  const SwitchCardWidget({
    super.key,
    required this.index,
    required this.switchModel,
    required this.onUpdateSwitch,
    required this.onRemoveSwitch,
    required this.spaces,
    required this.loops,
  });

  @override
  State<SwitchCardWidget> createState() => _SwitchCardWidgetState();
}

class _SwitchCardWidgetState extends State<SwitchCardWidget> {
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
                      widget.switchModel.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (!_isExpanded) ...[
                    Text(
                      'x${widget.switchModel.count} · ${widget.switchModel.fireType} · ${widget.switchModel.allControlledLoopNames.length}迴路',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditSwitchDialog(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => widget.onRemoveSwitch(widget.index),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('數量：${widget.switchModel.count}'),
                  if (widget.switchModel.price > 0)
                    Text('價格：${widget.switchModel.price}'),
                  Text('單火/零火：${widget.switchModel.fireType}'),
                  Text('協定類型：${widget.switchModel.protocol}'),
                  Text('顏色：${widget.switchModel.color}'),
                  const SizedBox(height: 12),
                  const Divider(),
                  // 每切分區
                  ...List.generate(widget.switchModel.gangs.length, (
                    gangIndex,
                  ) {
                    final gang = widget.switchModel.gangs[gangIndex];
                    return _buildGangSection(gangIndex, gang);
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGangSection(int gangIndex, SwitchGang gang) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 切標題 + 場景開關
          Row(
            children: [
              Text(
                '第 ${gangIndex + 1} 切',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (widget.switchModel.sceneCapable) ...[
                Text(
                  '場景開關',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Switch(
                  value: gang.isScene,
                  onChanged: (value) {
                    final updatedGangs = widget.switchModel.gangs
                        .map((g) => g.copyWith())
                        .toList();
                    // 切換場景模式時，若關閉場景且已有多個迴路，保留第一個
                    if (!value && gang.controlledLoopNames.length > 1) {
                      updatedGangs[gangIndex] = gang.copyWith(
                        isScene: false,
                        controlledLoopNames: [gang.controlledLoopNames.first],
                      );
                    } else {
                      updatedGangs[gangIndex] = gang.copyWith(isScene: value);
                    }
                    widget.onUpdateSwitch(
                      widget.index,
                      widget.switchModel.copyWith(gangs: updatedGangs),
                    );
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          // 迴路選擇區
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ...gang.controlledLoopNames.map((loopName) {
                return Chip(
                  label: Text(loopName, style: const TextStyle(fontSize: 13)),
                  deleteIcon: Icon(
                    Icons.close,
                    size: context.scaledIconSize(16),
                  ),
                  onDeleted: () {
                    _removeLoopFromGang(gangIndex, loopName);
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }),
              // 新增/替換迴路按鈕（跟在最後一個 Chip 後面）
              if (gang.isScene || gang.controlledLoopNames.isEmpty)
                ActionChip(
                  avatar: Icon(Icons.add, size: context.scaledIconSize(16)),
                  label: const Text('新增', style: TextStyle(fontSize: 13),
                  ),
                  tooltip: gang.isScene ? '新增控制迴路' : '選擇控制迴路',
                  onPressed: () =>
                      _showSelectLoopForGangDialog(context, gangIndex, gang),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )
              else
                ActionChip(
                  avatar: Icon(
                    Icons.swap_horiz,
                    size: context.scaledIconSize(16),
                  ),
                  label: const Text('替換', style: TextStyle(fontSize: 13),
                  ),
                  tooltip: '替換控制迴路',
                  onPressed: () => _showSelectLoopForGangDialog(
                    context,
                    gangIndex,
                    gang,
                    replaceSingle: true,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (gangIndex < widget.switchModel.gangs.length - 1)
            const Divider(height: 16),
        ],
      ),
    );
  }

  void _removeLoopFromGang(int gangIndex, String loopName) {
    final updatedGangs = widget.switchModel.gangs
        .map((g) => g.copyWith())
        .toList();
    final updatedNames = List<String>.from(
      updatedGangs[gangIndex].controlledLoopNames,
    )..remove(loopName);
    updatedGangs[gangIndex] = updatedGangs[gangIndex].copyWith(
      controlledLoopNames: updatedNames,
    );
    widget.onUpdateSwitch(
      widget.index,
      widget.switchModel.copyWith(gangs: updatedGangs),
    );
  }

  void _showSelectLoopForGangDialog(
    BuildContext context,
    int gangIndex,
    SwitchGang gang, {
    bool replaceSingle = false,
  }) {
    // 計算所有其他切已使用的迴路名稱
    final usedByOtherGangs = <String>{};
    for (int i = 0; i < widget.switchModel.gangs.length; i++) {
      if (i != gangIndex) {
        usedByOtherGangs.addAll(
          widget.switchModel.gangs[i].controlledLoopNames,
        );
      }
    }

    // 取得同空間的迴路，排除已被其他切使用的
    final sameSpaceLoops = widget.loops
        .where((l) => l.space == widget.switchModel.space)
        .where((l) => !usedByOtherGangs.contains(l.name))
        .toList();

    // 場景模式：排除本切已選的
    final availableLoops = gang.isScene && !replaceSingle
        ? sameSpaceLoops
              .where((l) => !gang.controlledLoopNames.contains(l.name))
              .toList()
        : sameSpaceLoops;

    if (availableLoops.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('此空間中沒有可選的迴路')));
      return;
    }

    if (gang.isScene && !replaceSingle) {
      // 場景模式：多選
      final selected = <String>{};
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('第 ${gangIndex + 1} 切 — 選擇控制迴路（場景）'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: availableLoops.map((loop) {
                  final isSelected = selected.contains(loop.name);
                  return CheckboxListTile(
                    title: Text(loop.name),
                    subtitle: Text(
                      '${loop.voltage}V · ${loop.dimmingType} · ${loop.totalWatt}W',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: isSelected,
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          selected.add(loop.name);
                        } else {
                          selected.remove(loop.name);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: selected.isNotEmpty
                    ? () {
                        final updatedGangs = widget.switchModel.gangs
                            .map((g) => g.copyWith())
                            .toList();
                        final updatedNames = List<String>.from(
                          gang.controlledLoopNames,
                        )..addAll(selected);
                        updatedGangs[gangIndex] = gang.copyWith(
                          controlledLoopNames: updatedNames,
                        );
                        widget.onUpdateSwitch(
                          widget.index,
                          widget.switchModel.copyWith(gangs: updatedGangs),
                        );
                        Navigator.of(context).pop();
                      }
                    : null,
                child: Text('確定 (${selected.length})'),
              ),
            ],
          ),
        ),
      );
    } else {
      // 非場景模式或替換：單選
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            replaceSingle
                ? '第 ${gangIndex + 1} 切 — 替換控制迴路'
                : '第 ${gangIndex + 1} 切 — 選擇控制迴路',
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: availableLoops.map((loop) {
                return ListTile(
                  title: Text(loop.name),
                  subtitle: Text(
                    '${loop.voltage}V · ${loop.dimmingType} · ${loop.totalWatt}W',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    final updatedGangs = widget.switchModel.gangs
                        .map((g) => g.copyWith())
                        .toList();
                    updatedGangs[gangIndex] = gang.copyWith(
                      controlledLoopNames: [loop.name],
                    );
                    widget.onUpdateSwitch(
                      widget.index,
                      widget.switchModel.copyWith(gangs: updatedGangs),
                    );
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        ),
      );
    }
  }

  void _showEditSwitchDialog(BuildContext context) {
    final nameController = TextEditingController(text: widget.switchModel.name);
    String space = widget.switchModel.space;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('編輯開關'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: space,
                  decoration: const InputDecoration(labelText: '所屬空間'),
                  items: widget.spaces
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => space = v ?? '未分類'),
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '名稱'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final updated = widget.switchModel.copyWith(
                  name: nameController.text,
                  space: space,
                );
                widget.onUpdateSwitch(widget.index, updated);
                Navigator.of(context).pop();
              },
              child: const Text('儲存'),
            ),
          ],
        ),
      ),
    );
  }
}
