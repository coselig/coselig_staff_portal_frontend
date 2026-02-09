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
    // 嘗試自動新增下一個時段（只適用於以period開頭的傳統格式）
    _tryAddNextPeriodIfApplicable();
  }

  // 嘗試自動新增下一個時段（只適用於period1, period2...格式）
  void _tryAddNextPeriodIfApplicable() {
    // 檢查是否所有時段都遵循period格式
    bool allArePeriodFormat = _periodsTimes.keys.every((period) {
      return period.startsWith('period') &&
          int.tryParse(period.replaceAll('period', '')) != null;
    });

    if (!allArePeriodFormat) return; // 如果不是傳統格式，不自動新增

    int maxNum = 0;
    int highestFilled = 0;
    _periodsTimes.forEach((period, times) {
      final num = int.tryParse(period.replaceAll('period', '')) ?? 0;
      if (num > maxNum) maxNum = num;
      if (times['check_in'] != null || times['check_out'] != null) {
        if (num > highestFilled) highestFilled = num;
      }
    });
    if (highestFilled >= 1 &&
        !_periodsTimes.containsKey('period${highestFilled + 1}')) {
      _periodsTimes['period${highestFilled + 1}'] = {
        'check_in': null,
        'check_out': null,
      };
    }
  }

// 直接顯示時段名稱，不進行任何轉換
  String _getPeriodDisplayName(String periodKey) {
    return periodKey;
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

  // 當某個時段有任何時間被設定時，自動新增下一個空時段（若不存在）
  void _maybeAddNextPeriod(String period) {
    // 只對傳統的period格式自動新增
    if (!period.startsWith('period')) return;
    
    final num = int.tryParse(period.replaceAll('period', '')) ?? 0;
    if (num == 0) return;
    final times = _periodsTimes[period];
    if (times == null) return;
    if (times['check_in'] == null && times['check_out'] == null) return;
    final nextPeriod = 'period${num + 1}';
    if (!_periodsTimes.containsKey(nextPeriod)) {
      _periodsTimes[nextPeriod] = {'check_in': null, 'check_out': null};
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
                                      _maybeAddNextPeriod(period);
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
                                      _maybeAddNextPeriod(period);
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
