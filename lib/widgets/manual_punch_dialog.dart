import 'package:flutter/material.dart';

/// 補打卡彈出視窗元件
class ManualPunchDialog extends StatefulWidget {
  final String employeeName;
  final DateTime date;
  final Map<String, Map<String, String?>> periodsData;
  final void Function(Map<String, Map<String, String?>> periods) onSubmit;

  const ManualPunchDialog({
    super.key,
    required this.employeeName,
    required this.date,
    required this.periodsData,
    required this.onSubmit,
  });

  @override
  State<ManualPunchDialog> createState() => _ManualPunchDialogState();
}

class _ManualPunchDialogState extends State<ManualPunchDialog> {
  late Map<String, Map<String, TimeOfDay?>> _periodsTimes;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _periodsTimes = {};
    for (final entry in widget.periodsData.entries) {
      final period = entry.key;
      final data = entry.value;
      _periodsTimes[period] = {
        'check_in': _parseTime(data['check_in']),
        'check_out': _parseTime(data['check_out']),
      };
    }
  }

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    // 如果是完整的 datetime 格式，如 "2025-12-29 05:22:59"，提取時間部分
    final parts = timeStr.split(' ');
    final timePart = parts.length > 1 ? parts[1] : timeStr;
    final timeComponents = timePart.split(':');
    if (timeComponents.length >= 2) {
      final hour = int.tryParse(timeComponents[0]);
      final minute = int.tryParse(timeComponents[1]);
      if (hour != null && minute != null) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    return null;
  }

  // 直接顯示時段名稱，不進行任何轉換
  String _getPeriodDisplayName(String periodKey) {
    return periodKey;
  }

  // 檢查是否可以新增時段（至少有一個時段設置了上班時間）
  bool _canAddNewPeriod() {
    return _periodsTimes.values.any((times) => times['check_in'] != null);
  }

  // 新增一個空的時段
  void _addNewPeriod() {
    // 生成新的時段名稱，基於現有時段
    String newPeriodName = _generateNewPeriodName();

    setState(() {
      _periodsTimes[newPeriodName] = {'check_in': null, 'check_out': null};
    });
  }

  // 生成新的時段名稱，統一使用"補打卡時段X"格式
  String _generateNewPeriodName() {
    int maxNum = 0;
    // 查找所有現有的補打卡時段
    for (var period in _periodsTimes.keys) {
      if (period.startsWith('補打卡時段')) {
        final numStr = period.replaceAll('補打卡時段', '');
        final num = int.tryParse(numStr) ?? 0;
        if (num > maxNum) maxNum = num;
      }
    }
    return '補打卡時段${maxNum + 1}';
  }

  // 在設置上班時間後檢查是否自動新增下一個時段
  void _checkAndAddNextPeriod(String period) {
    // 只有在設置上班時間後，才檢查是否需要自動新增
    final times = _periodsTimes[period];
    if (times != null && times['check_in'] != null) {
      // 如果這是最後一個時段，自動新增下一個補打卡時段
      final sortedPeriods = _periodsTimes.keys.toList()..sort();
      if (period == sortedPeriods.last) {
        _addNewPeriod();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('補打卡 - ${widget.employeeName}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '日期：${widget.date.year}/${widget.date.month}/${widget.date.day}',
              ),
              const SizedBox(height: 16),
              ..._periodsTimes.entries.map((entry) {
                final period = entry.key;
                final times = entry.value;
                final periodName = _getPeriodDisplayName(period);
                return Column(
                  children: [
                    Text(
                      periodName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '上班：${times['check_in'] != null ? '${times['check_in']!.hour.toString().padLeft(2, '0')}:${times['check_in']!.minute.toString().padLeft(2, '0')}' : '未設定'}',
                          ),
                        ),
                        TextButton(
                          onPressed:
                              (widget.periodsData[period]?['check_in'] == null)
                              ? () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime:
                                        times['check_in'] ?? TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _periodsTimes[period]!['check_in'] =
                                          picked;
                                      // 設置上班時間後，檢查是否可以新增下一個時段
                                      _checkAndAddNextPeriod(period);
                                    });
                                  }
                                }
                              : null,
                          child: const Text('選擇'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '下班：${times['check_out'] != null ? '${times['check_out']!.hour.toString().padLeft(2, '0')}:${times['check_out']!.minute.toString().padLeft(2, '0')}' : '未設定'}',
                          ),
                        ),
                        TextButton(
                          onPressed:
                              (widget.periodsData[period]?['check_out'] == null)
                              ? () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime:
                                        times['check_out'] ?? TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _periodsTimes[period]!['check_out'] =
                                          picked;
                                    });
                                  }
                                }
                              : null,
                          child: const Text('選擇'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),

              // 新增時段按鈕
              ElevatedButton.icon(
                onPressed: _canAddNewPeriod() ? _addNewPeriod : null,
                icon: const Icon(Icons.add),
                label: const Text('新增時段'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canAddNewPeriod() ? null : Colors.grey,
                ),
              ),
              const SizedBox(height: 16),

            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('取消'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('送出'),
          onPressed: () {
            final result = <String, Map<String, String?>>{};
            _periodsTimes.forEach((period, times) {
              result[period] = {
                'check_in':
                    widget.periodsData[period]?['check_in'] ??
                    (times['check_in'] != null
                          ? '${times['check_in']!.hour.toString().padLeft(2, '0')}:${times['check_in']!.minute.toString().padLeft(2, '0')}:00'
                        : null),
                'check_out':
                    widget.periodsData[period]?['check_out'] ??
                    (times['check_out'] != null
                          ? '${times['check_out']!.hour.toString().padLeft(2, '0')}:${times['check_out']!.minute.toString().padLeft(2, '0')}:00'
                        : null),
              };
            });
            widget.onSubmit(result);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
