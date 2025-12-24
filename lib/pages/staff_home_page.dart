import 'package:coselig_staff_portal/services/holiday_service.dart';
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
  Map<int, dynamic> _holidaysMap = {};

  Future<void> _fetchHolidays() async {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    try {
      final holidayService = HolidayService();
      final holidays = await holidayService.fetchTaiwanHolidays(year);
      debugPrint('[Holiday] $year年取得假日數量: ${holidays.length}');
      final Map<int, dynamic> map = {};
      for (final h in holidays) {
        final date = DateTime.parse(h.date);
        if (date.month == month) {
          map[date.day] = h.name;
          debugPrint('[Holiday] ${h.date} ${h.name} 加入本月假日');
        }
      }
      debugPrint('[Holiday] $month月假日map: $map');
      setState(() {
        _holidaysMap = map;
      });
    } catch (e) {
      debugPrint('[Holiday] 取得假日失敗: $e');
      setState(() {
        _holidaysMap = {};
      });
    }
  }
  List<Map<String, dynamic>> _workingStaff = [];
  bool _loadingWorkingStaff = false;

  Future<void> _fetchWorkingStaff() async {
    setState(() => _loadingWorkingStaff = true);
    try {
      final authService = context.read<AuthService>();
      final attendance = context.read<AttendanceService>();
      final employees = await authService.getEmployees();
      List<Map<String, dynamic>> working = [];
      for (final emp in employees) {
        final empId = emp['id']?.toString();
        if (empId == null) continue;
        await attendance.getTodayAttendance(empId);
        final today = attendance.todayAttendance;
        if (today != null &&
            today['check_in_time'] != null &&
            today['check_out_time'] == null) {
          working.add({
            'name': emp['name'] ?? '員工',
            'id': empId,
            'check_in_time': today['check_in_time'],
          });
        }
      }
      setState(() {
        _workingStaff = working;
      });
    } catch (e) {
      setState(() {
        _workingStaff = [];
      });
    } finally {
      setState(() => _loadingWorkingStaff = false);
    }
  }
  bool _requested = false;
  DateTime _selectedMonth = DateTime.now();
  Map<int, dynamic> _monthRecords = {};
  final ExcelExportService _excelExportService = ExcelExportService();

  @override
  void initState() {
    super.initState();
    Future.microtask(_initUserAndAttendance);
    Future.microtask(_fetchWorkingStaff);
    Future.microtask(_fetchHolidays);
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
      await _fetchHolidays();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ...existing code...
    Widget workingStaffBlock = Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  '目前正在上班的員工',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh),
                  tooltip: '刷新',
                  onPressed: _loadingWorkingStaff ? null : _fetchWorkingStaff,
                ),
              ],
            ),
            _loadingWorkingStaff
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _workingStaff.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      '目前沒有員工正在上班',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : Column(
                    children: _workingStaff
                        .map(
                          (emp) => ListTile(
                            leading: Icon(Icons.person, color: Colors.blue),
                            title: Text(emp['name'] ?? ''),
                            subtitle: Text(
                              '上班時間：${formatTime(emp['check_in_time'])}',
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ],
        ),
      ),
    );
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
          workingStaffBlock,
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
                onPressed: attendance.hasCheckedIn
                    ? null
                    : () async {
                        if (userId != null) {
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('上班打卡'),
                              content: Text('是否要打卡？'),
                              actions: [
                                TextButton(
                                  child: Text('取消'),
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                ),
                                ElevatedButton(
                                  child: Text('確定'),
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                ),
                              ],
                            ),
                          );
                          if (result == true) {
                            await attendance.checkIn(userId);
                            // 打卡後自動刷新
                            await attendance.getTodayAttendance(userId);
                            await _fetchMonthAttendance();
                          }
                        }
                      },
                child: Text(attendance.hasCheckedIn ? '已上班打卡' : '上班打卡'),
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
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          attendance.hasCheckedOut ? '補下班打卡' : '下班打卡',
                        ),
                        content: Text(
                          '是否要${attendance.hasCheckedOut ? '重新' : ''}打卡？',
                        ),
                        actions: [
                          TextButton(
                            child: Text('取消'),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                          ElevatedButton(
                            child: Text('確定'),
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ],
                      ),
                    );
                    if (result == true) {
                      await attendance.checkOut(userId);
                      // 打卡後自動刷新
                      await attendance.getTodayAttendance(userId);
                      await _fetchMonthAttendance();
                    }
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
                    await _fetchHolidays();
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
                holidaysMap: _holidaysMap,
                todayDay:
                    (_selectedMonth.year == DateTime.now().year &&
                        _selectedMonth.month == DateTime.now().month)
                    ? DateTime.now().day
                    : null,
                // debug
                // ignore: avoid_print
                // ignore: avoid_print
                // ignore: avoid_print
                // ignore: avoid_print
              ),
            ),
          ),
        ],
      ),
    );
  }
}
