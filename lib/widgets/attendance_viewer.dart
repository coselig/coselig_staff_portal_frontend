import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/attendance_service.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:coselig_staff_portal/widgets/month_year_picker.dart';
import 'package:coselig_staff_portal/widgets/attendance_calendar_view.dart';
import 'package:coselig_staff_portal/services/attendance_excel_export_service.dart';
import 'package:coselig_staff_portal/main.dart';

class AttendanceViewer extends StatefulWidget {
  const AttendanceViewer({super.key});

  @override
  State<AttendanceViewer> createState() => _AttendanceViewerState();
}

class _AttendanceViewerState extends State<AttendanceViewer> {
  DateTime _selectedMonth = DateTime.now();
  final ExcelExportService _excelExportService = ExcelExportService();

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceService>();
    final authService = context.read<AuthService>();
    final userId = authService.userId;

    return Column(
      children: [
        if (attendance.errorMessage != null)
          Text(
            attendance.errorMessage!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 14,
            ),
          ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('選擇月份'),
              onPressed: () async {
                final result = await showMonthYearPicker(
                  context: context,
                  initialYear: _selectedMonth.year,
                  initialMonth: _selectedMonth.month,
                );
                if (result != null) {
                  setState(() {
                    _selectedMonth = DateTime(result.year, result.month);
                  });
                  if (userId != null) {
                    await attendance.fetchAndCacheMonthAttendance(
                      userId,
                      _selectedMonth,
                    );
                  }
                  scaffoldMessengerKey.currentState!.showSnackBar(
                    SnackBar(
                      content: Text('選擇的日期:${result.year}/${result.month}'),
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              child: const Text('匯出Excel'),
              onPressed: () async {
                final employeeName = authService.name ?? '員工';
                final employeeId = authService.userId ?? '';

                try {
                  await _excelExportService.exportAttendanceRecords(
                    employeeName: employeeName,
                    employeeId: employeeId,
                    monthRecords: attendance.currentMonthRecords,
                    month: _selectedMonth,
                  );
                  scaffoldMessengerKey.currentState!.showSnackBar(
                    const SnackBar(content: Text('Excel檔案匯出成功')),
                  );
                } catch (e) {
                  scaffoldMessengerKey.currentState!.showSnackBar(
                    SnackBar(content: Text('匯出失敗: $e')),
                  );
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 24),
        Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: AttendanceCalendarView(
              month: _selectedMonth,
              recordsMap: attendance.currentMonthRecords,
              leaveDaysMap: {},
              todayDay:
                  (_selectedMonth.year == DateTime.now().year &&
                      _selectedMonth.month == DateTime.now().month)
                  ? DateTime.now().day
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}