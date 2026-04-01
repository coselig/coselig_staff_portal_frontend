import 'dart:convert';

import 'package:coselig_staff_portal/main.dart';
import 'package:flutter/material.dart';
import 'package:http/browser_client.dart';

class SmartHomeAssessmentFormSummary {
  final int id;
  final int userId;
  final String name;
  final String createdAt;
  final String updatedAt;
  final String creatorName;

  const SmartHomeAssessmentFormSummary({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.creatorName,
  });

  factory SmartHomeAssessmentFormSummary.fromJson(Map<String, dynamic> json) {
    return SmartHomeAssessmentFormSummary(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      creatorName:
          json['chinese_name']?.toString() ??
          json['user_name']?.toString() ??
          '未知使用者',
    );
  }
}

class SmartHomeAssessmentFormDetail {
  final int id;
  final int userId;
  final String name;
  final Map<String, dynamic> formData;
  final String createdAt;
  final String updatedAt;

  const SmartHomeAssessmentFormDetail({
    required this.id,
    required this.userId,
    required this.name,
    required this.formData,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SmartHomeAssessmentFormDetail.fromJson(Map<String, dynamic> json) {
    return SmartHomeAssessmentFormDetail(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      name: json['name']?.toString() ?? '',
      formData: Map<String, dynamic>.from(
        json['formData'] ?? const <String, dynamic>{},
      ),
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}

class SmartHomeAssessmentService {
  final String baseUrl = 'https://employeeservice.coseligtest.workers.dev';
  final BrowserClient _client = BrowserClient()..withCredentials = true;

  Future<List<SmartHomeAssessmentFormSummary>> fetchForms() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/smart-home-assessment-forms'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final forms = (data['forms'] as List<dynamic>? ?? const [])
          .map((item) => SmartHomeAssessmentFormSummary.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
      return forms;
    }

    throw _buildHttpException(response.statusCode, response.body);
  }

  Future<SmartHomeAssessmentFormDetail> loadForm(String name) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/smart-home-assessment-forms/load').replace(
        queryParameters: {'name': name},
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return SmartHomeAssessmentFormDetail.fromJson(
        Map<String, dynamic>.from(
          data['form'] as Map? ?? const <String, dynamic>{},
        ),
      );
    }

    throw _buildHttpException(response.statusCode, response.body);
  }

  Future<int?> saveForm(String name, Map<String, dynamic> formData) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/smart-home-assessment-forms'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'formData': formData}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return int.tryParse(data['formId']?.toString() ?? '');
    }

    throw _buildHttpException(response.statusCode, response.body);
  }

  Future<void> deleteForm(String name) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/smart-home-assessment-forms').replace(
        queryParameters: {'name': name},
      ),
    );

    if (response.statusCode == 200) {
      return;
    }

    throw _buildHttpException(response.statusCode, response.body);
  }

  Exception _buildHttpException(int statusCode, String body) {
    Map<String, dynamic>? payload;
    try {
      payload = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      payload = null;
    }

    if (statusCode == 401) {
      navigatorKey.currentState?.pushReplacementNamed('/login');
      return Exception(payload?['error']?.toString() ?? 'Unauthorized');
    }

    return Exception(
      payload?['error']?.toString() ??
          payload?['detail']?.toString() ??
          'Request failed ($statusCode)',
    );
  }

  @mustCallSuper
  void dispose() {
    _client.close();
  }
}
