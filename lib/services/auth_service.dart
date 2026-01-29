import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/browser_client.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  /// ⚠️ Flutter Web 必須用 BrowserClient 才能送 / 收 Cookie
  final BrowserClient _client = BrowserClient()..withCredentials = true;

  static const String baseUrl =
      'https://employeeservice.coseligtest.workers.dev';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '120974904090-7i1lmj710vvvfjaf71du6tdb4sun8i8q.apps.googleusercontent.com',
  );

  String? name;
  String? chineseName;
  String? email;
  String? role;
  String? userId;
  String? themeMode; // 新增主題模式欄位
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
        themeMode = data['user']['theme_mode']; // 新增主題模式
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
   * Google 登入
   * ========= */
  Future<bool> googleLogin() async {
    isLoading = true;
    message = '正在登入 Google...';
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        message = 'Google 登入取消';
        isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        message = '獲取 Google ID Token 失敗';
        isLoading = false;
        notifyListeners();
        return false;
      }

      // 發送 ID Token 到後端驗證
      final res = await _client.post(
        Uri.parse('$baseUrl/api/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['user'] != null) {
        name = data['user']['name'];
        chineseName = data['user']['chinese_name'];
        email = data['user']['email'];
        role = data['user']['role'];
        userId = data['user']['id']?.toString();
        themeMode = data['user']['theme_mode'];
        message = 'Google 登入成功';
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        _clearUser();
        message = data['error'] ?? 'Google 登入失敗';
      }
    } catch (e) {
      message = 'Google 登入請求失敗: $e';
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  /* =========
   * 更新主題模式
   * ========= */
  Future<bool> updateThemeMode(String mode) async {
    try {
      final res = await _client.put(
        Uri.parse('$baseUrl/api/users/theme-mode'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'theme_mode': mode}),
      );

      if (res.statusCode == 200) {
        themeMode = mode;
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('更新主題模式失敗: $e');
      return false;
    }
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
    themeMode = null; // 新增清除主題模式
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
