import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/browser_client.dart';

class AttendanceService extends ChangeNotifier {
  /// Flutter Web 必須用 BrowserClient 才能送 Cookie
  final BrowserClient _client = BrowserClient()..withCredentials = true;

  static const String baseUrl =
      'https://employeeservice.coseligtest.workers.dev';

  Map<String, dynamic>? todayAttendance;
  String? errorMessage;
  
  // 月度打卡記錄快取
  Map<int, dynamic> currentMonthRecords = {};
  DateTime? currentMonthDate;
  String? currentMonthUserId;

  // 正在上班的員工列表快取
  List<Map<String, dynamic>> workingStaffList = [];
  bool isLoadingWorkingStaff = false;

  // 動態時段管理
  List<String> dynamicPeriods = ['period1'];
  final Map<int, String> periodNames = {1: '上午班', 2: '下午班', 3: '晚班'};

  /// 取得指定月份的打卡記錄
  Future<Map<int, dynamic>> getMonthAttendance(
    String userId,
    int year,
    int month,
  ) async {
    final url =
        '$baseUrl/api/attendance/month?user_id=$userId&year=$year&month=$month';
    final res = await _client.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode == 200) {
      // 假設 API 回傳格式: { "records": [ { "day": 1, "period1_check_in_time": ..., ... }, ... ] }
      final data = jsonDecode(res.body);
      final records = data['records'] as List<dynamic>? ?? [];
      final Map<int, dynamic> recordsMap = {};
      for (final record in records) {
        if (record is Map<String, dynamic> && record['day'] != null) {
          final day = record['day'] as int;
          recordsMap[day] = record;
        }
      }
      return recordsMap;
    } else {
      return {};
    }
  }

  /// 取得並快取月份打卡記錄（帶狀態管理）
  Future<void> fetchAndCacheMonthAttendance(
    String userId,
    DateTime month,
  ) async {
    final records = await getMonthAttendance(userId, month.year, month.month);
    currentMonthRecords = records;
    currentMonthDate = month;
    currentMonthUserId = userId;
    notifyListeners();
  }

  /// 獲取正在上班的員工列表
  Future<List<Map<String, dynamic>>> getWorkingStaff() async {
    try {
      final res = await _client.get(
        Uri.parse('$baseUrl/api/working-staff'),
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final workingStaff = data['working_staff'] as List<dynamic>? ?? [];
        return workingStaff.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception('獲取正在工作的員工列表失敗: ${res.body}');
      }
    } catch (e) {
      print('獲取正在工作的員工列表錯誤: $e');
      rethrow;
    }
  }

  /// 獲取並快取正在上班的員工列表（帶狀態管理）
  Future<void> fetchAndCacheWorkingStaff() async {
    isLoadingWorkingStaff = true;
    notifyListeners();

    try {
      final workingStaff = await getWorkingStaff();
      workingStaffList = workingStaff
          .map(
            (emp) => {
              'name': emp['name'] ?? '員工',
              'chinese_name': emp['chinese_name'],
              'id': emp['user_id']?.toString() ?? '',
              'check_in_time': emp['check_in_time'],
            },
          )
          .toList();
    } catch (e) {
      workingStaffList = [];
      print('獲取正在上班員工失敗: $e');
    } finally {
      isLoadingWorkingStaff = false;
      notifyListeners();
    }
  }

  /// 上班打卡
  Future<bool> checkIn(String userId, {String period = 'morning'}) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/attendance/check-in'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'period': period}),
    );

    if (res.statusCode == 200) {
      await getTodayAttendance(userId);
      return true;
    } else {
      errorMessage = jsonDecode(res.body)['error'];
      notifyListeners();
      return false;
    }
  }

  /// 下班打卡
  Future<bool> checkOut(String userId, {String period = 'morning'}) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/attendance/check-out'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'period': period}),
    );

    if (res.statusCode == 200) {
      await getTodayAttendance(userId);
      return true;
    } else {
      errorMessage = jsonDecode(res.body)['error'];
      notifyListeners();
      return false;
    }
  }

  /// 取得今天打卡狀態（⚠️ GET）
  Future<void> getTodayAttendance(String userId) async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/attendance/today?user_id=$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (res.statusCode == 200) {
      todayAttendance = jsonDecode(res.body);
      errorMessage = null;
      notifyListeners();
    } else {
      throw Exception('Failed to load attendance data');
    }
  }

  bool get hasCheckedIn => todayAttendance?['check_in_time'] != null;

  bool get hasCheckedOut => todayAttendance?['check_out_time'] != null;

  // 新增時段打卡檢查
  bool get hasCheckedInMorning =>
      todayAttendance?['morning_check_in_time'] != null;

  bool get hasCheckedOutMorning =>
      todayAttendance?['morning_check_out_time'] != null;

  bool get hasCheckedInAfternoon =>
      todayAttendance?['afternoon_check_in_time'] != null;

  bool get hasCheckedOutAfternoon =>
      todayAttendance?['afternoon_check_out_time'] != null;

  /// 清空打卡數據
  void clear() {
    todayAttendance = null;
    errorMessage = null;
    notifyListeners();
  }

  /// 管理員補打卡
  Future<void> manualPunch(
    String employeeId,
    DateTime date,
    Map<String, Map<String, String?>> periods,
  ) async {
    final url = '$baseUrl/api/manual-punch';
    final body = {
      'employee_id': employeeId,
      'date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'periods': periods,
    };
    final res = await _client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      // 成功
    } else {
      throw Exception('補打卡失敗: ${res.body}');
    }
  }

  /// 更新時段名稱
  Future<bool> updatePeriodName(String oldPeriod, String newPeriod) async {
    debugPrint(
      '[AttendanceService][updatePeriodName] oldPeriod: $oldPeriod, newPeriod: $newPeriod',
    );

    final res = await _client.put(
      Uri.parse('$baseUrl/api/attendance/period'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'oldPeriod': oldPeriod, 'newPeriod': newPeriod}),
    );

    debugPrint(
      '[AttendanceService][updatePeriodName] statusCode: ${res.statusCode}, response: ${res.body}',
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      debugPrint(
        '[AttendanceService][updatePeriodName] success: ${data['message']}',
      );
      return true;
    } else {
      final errorData = jsonDecode(res.body);
      errorMessage = errorData['error'] ?? '更新失敗';
      notifyListeners();
      return false;
    }
  }

  /// 更新動態時段列表（從今天的考勤數據中發現所有時段）
  void updateDynamicPeriods() {
    if (todayAttendance == null) {
      dynamicPeriods = ['period1'];
      notifyListeners();
      return;
    }

    // 收集所有時段（包含動態時段名稱）
    final Set<String> allPeriods = {};
    todayAttendance!.forEach((key, value) {
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
    if (allPeriods.isEmpty) {
      dynamicPeriods = ['period1']; // 預設至少有一個時段
    } else {
      dynamicPeriods = allPeriods.toList()
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
    }
    notifyListeners();
  }

  /// 新增時段
  Future<bool> addPeriod(String periodName) async {
    final newPeriodIndex = dynamicPeriods.length + 1;
    final newPeriod = 'period$newPeriodIndex';

    // 更新本地狀態
    periodNames[newPeriodIndex] = periodName;
    dynamicPeriods.add(newPeriod);
    notifyListeners();

    // TODO: 如果需要後端支持，可以在這裡調用 API
    return true;
  }

  /// 獲取指定日期所有員工的考勤記錄（管理員用）
  Future<List<Map<String, dynamic>>> fetchAllEmployeesAttendanceForDate(
    DateTime date,
  ) async {
    final url =
        '$baseUrl/api/attendance/all-employees?date=${date.toIso8601String().split('T')[0]}';
    final res = await _client.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final records = data['records'] as List<dynamic>? ?? [];
      return records.map((record) => record as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to fetch all employees attendance');
    }
  }
}
