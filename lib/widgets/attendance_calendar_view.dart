import 'package:coselig_staff_portal/utils/time_utils.dart';
import 'package:flutter/material.dart';

/// 月曆視圖元件，顯示一個月的打卡、請假、假日狀態
typedef OnManualPunch = void Function(int day, dynamic record);

class AttendanceCalendarView extends StatelessWidget {
  final DateTime month;
  final Map<int, dynamic> recordsMap; // day -> record
  final Map<int, List<dynamic>> leaveDaysMap; // day -> leave list
  final Map<int, dynamic> holidaysMap; // day -> holiday
  final int? todayDay;
  final Map<int, String>? periodNames; // 時段名稱映射

  final OnManualPunch? onManualPunch;

  const AttendanceCalendarView({
    super.key,
    required this.month,
    required this.recordsMap,
    required this.leaveDaysMap,
    required this.holidaysMap,
    this.todayDay,
    this.onManualPunch,
    this.periodNames,
  });

  @override
  Widget build(BuildContext context) {
    // 取得本月1號的日期
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    // 取得本月最後一天的日期
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    // 1號是星期幾（1=週一, 7=週日，若為7則轉成0，讓1號對齊在週日）
    final firstWeekday = firstDayOfMonth.weekday == 7
        ? 0
        : firstDayOfMonth.weekday;
    // 本月天數
    final daysInMonth = lastDayOfMonth.day;
    // 計算總格數（補足前面空格與最後一週）
    final totalCells = ((daysInMonth + firstWeekday) / 7).ceil() * 7;
    final List<Widget> gridItems = [];
    // 產生月曆格子
    for (int i = 0; i < totalCells; i++) {
      // 前面 firstWeekday 個格子補空白，讓1號對齊正確星期
      // 超過本月天數的格子也補空白
      if (i < firstWeekday || i - firstWeekday + 1 > daysInMonth) {
        gridItems.add(const SizedBox.shrink());
      } else {
        // 計算當前格子是幾號
        final day = i - firstWeekday + 1;
        final record = recordsMap[day];
        final leave = leaveDaysMap[day];
        final holiday = holidaysMap[day];
        final isToday = todayDay == day;
        // 判斷是否為週末（週日或週六）
        final isWeekend = (i % 7 == 0) || (i % 7 == 6);
        gridItems.add(
          _buildCalendarDay(
            context,
            day,
            record,
            leave,
            isToday,
            holiday,
            isWeekend,
          ),
        );
      }
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            constraints.maxWidth.clamp(280.0, 420.0); // 最小280，最大420
            return Column(
              children: [
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final label in ['日', '一', '二', '三', '四', '五', '六'])
                      Center(
                        child: Text(
                          label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.0, // 正方形比例
                  children: gridItems,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCalendarDay(
    BuildContext context,
    int day,
    dynamic record,
    List<dynamic>? leaveRequests,
    bool isToday,
    dynamic holiday,
    bool isWeekend,
  ) {
    Color backgroundColor;
    Color textColor = Theme.of(context).colorScheme.onSurface;
    String status = '';
    if (holiday != null) {
      backgroundColor = Theme.of(context).colorScheme.errorContainer;
      textColor = Theme.of(context).colorScheme.onErrorContainer;
      status = '假日';
    } else if (leaveRequests != null && leaveRequests.isNotEmpty) {
      backgroundColor = Theme.of(context).colorScheme.secondaryContainer;
      textColor = Theme.of(context).colorScheme.onSecondaryContainer;
      status = '請假';
    } else if (record != null) {
      backgroundColor = Theme.of(context).colorScheme.primaryContainer;
      textColor = Theme.of(context).colorScheme.onPrimaryContainer;

      // 收集所有時段的打卡記錄
      final List<Map<String, dynamic>> periodRecords = [];

      // 檢查所有可能的時段記錄（包含動態時段名稱）
      final Map<String, Map<String, String?>> periodData = {};

      record.forEach((key, value) {
        if (key is String &&
            value != null &&
            (key.endsWith('_check_in_time') ||
                key.endsWith('_check_out_time'))) {
          // 提取時段名稱（去掉 _check_in_time 或 _check_out_time 後綴）
          String periodName;
          try {
            if (key.endsWith('_check_in_time')) {
              periodName = key.substring(
                0,
                key.length - '_check_in_time'.length,
              );
            } else {
              periodName = key.substring(
                0,
                key.length - '_check_out_time'.length,
              );
            }

            // 防護：確保 periodName 不為空
            if (periodName.isEmpty) {
              return; // 跳過這個記錄
            }

            // 初始化時段資料
            if (periodData[periodName] == null) {
              periodData[periodName] = {'checkIn': null, 'checkOut': null};
            }

            // 設定打卡時間
            if (key.endsWith('_check_in_time')) {
              periodData[periodName]!['checkIn'] = value?.toString();
            } else {
              periodData[periodName]!['checkOut'] = value?.toString();
            }
          } catch (e) {
            // 如果字串處理出錯，跳過這個記錄
          }
        }
      });

      // 轉換為排序用的格式
      periodData.forEach((periodName, data) {
        final checkIn = data['checkIn'];
        final checkOut = data['checkOut'];

        if (checkIn != null || checkOut != null) {
          periodRecords.add({
            'periodName': periodName,
            'checkIn': checkIn,
            'checkOut': checkOut,
          });
        }
      });

      // 按照上班打卡時間排序
      periodRecords.sort((a, b) {
        final aCheckIn = a['checkIn'];
        final bCheckIn = b['checkIn'];

        if (aCheckIn == null && bCheckIn == null) {
          return a['periodName'].compareTo(b['periodName']); // 都沒有上班時間，按名稱排序
        } else if (aCheckIn == null) {
          return 1; // a沒有上班時間，排在後面
        } else if (bCheckIn == null) {
          return -1; // b沒有上班時間，排在後面
        } else {
          return aCheckIn.compareTo(bCheckIn); // 按上班時間排序
        }
      });

      // 根據排序後的時段生成狀態文字
      final List<String> periodStatuses = [];
      for (final periodRecord in periodRecords) {
        final checkIn = periodRecord['checkIn'];
        final checkOut = periodRecord['checkOut'];

        String periodStatus = '';

        if (checkIn != null && checkOut != null) {
          periodStatus = '${formatTime(checkIn)}~${formatTime(checkOut)}';
        } else if (checkIn != null) {
          periodStatus = '上${formatTime(checkIn)}';
        } else if (checkOut != null) {
          periodStatus = '下${formatTime(checkOut)}';
        }

        if (periodStatus.isNotEmpty) {
          periodStatuses.add(periodStatus);
        }
      }

      // 如果沒有時段記錄，檢查舊格式
      if (periodStatuses.isEmpty) {
        String checkIn = record['check_in_time'] ?? '';
        String checkOut = record['check_out_time'] ?? '';

        if (checkIn.isNotEmpty && checkOut.isNotEmpty) {
          status = '上:${formatTime(checkIn)}\n下:${formatTime(checkOut)}';
        } else if (checkIn.isNotEmpty) {
          status = '上:${formatTime(checkIn)}';
        } else if (checkOut.isNotEmpty) {
          status = '下:${formatTime(checkOut)}';
        } else {
          status = '打卡';
        }
      } else {
        // 使用時段記錄，最多顯示2個時段，避免太擠
        if (periodStatuses.length <= 2) {
          status = periodStatuses.join('\n');
        } else {
          status = '${periodStatuses.take(2).join('\n')}\n...';
        }
      }
    } else {
      backgroundColor = Theme.of(context).colorScheme.surfaceVariant;
      textColor = Theme.of(context).colorScheme.onSurfaceVariant;
      status = '';
    }

    if (isWeekend && status == '') {
      backgroundColor = Theme.of(context).colorScheme.surface;
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        onLongPress: () {
          if (onManualPunch != null) {
            onManualPunch!(day, record);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isToday
                ? [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
            border: isToday
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (status.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    status,
                    style: TextStyle(color: textColor, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
