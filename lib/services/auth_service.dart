import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/browser_client.dart';

class AuthService extends ChangeNotifier {
  /// ⚠️ Flutter Web 必須用 BrowserClient 才能送 / 收 Cookie
  final BrowserClient _client = BrowserClient()..withCredentials = true;

  static const String baseUrl =
      'https://employeeservice.coseligtest.workers.dev';

  String? name;
  String? chineseName;
  String? email;
  String? role;
  String? userId;
  bool isLoading = false;
  String message = '';

  /// 是否已登入
  bool get isLoggedIn => name != null;

  /// 是否為管理員
  bool get isAdmin => role == 'admin';

  /* ========================
   * 獲取員工列表（管理員功能）
   * ======================== */
  Future<List<Map<String, dynamic>>> getEmployees() async {
    try {
      final res = await _client.get(
        Uri.parse('$baseUrl/api/employees'),
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final employees = data['employees'] as List<dynamic>? ?? [];
        return employees.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception('獲取員工列表失敗: ${res.body}');
      }
    } catch (e) {
      print('獲取員工列表錯誤: $e');
      rethrow;
    }
  }

  /* ========================
   * 獲取正在工作的員工列表
   * ======================== */
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

  /* ========================
   * 自動登入（讀取 session）
   * ======================== */
  Future<void> tryAutoLogin() async {
    isLoading = true;
    notifyListeners();

    try {
      final res = await _client.get(
        Uri.parse('$baseUrl/api/me'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['user'] != null) {
        name = data['user']['name'];
        chineseName = data['user']['chinese_name'];
        chineseName = data['user']['chinese_name'];
        email = data['user']['email'];
        role = data['user']['role'];
        userId = data['user']['id']?.toString();
        message = '自動登入成功';
      } else {
        _clearUser();
        message = '尚未登入';
      }
    } catch (e) {
      _clearUser();
      message = '自動登入失敗: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  /* =========
   * 登入
   * ========= */
  Future<bool> login(String email, String password) async {
    isLoading = true;
    message = '正在登入...';
    notifyListeners();

    try {
      // 支援 email 或 name 登入
      Map<String, dynamic> loginBody;
      if (email.contains('@')) {
        loginBody = {'email': email, 'password': password};
      } else {
        loginBody = {'name': email, 'password': password};
      }
      final res = await _client.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginBody),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['user'] != null) {
        name = data['user']['name'];
        this.email = data['user']['email'];
        role = data['user']['role'];
        userId = data['user']['id']?.toString();
        message = '登入成功';
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        _clearUser();
        message = data['error'] ?? '登入失敗';
      }
    } catch (e) {
      message = '請求失敗: $e';
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  /* =========
   * 註冊
   * ========= */
  Future<bool> register(String name, String email, String password) async {
    isLoading = true;
    message = '註冊中...';
    notifyListeners();

    try {
      final res = await _client.post(
        Uri.parse('$baseUrl/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': 'employee',
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 201) {
        message = '註冊成功，請登入';
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        message = data['error'] ?? '註冊失敗';
      }
    } catch (e) {
      message = '請求失敗: $e';
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  /* =========
   * 登出
   * ========= */
  Future<void> logout() async {
    isLoading = true;
    notifyListeners();

    try {
      await _client.post(
        Uri.parse('$baseUrl/api/logout'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (_) {}

    _clearUser();
    message = '已登出';
    isLoading = false;
    notifyListeners();
  }

  /* =========
   * 工具
   * ========= */
  void _clearUser() {
    name = null;
    chineseName = null;
    email = null;
    role = null;
    userId = null;
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
