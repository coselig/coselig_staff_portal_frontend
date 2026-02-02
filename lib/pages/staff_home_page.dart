import 'package:universal_html/html.dart' as html;
import 'package:coselig_staff_portal/constants/app_constants.dart';
import 'package:coselig_staff_portal/services/attendance_service.dart';
import 'package:coselig_staff_portal/widgets/app_drawer.dart';
import 'package:coselig_staff_portal/widgets/working_staff_card.dart';
import 'package:coselig_staff_portal/widgets/attendance_viewer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:coselig_staff_portal/widgets/attendance_punch_card.dart';
import 'package:coselig_staff_portal/main.dart';

class StaffHomePage extends StatefulWidget {
  const StaffHomePage({super.key});

  @override
  State<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends State<StaffHomePage> {
  bool _requested = false;

  // 移除本地時段管理方法，改用 AttendanceService

  @override
  void initState() {
    super.initState();
    html.document.title = '員工系統';
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
      attendance.updateDynamicPeriods();
      // await attendance.fetchAndCacheMonthAttendance(
      //   authService.userId!,
      //   _selectedMonth,
      // );
    }
  }

  // 編輯任何時段名稱
  Future<void> _editPeriodNameForAnyPeriod(
    String currentPeriod,
    String currentDisplayName,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: currentDisplayName,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('編輯時段名稱'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('請輸入新的時段名稱：'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: '時段名稱',
                hintText: '例如：HomeAssistant端打卡、上午班、下午班',
                border: OutlineInputBorder(),
              ),
              maxLength: 20,
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
      try {
        // 調用後端 API 更新時段名稱
        final attendanceService = context.read<AttendanceService>();

        final success = await attendanceService.updatePeriodName(
          currentPeriod,
          result,
        );

        if (success) {
          // 如果是 period 格式，也更新本地快取
          if (currentPeriod.startsWith('period')) {
            final num = int.tryParse(currentPeriod.substring(6));
            if (num != null) {
              attendanceService.periodNames[num] = result;
            }
          }

          // 刷新今日打卡資料
          final authService = context.read<AuthService>();
          if (authService.userId != null) {
            await attendanceService.getTodayAttendance(authService.userId!);
            attendanceService.updateDynamicPeriods();
            // 刷新當前月份的資料
            await attendanceService.fetchAndCacheMonthAttendance(
              authService.userId!,
              DateTime.now(),
            );
          }

          scaffoldMessengerKey.currentState!.showSnackBar(
            SnackBar(content: Text('時段名稱已更新為：$result')),
          );
        } else {
          scaffoldMessengerKey.currentState!.showSnackBar(
            SnackBar(
              content: Text('更新失敗：${attendanceService.errorMessage ?? '未知錯誤'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        scaffoldMessengerKey.currentState!.showSnackBar(
          SnackBar(content: Text('更新失敗：$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 通用打卡方法
  Future<void> _performPunch({
    required String? userId,
    required String period,
    required String periodName,
    required bool isCheckIn,
  }) async {
    if (userId == null) return;

    final actionName = isCheckIn ? '上班' : '下班';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$periodName - $actionName打卡'),
        content: Text('確定要進行$actionName打卡嗎？'),
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
      if (isCheckIn) {
        await attendance.checkIn(userId, period: period);
      } else {
        await attendance.checkOut(userId, period: period);
      }
      // 打卡後自動刷新
      await attendance.getTodayAttendance(userId);
      // await attendance.fetchAndCacheMonthAttendance(userId, _selectedMonth);
      scaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(content: Text('$periodName $actionName打卡成功')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final attendance = context.watch<AttendanceService>();
    final userId = authService.userId;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: '開啟選單',
          ),
        ),
        title: Row(
          children: [
            const Text('員工系統'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(77),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppConstants.fullVersion,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.refresh),
        //     tooltip: '手動刷新',
        //     onPressed: () async {
        //       if (userId != null) {
        //         await attendance.getTodayAttendance(userId);
        //         attendance.updateDynamicPeriods();
        //         await attendance.fetchAndCacheMonthAttendance(
        //           userId,
        //           _selectedMonth,
        //         );
        //         scaffoldMessengerKey.currentState!.showSnackBar(
        //           const SnackBar(content: Text('已手動刷新打卡資料')),
        //         );
        //       }
        //     },
        //   ),
        // ],
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const WorkingStaffCard(),
          Text(
            '歡迎，${authService.chineseName ?? authService.name ?? '員工'}！',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
          // 動態時段
          Column(
            children: List.generate(attendance.dynamicPeriods.length, (index) {
              final period = attendance.dynamicPeriods[index];

              // 根據時段名稱決定顯示名稱
              String displayName;
              if (period.startsWith('period')) {
                final num = int.tryParse(period.substring(6));
                displayName = attendance.periodNames[num] ?? '時段$num';
              } else {
                displayName = period; // 直接使用自定義名稱
              }

              final checkInTime =
                  attendance.todayAttendance?['${period}_check_in_time'];
              final checkOutTime =
                  attendance.todayAttendance?['${period}_check_out_time'];

              return AttendancePunchCard(
                period: period,
                displayName: displayName,
                checkInTime: checkInTime,
                checkOutTime: checkOutTime,
                onEditName: () =>
                    _editPeriodNameForAnyPeriod(period, displayName),
                onCheckIn: () => _performPunch(
                  userId: userId,
                  period: period,
                  periodName: displayName,
                  isCheckIn: true,
                ),
                onCheckOut: () => _performPunch(
                  userId: userId,
                  period: period,
                  periodName: displayName,
                  isCheckIn: false,
                ),
              );
            }),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('新增時段'),
            onPressed: () async {
              final attendance = context.read<AttendanceService>();
              final newPeriodIndex = attendance.dynamicPeriods.length + 1;
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
                final success = await attendance.addPeriod(result);
                if (success) {
                  scaffoldMessengerKey.currentState!.showSnackBar(
                    SnackBar(content: Text('已新增時段：$result')),
                  );
                } else {
                  scaffoldMessengerKey.currentState!.showSnackBar(
                    SnackBar(
                      content: Text('新增失敗：${attendance.errorMessage ?? '未知錯誤'}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          SizedBox(height: 16),
          const AttendanceViewer(),
        ],
      ),
    );
  }
}
