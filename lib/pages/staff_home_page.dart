import 'package:universal_html/html.dart' as html;
import 'package:coselig_staff_portal/services/holiday_service.dart';
import 'package:coselig_staff_portal/utils/time_utils.dart';
import 'package:coselig_staff_portal/services/attendance_service.dart';
import 'package:coselig_staff_portal/widgets/buttons.dart';
import 'package:coselig_staff_portal/widgets/theme_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:coselig_staff_portal/widgets/month_year_picker.dart';
import 'package:coselig_staff_portal/widgets/attendance_calendar_view.dart';
import 'package:coselig_staff_portal/main.dart';
import 'package:coselig_staff_portal/services/attendance_excel_export_service.dart';

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
      final workingStaff = await authService.getWorkingStaff();
      setState(() {
        _workingStaff = workingStaff
            .map(
              (emp) => {
                'name': emp['name'] ?? '員工',
                'id': emp['user_id']?.toString() ?? '',
                'check_in_time': emp['check_in_time'],
              },
            )
            .toList();
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

  int periodCount = 1; // 動態時段數量
  List<String> _dynamicPeriods = ['period1']; // 動態時段列表
  final Map<int, String> _periodNames = {
    1: '上午班',
    2: '下午班',
    3: '晚班',
  }; // 時段自定義名稱

  void _updatePeriodCount() {
    final attendance = context.read<AttendanceService>();
    final today = attendance.todayAttendance;
    if (today == null) {
      setState(() => periodCount = 1);
      return;
    }
    
    // 收集所有時段（包含動態時段名稱）
    final Set<String> allPeriods = {};
    today.forEach((key, value) {
      if (key.endsWith('_check_in_time') || key.endsWith('_check_out_time')) {
        String periodName;
        if (key.endsWith('_check_in_time')) {
          periodName = key.substring(0, key.length - '_check_in_time'.length);
        } else {
          periodName = key.substring(0, key.length - '_check_out_time'.length);
        }
        if (periodName.isNotEmpty) {
          allPeriods.add(periodName);
        }
      }
    });
    
    // 更新動態時段列表
    setState(() {
      if (allPeriods.isEmpty) {
        _dynamicPeriods = ['period1']; // 預設至少有一個時段
        periodCount = 1;
      } else {
        _dynamicPeriods = allPeriods.toList()
          ..sort((a, b) {
            // 優先顯示 period1, period2 格式的時段
            final aPeriod = a.startsWith('period');
            final bPeriod = b.startsWith('period');
            if (aPeriod && !bPeriod) return -1;
            if (!aPeriod && bPeriod) return 1;
            if (aPeriod && bPeriod) {
              final aNum = int.tryParse(a.substring(6)) ?? 999;
              final bNum = int.tryParse(b.substring(6)) ?? 999;
              return aNum.compareTo(bNum);
            }
            return a.compareTo(b);
          });
        periodCount = _dynamicPeriods.length;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    html.document.title = '員工系統';
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
      _updatePeriodCount();
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

  // 編輯時段名稱
  Future<void> _editPeriodName(int periodIndex) async {
    final TextEditingController controller = TextEditingController(
      text: _periodNames[periodIndex] ?? '時段$periodIndex',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('編輯時段名稱'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('請輸入第 $periodIndex 個時段的名稱：'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: '時段名稱',
                hintText: '例如：上午班、下午班、晚班',
                border: OutlineInputBorder(),
              ),
              maxLength: 10,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('取消'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text('確定'),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.of(context).pop(newName);
              }
            },
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _periodNames[periodIndex] = result;
      });
      scaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(content: Text('時段名稱已更新為：$result')),
      );
    }
  }

  // 上班打卡
  Future<void> _performCheckIn(
    String? userId,
    String period,
    String periodName,
  ) async {
    if (userId == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$periodName - 上班打卡'),
        content: Text('確定要進行上班打卡嗎？'),
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
      final attendance = context.read<AttendanceService>();
      await attendance.checkIn(userId, period: period);
      // 打卡後自動刷新
      await attendance.getTodayAttendance(userId);
      await _fetchMonthAttendance();
      scaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(content: Text('$periodName 上班打卡成功')),
      );
    }
  }

  // 下班打卡
  Future<void> _performCheckOut(
    String? userId,
    String period,
    String periodName,
  ) async {
    if (userId == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$periodName - 下班打卡'),
        content: Text('確定要進行下班打卡嗎？'),
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
      final attendance = context.read<AttendanceService>();
      await attendance.checkOut(userId, period: period);
      // 打卡後自動刷新
      await attendance.getTodayAttendance(userId);
      await _fetchMonthAttendance();
      scaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(content: Text('$periodName 下班打卡成功')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
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
                _updatePeriodCount();
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
          ThemeToggleSwitch(),
          logoutButton(context),
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
                  navigatorKey.currentState!.pushNamed('/admin');
                },
              ),
              const Divider(),
            ],
            ListTile(
              leading: Icon(Icons.build),
              title: Text('裝置註冊表生成器'),
              onTap: () {
                navigatorKey.currentState!.pushNamed('/discovery_generate');
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('登出'),
              onTap: () async {
                final attendance = context.read<AttendanceService>();
                attendance.clear();
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
          // 動態時段
          Column(
            children: List.generate(_dynamicPeriods.length, (index) {
              final period = _dynamicPeriods[index];
              final periodIndex = index + 1;

              // 根據時段名稱決定顯示名稱
              String displayName;
              if (period.startsWith('period')) {
                final num = int.tryParse(period.substring(6));
                displayName = _periodNames[num] ?? '時段$num';
              } else {
                displayName = period; // 直接使用自定義名稱
              }

              final checkInTime =
                  attendance.todayAttendance?['${period}_check_in_time'];
              final checkOutTime =
                  attendance.todayAttendance?['${period}_check_out_time'];
              final hasCheckedIn = checkInTime != null;
              final hasCheckedOut = checkOutTime != null;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 時段名稱編輯行
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // 只有 period 格式的才能編輯名稱
                          if (period.startsWith('period'))
                            IconButton(
                              icon: Icon(Icons.edit, size: 20),
                              tooltip: '編輯時段名稱',
                              onPressed: () => _editPeriodName(periodIndex),
                            ),
                        ],
                      ),
                      SizedBox(height: 8),
                      // 打卡狀態和按鈕
                      if (hasCheckedIn && hasCheckedOut)
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                '${formatTime(checkInTime)} ~ ${formatTime(checkOutTime)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (hasCheckedIn)
                        // 下班打卡
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.login, color: Theme.of(context).colorScheme.primary),
                                    SizedBox(width: 8),
                                    Text(
                                      '上班時間：${formatTime(checkInTime)}',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            ElevatedButton.icon(
                              icon: Icon(Icons.logout),
                              label: Text('下班打卡'),
                              onPressed: () =>
                                  _performCheckOut(userId, period, displayName),
                            ),
                          ],
                        )
                      else
                        // 上班打卡
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.schedule, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    SizedBox(width: 8),
                                    Text(
                                      '尚未打卡',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            ElevatedButton.icon(
                              icon: Icon(Icons.login),
                              label: Text('上班打卡'),
                              onPressed: () =>
                                  _performCheckIn(userId, period, displayName),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('新增時段'),
            onPressed: () async {
              final newPeriodIndex = periodCount + 1;
              final TextEditingController controller = TextEditingController(
                text: '時段$newPeriodIndex',
              );

              final result = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('新增時段'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('請為新時段命名：'),
                      SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: '時段名稱',
                          hintText: '例如：上午班、下午班、晚班',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 10,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: Text('取消'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    ElevatedButton(
                      child: Text('確定'),
                      onPressed: () {
                        final newName = controller.text.trim();
                        if (newName.isNotEmpty) {
                          Navigator.of(context).pop(newName);
                        }
                      },
                    ),
                  ],
                ),
              );

              if (result != null && result.isNotEmpty) {
                setState(() {
                  periodCount++;
                  _periodNames[newPeriodIndex] = result;
                });
                scaffoldMessengerKey.currentState!.showSnackBar(
                  SnackBar(content: Text('已新增時段：$result')),
                );
              }
            },
          ),
          SizedBox(height: 16),
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
                periodNames: _periodNames,
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
