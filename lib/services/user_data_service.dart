import 'package:flutter/material.dart';
import 'package:http/browser_client.dart';
import 'dart:convert';
import 'package:coselig_staff_portal/main.dart';

class UserDataService extends ChangeNotifier {
  final String baseUrl = 'https://employeeservice.coseligtest.workers.dev';
  final BrowserClient _client = BrowserClient()..withCredentials = true;

  // 獲取當前用戶資料
  Future<Map<String, dynamic>> getCurrentUserData() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/users/me'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user'];
      } else if (response.statusCode == 401) {
        navigatorKey.currentState?.pushReplacementNamed('/login');
        throw Exception('未登入');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '獲取用戶資料失敗');
      }
    } catch (e) {
      throw Exception('網路錯誤: $e');
    }
  }

  // 獲取所有用戶（管理員）
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/users'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['users']);
      } else if (response.statusCode == 401) {
        navigatorKey.currentState?.pushReplacementNamed('/login');
        throw Exception('未登入');
      } else if (response.statusCode == 403) {
        throw Exception('權限不足');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '獲取用戶列表失敗');
      }
    } catch (e) {
      throw Exception('網路錯誤: $e');
    }
  }

  // 根據 ID 獲取用戶資料（管理員）
  Future<Map<String, dynamic>> getUserDataById(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/users/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user'];
      } else if (response.statusCode == 401) {
        navigatorKey.currentState?.pushReplacementNamed('/login');
        throw Exception('未登入');
      } else if (response.statusCode == 403) {
        throw Exception('權限不足');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '獲取用戶資料失敗');
      }
    } catch (e) {
      throw Exception('網路錯誤: $e');
    }
  }

  // 更新當前用戶資料
  Future<void> updateCurrentUserData(Map<String, dynamic> updateData) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/api/users/me'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        navigatorKey.currentState?.pushReplacementNamed('/login');
        throw Exception('未登入');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '更新用戶資料失敗');
      }
    } catch (e) {
      throw Exception('網路錯誤: $e');
    }
  }

  // 更新用戶角色（僅管理員）
  Future<void> updateUserRole(String userId, String role) async {
    try {
      final response = await _client.patch(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'role': role}),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        navigatorKey.currentState?.pushReplacementNamed('/login');
        throw Exception('未登入');
      } else if (response.statusCode == 403) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '權限不足');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '更新角色失敗');
      }
    } catch (e) {
      throw Exception('網路錯誤: $e');
    }
  }

  // 更新用戶在職狀態（僅管理員）
  Future<void> updateUserActive(String userId, bool isActive) async {
    try {
      final response = await _client.patch(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'is_active': isActive ? 1 : 0}),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        navigatorKey.currentState?.pushReplacementNamed('/login');
        throw Exception('未登入');
      } else if (response.statusCode == 403) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '權限不足');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '更新在職狀態失敗');
      }
    } catch (e) {
      throw Exception('網路錯誤: $e');
    }
  }

  // 查詢用戶關聯資料摘要（刪除前預覽，僅管理員）
  Future<Map<String, dynamic>> getUserRelatedData(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/users/$userId/related-data'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        navigatorKey.currentState?.pushReplacementNamed('/login');
        throw Exception('未登入');
      } else if (response.statusCode == 403) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '權限不足');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '查詢失敗');
      }
    } catch (e) {
      throw Exception('網路錯誤: $e');
    }
  }

  // 刪除用戶及其所有關聯資料（僅管理員）
  Future<void> deleteUser(String userId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/api/users/$userId'),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        navigatorKey.currentState?.pushReplacementNamed('/login');
        throw Exception('未登入');
      } else if (response.statusCode == 403) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '權限不足');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '刪除失敗');
      }
    } catch (e) {
      throw Exception('網路錯誤: $e');
    }
  }
}
