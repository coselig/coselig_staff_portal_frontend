import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AttendanceService extends ChangeNotifier {
  // Debug print
  void debugPrintAttendance([String tag = '']) {
    print(
      '[AttendanceService][$tag] todayAttendance: '
      '${todayAttendance != null ? todayAttendance.toString() : 'null'}',
    );
  }
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
    print(
      '[AttendanceService][getMonthAttendance] userId: $userId, year: $year, month: $month',
    );
    final res = await http.get(
      Uri.parse(
        '$baseUrl/api/attendance/month?user_id=$userId&year=$year&month=$month',
      ),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode == 200) {
      // 假設 API 回傳格式: { "records": [ { "day": 1, ... }, ... ] }
      final data = jsonDecode(res.body);
      final records = data['records'] as List<dynamic>? ?? [];
      final Map<int, dynamic> recordsMap = {};
      for (final record in records) {
        if (record is Map<String, dynamic> && record['day'] != null) {
          recordsMap[record['day']] = record;
        }
      }
      return recordsMap;
    } else {
      print('[AttendanceService][getMonthAttendance] error: ${res.body}');
      return {};
    }
  }

  /// 上班打卡
  Future<bool> checkIn(String userId) async {
    print('[AttendanceService][checkIn] userId: $userId');
    final res = await http.post(
      Uri.parse('$baseUrl/api/attendance/check-in'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
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
  Future<bool> checkOut(String userId) async {
    print('[AttendanceService][checkOut] userId: $userId');
    final res = await http.post(
      Uri.parse('$baseUrl/api/attendance/check-out'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
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
    print('[AttendanceService][getTodayAttendance] userId: $userId');
    final res = await http.get(
      Uri.parse('$baseUrl/api/attendance/today?user_id=$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (res.statusCode == 200) {
      todayAttendance = jsonDecode(res.body);
      errorMessage = null;
      debugPrintAttendance('getTodayAttendance');
      notifyListeners();
    } else {
      throw Exception('Failed to load attendance data');
    }
  }

  bool get hasCheckedIn =>
      todayAttendance?['check_in_time'] != null;

  bool get hasCheckedOut =>
      todayAttendance?['check_out_time'] != null;
}
