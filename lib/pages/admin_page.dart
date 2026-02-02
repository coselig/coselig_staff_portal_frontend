import 'package:universal_html/html.dart' as html;
import 'package:coselig_staff_portal/services/attendance_service.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:coselig_staff_portal/widgets/buttons.dart';
import 'package:coselig_staff_portal/widgets/month_year_picker.dart';
import 'package:coselig_staff_portal/widgets/attendance_calendar_view.dart';
import 'package:coselig_staff_portal/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/main.dart';
import 'package:coselig_staff_portal/services/attendance_excel_export_service.dart';
import 'package:coselig_staff_portal/widgets/manual_punch_dialog.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final ExcelExportService _excelExportService = ExcelExportService();
  DateTime _selectedMonth = DateTime.now();
  Map<String, Map<String, dynamic>> _allEmployeesRecords = {};
  bool _isLoading = false;
  List<Map<String, dynamic>> _employees = [];
  String? _selectedEmployeeId;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    html.document.title = '管理員系統';
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    try {
      final authService = context.read<AuthService>();
      final employees = await authService.getEmployees();
      setState(() {
        _employees = employees;
        if (employees.isNotEmpty) {
          _selectedEmployeeId = employees.first['id']?.toString();
        }
      });
    } catch (e) {
      scaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(content: Text('載入員工列表失敗: $e')),
      );
    }
  }

  Future<void> _fetchEmployeeAttendance() async {
    if (_selectedEmployeeId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final attendance = context.read<AttendanceService>();
      final records = await attendance.getMonthAttendance(
        _selectedEmployeeId!,
        _selectedMonth.year,
        _selectedMonth.month,
      );

      setState(() {
        _allEmployeesRecords = {
          _selectedEmployeeId!: {
            'employee': _employees.firstWhere(
              (e) => e['id'].toString() == _selectedEmployeeId,
              orElse: () => <String, dynamic>{},
            ),
            'records': records,
          }
        };
      });
    } catch (e) {
      scaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(content: Text('載入打卡記錄失敗: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理員系統'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: '回首頁',
          onPressed: () {
            navigatorKey.currentState!.pushReplacementNamed('/home');
          },
        ),
        actions: [
          registerGenerateButton(),
          logoutButton(context),
        ],
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Checkbox(
                  value: _showInactive,
                  onChanged: (value) {
                    setState(() {
                      _showInactive = value ?? false;
                    });
                  },
                ),
                const Text('顯示離職員工'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedEmployeeId,
                    decoration: const InputDecoration(
                      labelText: '選擇員工',
                      border: OutlineInputBorder(),
                    ),
                    items: _employees
                        .where((employee) {
                          // 過濾離職員工
                          if (!_showInactive) {
                            final isActive = employee['is_active'];
                            // is_active 可能是 int (0/1) 或 bool
                            if (isActive == 0 || isActive == false) {
                              return false;
                            }
                          }
                          return true;
                        })
                        .map((employee) {
                      final role = employee['role'] ?? 'employee';
                      final chineseName = employee['chinese_name'];
                      final englishName = employee['name'] ?? '未知員工';
                      final displayName =
                          chineseName != null && chineseName.isNotEmpty
                          ? chineseName
                          : englishName;
                      final roleText = role == 'admin' ? ' (管理員)' : '';
                          final isActive = employee['is_active'];
                          final statusText =
                              (isActive == 0 || isActive == false)
                              ? ' (離職)'
                              : '';
                      
                      return DropdownMenuItem<String>(
                        value: employee['id']?.toString(),
                            child: Text('$displayName$roleText$statusText'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedEmployeeId = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
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
                    }
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    await _fetchEmployeeAttendance();
                  },
                  child: Text('查詢'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_allEmployeesRecords.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.download),
                  label: Text('匯出Excel'),
                  onPressed: () async {
                    final userId = _allEmployeesRecords.keys.first;
                    final employeeData = _allEmployeesRecords[userId]!;
                    final employee =
                        employeeData['employee'] as Map<String, dynamic>;
                    final records = Map<int, dynamic>.from(
                      employeeData['records'] as Map,
                    );
                    final employeeName =
                        employee['chinese_name'] ?? employee['name'] ?? '員工';
                    final employeeId = employee['id']?.toString() ?? userId;
                    try {
                      await _excelExportService.exportAttendanceRecords(
                        employeeName: employeeName,
                        employeeId: employeeId,
                        monthRecords: records,
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
              ),
            Text(
              '員工打卡總覽 - ${_selectedMonth.year}年${_selectedMonth.month}月',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _allEmployeesRecords.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                '請選擇員工並點擊查詢',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _allEmployeesRecords.length,
                          itemBuilder: (context, index) {
                            final userId = _allEmployeesRecords.keys.elementAt(index);
                            final employeeData = _allEmployeesRecords[userId]!;
                            final employee = employeeData['employee'] as Map<String, dynamic>;
                        final records = Map<int, dynamic>.from(
                          employeeData['records'] as Map,
                        );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      employee.isNotEmpty 
                                      ? '${employee['chinese_name'] ?? employee['name'] ?? '未知員工'} (${employee['email'] ?? ''})'
                                        : '未知員工 ($userId)',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text('員工ID: $userId'),
                                    const SizedBox(height: 16),
                                    Align(
                                      alignment: Alignment.center,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(maxWidth: 680),
                                        child: AttendanceCalendarView(
                                          month: _selectedMonth,
                                          recordsMap: records,
                                      leaveDaysMap: const {},
                                          todayDay: null,
                                      onManualPunch: (day, record) async {
                                        final date = DateTime(
                                          _selectedMonth.year,
                                          _selectedMonth.month,
                                          day,
                                        );
                                        // 準備 periodsData
                                        final Map<String, Map<String, String?>>
                                        periodsData = {};
                                        if (record is Map<String, dynamic>) {
                                          final Set<String> periods = {};
                                          record.forEach((key, value) {
                                            if (key.startsWith('period')) {
                                              final parts = key.split('_');
                                              if (parts.length >= 2 &&
                                                  parts[0].startsWith(
                                                    'period',
                                                  )) {
                                                periods.add(parts[0]);
                                              }
                                            }
                                          });
                                          for (final period in periods) {
                                            periodsData[period] = {
                                              'check_in':
                                                  record['${period}_check_in_time'],
                                              'check_out':
                                                  record['${period}_check_out_time'],
                                            };
                                          }
                                        }
                                        // 如果沒有任何 period，添加 period1
                                        if (periodsData.isEmpty) {
                                          periodsData['period1'] = {
                                            'check_in': null,
                                            'check_out': null,
                                          };
                                        }
                                        await showDialog(
                                          context: context,
                                          builder: (context) => ManualPunchDialog(
                                            employeeName:
                                                employee['chinese_name'] ??
                                                employee['name'] ??
                                                '員工',
                                            date: date,
                                            periodsData: periodsData,
                                            onSubmit: (periods) async {
                                              try {
                                                final attendance = context
                                                    .read<AttendanceService>();
                                                await attendance.manualPunch(
                                                  _selectedEmployeeId!,
                                                  date,
                                                  periods,
                                                );
                                                scaffoldMessengerKey
                                                    .currentState!
                                                    .showSnackBar(
                                                      const SnackBar(
                                                        content: Text('補打卡成功'),
                                                      ),
                                                    );
                                                // 重新載入數據
                                                await _fetchEmployeeAttendance();
                                              } catch (e) {
                                                scaffoldMessengerKey
                                                    .currentState!
                                                    .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          '補打卡失敗: $e',
                                                        ),
                                                      ),
                                                    );
                                              }
                                            },
                                          ),
                                        );
                                      },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}