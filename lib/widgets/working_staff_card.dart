import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/attendance_service.dart';
import 'package:intl/intl.dart';

class WorkingStaffCard extends StatefulWidget {
  const WorkingStaffCard({super.key});

  @override
  State<WorkingStaffCard> createState() => _WorkingStaffCardState();
}

class _WorkingStaffCardState extends State<WorkingStaffCard> {
  String formatTime(dynamic time) {
    if (time == null) return '未知';
    try {
      final dateTime = DateTime.parse(time.toString());
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return time.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceService>();

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  '目前正在上班的員工',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: '刷新',
                  onPressed: attendance.isLoadingWorkingStaff
                      ? null
                      : () => attendance.fetchAndCacheWorkingStaff(),
                ),
              ],
            ),
            attendance.isLoadingWorkingStaff
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : attendance.workingStaffList.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '目前沒有員工正在上班',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  )
                : Column(
                    children: attendance.workingStaffList.map((emp) {
                      final chineseName = emp['chinese_name'];
                      final englishName = emp['name'] ?? '';
                      final displayName =
                          chineseName != null && chineseName.toString().isNotEmpty
                          ? chineseName.toString()
                          : englishName;
                      return ListTile(
                        leading: const Icon(Icons.person, color: Colors.blue),
                        title: Text(displayName),
                        subtitle: Text(
                          '上班時間：${formatTime(emp['check_in_time'])}',
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}