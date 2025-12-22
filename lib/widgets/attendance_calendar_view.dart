import 'package:coselig_staff_portal/utils/time_utils.dart';
import 'package:flutter/material.dart';

/// 月曆視圖元件，顯示一個月的打卡、請假、假日狀態
class AttendanceCalendarView extends StatelessWidget {
  final DateTime month;
  final Map<int, dynamic> recordsMap; // day -> record
  final Map<int, List<dynamic>> leaveDaysMap; // day -> leave list
  final Map<int, dynamic> holidaysMap; // day -> holiday
  final int? todayDay;
  
  final double cellWidth;

  const AttendanceCalendarView({
    super.key,
    required this.month,
    required this.recordsMap,
    required this.leaveDaysMap,
    required this.holidaysMap,
    this.todayDay,
    this.cellWidth = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    const cellWidth = 36.0;
    final totalCells = ((daysInMonth + firstWeekday) / 7).ceil() * 7;
    final List<Widget> gridItems = [];
    for (int i = 0; i < totalCells; i++) {
      if (i < firstWeekday || i - firstWeekday + 1 > daysInMonth) {
        gridItems.add(const SizedBox.shrink());
      } else {
        final day = i - firstWeekday + 1;
        final record = recordsMap[day];
        final leave = leaveDaysMap[day];
        final holiday = holidaysMap[day];
        final isToday = todayDay == day;
        final isWeekend = (i % 7 == 0) || (i % 7 == 6);
        gridItems.add(_buildCalendarDay(context, day, record, leave, isToday, holiday, isWeekend));
      }
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: cellWidth / 32.0,
              children: [
                for (final label in ['日', '一', '二', '三', '四', '五', '六'])
                  Center(
                    child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: cellWidth / 64.0,
              children: gridItems,
            ),
          ],
        ),
      ),
    );
  }

  String _debugRecordString(dynamic record) {
    if (record is Map<String, dynamic>) {
      String checkIn = record['check_in_time'] ?? '';
      String checkOut = record['check_out_time'] ?? '';
      String day = record['day']?.toString() ?? '';
      return 'day:$day\n上:${formatTime(checkIn)} 下:${formatTime(checkOut)}';
    }
    return record.toString();
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
    Color textColor = Colors.black87;
    IconData? icon;
    String status = '';
    if (holiday != null) {
      backgroundColor = Colors.red.shade100;
      textColor = Colors.red.shade700;
      icon = Icons.celebration;
      status = '假日';
    } else if (leaveRequests != null && leaveRequests.isNotEmpty) {
      backgroundColor = Colors.pink.shade100;
      textColor = Colors.pink.shade900;
      icon = Icons.event_busy;
      status = '請假';
    } else if (record != null) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade900;
      icon = Icons.check_circle;
      // 顯示上班/下班時間
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
      backgroundColor = Colors.grey.shade100;
      textColor = Colors.grey.shade600;
      status = '';
    }
      
    if (isWeekend && status == '') {
      backgroundColor = Colors.grey.shade200;
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isToday
                ? [BoxShadow(color: Colors.blue.shade100, blurRadius: 8, spreadRadius: 1)]
                : [],
            border: isToday ? Border.all(color: Colors.blue, width: 2) : null,
          ),
          width: cellWidth,
          height: 44,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$day', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
              if (icon != null) Icon(icon, size: 24, color: textColor),
              if (status.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    status,
                    style: TextStyle(color: textColor, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (record != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _debugRecordString(record),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
  
            ],
          ),
        ),
      ),
    );
  }
}
