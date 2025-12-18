import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AuthService extends ChangeNotifier {
  /// 嘗試自動登入（偵測 session cookie）
  Future<void> tryAutoLogin() async {
    final url = Uri.parse(
      'https://employeeservice.coseligtest.workers.dev/api/me',
    );
    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['user'] != null) {
        name = data['user']['name'];
        email = data['user']['email'];
        output = '自動登入成功';
      } else {
        name = null;
        email = null;
        output = '尚未登入';
      }
      notifyListeners();
    } catch (e) {
      output = '自動登入失敗: $e';
      notifyListeners();
    }
  }
  AuthService();

  String output = '';
  String? email;
  String? name;
  Future<void> register(String name, String email, String password) async {
    final url = Uri.parse(
      "https://employeeservice.coseligtest.workers.dev/api/register",
    );
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "role": "employee",
      }),
    );

    if (response.statusCode == 201) {
      notifyListeners();
      output = "註冊成功！可以直接登入";
    } else {
      final data = jsonDecode(response.body);
      notifyListeners();
      output = "註冊失敗：${data['error'] ?? 'Unknown'}";
    }
  }

  Future<void> login(String email, String password) async {
    final url = Uri.parse(
      'https://employeeservice.coseligtest.workers.dev/api/login',
    );

    output = '正在登入...';
    notifyListeners();

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      this.email = email; // 登入成功時儲存帳號
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['user'] != null) {
        name = data['user']['name'];
      } else {
        name = null;
      }
      output = 'HTTP status: ${response.statusCode}\nBody:\n${response.body}';
      notifyListeners();
    } catch (e) {
      output = '請求失敗: $e';
      notifyListeners();
    }
  }
}
