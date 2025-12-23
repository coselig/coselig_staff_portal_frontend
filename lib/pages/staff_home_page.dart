import 'package:coselig_staff_portal/utils/time_utils.dart';
import 'package:coselig_staff_portal/services/attendance_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:coselig_staff_portal/widgets/month_year_picker.dart';
import 'package:coselig_staff_portal/widgets/attendance_calendar_view.dart';
import 'package:coselig_staff_portal/main.dart';
import 'package:coselig_staff_portal/services/excel_export_service.dart';

class StaffHomePage extends StatefulWidget {
  const StaffHomePage({super.key});

  @override
  State<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends State<StaffHomePage> {
  bool _requested = false;
  DateTime _selectedMonth = DateTime.now();
  Map<int, dynamic> _monthRecords = {};
  final ExcelExportService _excelExportService = ExcelExportService();

  @override
  void initState() {
    super.initState();
    Future.microtask(_initUserAndAttendance);
  }

  Future<void> _initUserAndAttendance() async {
    if (_requested) return;
    _requested = true;
    final authService = context.read<AuthService>();
    final attendance = context.read<AttendanceService>();
    await authService.tryAutoLogin();
    if (authService.userId != null) {
      await attendance.getTodayAttendance(authService.userId!);
      await _fetchMonthAttendance();
    }
  }

  Future<void> _fetchMonthAttendance() async {
    final authService = context.read<AuthService>();
    final attendance = context.read<AttendanceService>();
    final userId = authService.userId;
    if (userId != null) {
      final records = await attendance.getMonthAttendance(
        userId,
        _selectedMonth.year,
        _selectedMonth.month,
      );
      setState(() {
        _monthRecords = records;
        debugPrint('[StaffHomePage][_monthRecords] $_monthRecords');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final attendance = context.watch<AttendanceService>();
    final userId = authService.userId;
    String? checkInTime = attendance.todayAttendance?['check_in_time'];
    String? checkOutTime = attendance.todayAttendance?['check_out_time'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('員工系統'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '手動刷新',
            onPressed: () async {
              debugPrint('[StaffHomePage][refresh] userId: $userId');
              if (userId != null) {
                await attendance.getTodayAttendance(userId);
                await _fetchMonthAttendance();
                debugPrint(
                  '[StaffHomePage][refresh] after getTodayAttendance & getMonthAttendance',
                );
                scaffoldMessengerKey.currentState!.showSnackBar(
                  const SnackBar(content: Text('已手動刷新打卡資料')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '登出',
            onPressed: () async {
              await authService.logout();
              navigatorKey.currentState!.pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text('光悅員工系統', style: TextStyle(fontSize: 20))),
            if (authService.isAdmin) ...[
              ListTile(
                leading: Icon(Icons.admin_panel_settings),
                title: Text('管理員系統'),
                onTap: () {
                  Navigator.of(context).pushNamed('/admin');
                },
              ),
              const Divider(),
            ],
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('登出'),
              onTap: () async {
                await authService.logout();
                navigatorKey.currentState!.pushReplacementNamed('/login');
              },
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            '歡迎，${authService.name ?? '員工'}！',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: Text('今日上班時間：${formatTime(checkInTime)}')),
              ElevatedButton(
                onPressed: () async {
                  if (userId != null) {
                    await attendance.checkIn(userId);
                  }
                },
                child: Text(attendance.hasCheckedIn ? '補上班打卡' : '上班打卡'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: Text('今日下班時間：${formatTime(checkOutTime)}')),
              ElevatedButton(
                onPressed: () async {
                  if (userId != null) {
                    await attendance.checkOut(userId);
                  }
                },
                child: Text(attendance.hasCheckedOut ? '補下班打卡' : '下班打卡'),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (attendance.errorMessage != null)
            Text(
              attendance.errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                child: Text('選擇月份'),
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
                    await _fetchMonthAttendance();
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
                child: Text('匯出Excel'),
                onPressed: () async {
                  final authService = context.read<AuthService>();
                  final employeeName = authService.name ?? '員工';
                  final employeeId = authService.userId ?? '';

                  try {
                    await _excelExportService.exportAttendanceRecords(
                      employeeName: employeeName,
                      employeeId: employeeId,
                      monthRecords: _monthRecords,
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
              constraints: BoxConstraints(maxWidth: 680),
              child: AttendanceCalendarView(
                month: _selectedMonth,
                recordsMap: _monthRecords,
                leaveDaysMap: {},
                holidaysMap: {},
                todayDay:
                    (_selectedMonth.year == DateTime.now().year &&
                        _selectedMonth.month == DateTime.now().month)
                    ? DateTime.now().day
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
