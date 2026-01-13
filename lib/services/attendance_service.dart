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
}
