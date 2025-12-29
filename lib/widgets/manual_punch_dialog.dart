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
                final periodName = '時段${period.replaceAll('period', '')}';
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
                          child: const Text('選擇'),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: times['check_in'] ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setState(
                                () =>
                                    _periodsTimes[period]!['check_in'] = picked,
                              );
                            }
                          },
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
                          child: const Text('選擇'),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime:
                                  times['check_out'] ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setState(
                                () => _periodsTimes[period]!['check_out'] =
                                    picked,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),
              ElevatedButton(
                child: const Text('新增時段'),
                onPressed: () {
                  // 找到最大的 period 號碼
                  int maxNum = 0;
                  _periodsTimes.keys.forEach((key) {
                    final numStr = key.replaceAll('period', '');
                    final num = int.tryParse(numStr) ?? 0;
                    if (num > maxNum) maxNum = num;
                  });
                  final newPeriod = 'period${maxNum + 1}';
                  setState(() {
                    _periodsTimes[newPeriod] = {
                      'check_in': null,
                      'check_out': null,
                    };
                  });
                },
              ),
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
                'check_in': times['check_in']?.format(context),
                'check_out': times['check_out']?.format(context),
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
