import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/browser_client.dart';

class AttendanceService extends ChangeNotifier {
  /// Flutter Web 必須用 BrowserClient 才能送 Cookie
  final BrowserClient _client = BrowserClient()..withCredentials = true;
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

/// 取得所有員工的打卡記錄（管理員功能）
  Future<Map<String, Map<int, dynamic>>> getAllEmployeesAttendance(
    int year,
    int month,
  ) async {
    print(
      '[AttendanceService][getAllEmployeesAttendance] year: $year, month: $month',
    );

    // TODO: 實現管理員 API 來獲取所有員工的打卡記錄
    // 目前返回空數據，顯示功能尚未實現的消息
    print('[AttendanceService][getAllEmployeesAttendance] 管理員功能尚未實現，返回空數據');

    return {};
  }

  /// 取得指定月份的打卡記錄
  Future<Map<int, dynamic>> getMonthAttendance(
    String userId,
    int year,
    int month,
  ) async {
    debugPrint(
      '[AttendanceService][getMonthAttendance] userId: $userId, year: $year, month: $month',
    );
    final url =
        '$baseUrl/api/attendance/month?user_id=$userId&year=$year&month=$month';
    debugPrint('[AttendanceService][getMonthAttendance] url: $url');
    final res = await _client.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );
    debugPrint(
      '[AttendanceService][getMonthAttendance] statusCode: ${res.statusCode}',
    );
    debugPrint(
      '[AttendanceService][getMonthAttendance] response body: ${res.body}',
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
      debugPrint(
        '[AttendanceService][getMonthAttendance] recordsMap: $recordsMap',
      );
      return recordsMap;
    } else {
      debugPrint('[AttendanceService][getMonthAttendance] error: ${res.body}');
      return {};
    }
  }

  /// 上班打卡
  Future<bool> checkIn(String userId) async {
    debugPrint('[AttendanceService][checkIn] userId: $userId');
    final res = await _client.post(
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
    final res = await _client.post(
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
    final res = await _client.get(
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
