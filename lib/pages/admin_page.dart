import 'package:coselig_staff_portal/services/attendance_service.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:coselig_staff_portal/widgets/month_year_picker.dart';
import 'package:coselig_staff_portal/widgets/attendance_calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/main.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  DateTime _selectedMonth = DateTime.now();
  Map<String, Map<String, dynamic>> _allEmployeesRecords = {};
  bool _isLoading = false;
  List<Map<String, dynamic>> _employees = [];
  String? _selectedEmployeeId;

  @override
  void initState() {
    super.initState();
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
    final authService = context.read<AuthService>();

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedEmployeeId,
                    decoration: const InputDecoration(
                      labelText: '選擇員工',
                      border: OutlineInputBorder(),
                    ),
                    items: _employees.map((employee) {
                      return DropdownMenuItem<String>(
                        value: employee['id']?.toString(),
                        child: Text(employee['name'] ?? '未知員工'),
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
                  child: Text('查詢'),
                  onPressed: _fetchEmployeeAttendance,
                ),
              ],
            ),
            const SizedBox(height: 20),
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
                            final records = employeeData['records'] as Map<int, dynamic>;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      employee.isNotEmpty 
                                        ? '${employee['name'] ?? '未知員工'} (${employee['email'] ?? ''})'
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
                                          holidaysMap: const {},
                                          todayDay: null,
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