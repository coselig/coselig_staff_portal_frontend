import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AuthService extends ChangeNotifier {
  AuthService();

  String output = '';
  String? username;
  Future<void> register(String username, String password) async {
    final url = Uri.parse(
      "https://employeeservice.coseligtest.workers.dev/api/register",
    );
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
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

  Future<void> login(String username, String password) async {
    final url = Uri.parse(
      'https://employeeservice.coseligtest.workers.dev/api/login',
    );

    output = '正在登入...';
    notifyListeners();

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      this.username = username; // 登入成功時儲存帳號
      output = 'HTTP status: ${response.statusCode}\nBody:\n${response.body}';
      notifyListeners();
    } catch (e) {
      output = '請求失敗: $e';
      notifyListeners();
    }
  }
}
