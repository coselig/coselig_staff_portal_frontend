import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/browser_client.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';

// ===== Models =====

class ProjectCase {
  final int id;
  final String name;
  final String status;
  final String? notes;
  final int? customerId;
  final int createdBy;
  final String createdAt;
  final String updatedAt;
  final String? customerCompany;
  final String? customerName;
  final String? customerChineseName;
  final String? customerEmail;
  final String? customerPhone;
  final String? creatorName;
  final String? creatorChineseName;
  final int snapshotCount;

  ProjectCase({
    required this.id,
    required this.name,
    required this.status,
    this.notes,
    this.customerId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.customerCompany,
    this.customerName,
    this.customerChineseName,
    this.customerEmail,
    this.customerPhone,
    this.creatorName,
    this.creatorChineseName,
    this.snapshotCount = 0,
  });

  factory ProjectCase.fromJson(Map<String, dynamic> json) {
    return ProjectCase(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      status: json['status'] ?? 'active',
      notes: json['notes'],
      customerId: json['customer_id'],
      createdBy: json['created_by'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      customerCompany: json['customer_company'],
      customerName: json['customer_name'],
      customerChineseName: json['customer_chinese_name'],
      customerEmail: json['customer_email'],
      customerPhone: json['customer_phone'],
      creatorName: json['creator_name'],
      creatorChineseName: json['creator_chinese_name'],
      snapshotCount: json['snapshot_count'] ?? 0,
    );
  }

  String get displayName => name;

  String get customerDisplayName {
    if (customerCompany != null && customerCompany!.isNotEmpty) {
      return customerCompany!;
    }
    return customerChineseName ?? customerName ?? '未指定客戶';
  }

  String get creatorDisplayName =>
      creatorChineseName ?? creatorName ?? '未知';
}

class QuoteSnapshot {
  final int id;
  final int caseId;
  final String label;
  final String? quoteData;
  final int createdBy;
  final String createdAt;
  final String? creatorName;
  final String? creatorChineseName;

  QuoteSnapshot({
    required this.id,
    required this.caseId,
    required this.label,
    this.quoteData,
    required this.createdBy,
    required this.createdAt,
    this.creatorName,
    this.creatorChineseName,
  });

  factory QuoteSnapshot.fromJson(Map<String, dynamic> json) {
    return QuoteSnapshot(
      id: json['id'] ?? 0,
      caseId: json['case_id'] ?? 0,
      label: json['label'] ?? '',
      quoteData: json['quote_data'],
      createdBy: json['created_by'] ?? 0,
      createdAt: json['created_at'] ?? '',
      creatorName: json['creator_name'],
      creatorChineseName: json['creator_chinese_name'],
    );
  }

  String get creatorDisplayName =>
      creatorChineseName ?? creatorName ?? '未知';
}

// ===== Service =====

class ProjectCaseService extends ChangeNotifier {
  final BrowserClient _client = BrowserClient()..withCredentials = true;

  List<ProjectCase> _cases = [];
  List<ProjectCase> get cases => _cases;

  bool isLoading = false;
  String? errorMessage;

  Future<List<ProjectCase>> fetchCases({int? customerId}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final uri = customerId != null
          ? Uri.parse(
              '${AuthService.baseUrl}/api/cases?customer_id=$customerId')
          : Uri.parse('${AuthService.baseUrl}/api/cases');

      final res = await _client.get(uri,
          headers: {'Content-Type': 'application/json'});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _cases = (data['cases'] as List)
            .map((e) => ProjectCase.fromJson(e))
            .toList();
        notifyListeners();
        return _cases;
      } else {
        errorMessage = '載入案件失敗 (${res.statusCode})';
        notifyListeners();
        return [];
      }
    } catch (e) {
      errorMessage = '網路錯誤：$e';
      notifyListeners();
      return [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<ProjectCase?> fetchCaseById(int caseId) async {
    try {
      final res = await _client.get(
        Uri.parse('${AuthService.baseUrl}/api/cases/$caseId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return ProjectCase.fromJson(data['case']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<int?> createCase({
    required String name,
    int? customerId,
    String? notes,
  }) async {
    try {
      final res = await _client.post(
        Uri.parse('${AuthService.baseUrl}/api/cases'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'customer_id': ?customerId,
          'notes': ?notes,
        }),
      );
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        await fetchCases();
        return data['id'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateCase(int caseId,
      {String? name, int? customerId, String? notes, String? status}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (customerId != null) body['customer_id'] = customerId;
      if (notes != null) body['notes'] = notes;
      if (status != null) body['status'] = status;

      final res = await _client.put(
        Uri.parse('${AuthService.baseUrl}/api/cases/$caseId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        await fetchCases();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCase(int caseId) async {
    try {
      final res = await _client.delete(
        Uri.parse('${AuthService.baseUrl}/api/cases/$caseId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        await fetchCases();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ===== 快照 =====

  Future<List<QuoteSnapshot>> fetchSnapshots(int caseId) async {
    try {
      final res = await _client.get(
        Uri.parse('${AuthService.baseUrl}/api/cases/$caseId/snapshots'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['snapshots'] as List)
            .map((e) => QuoteSnapshot.fromJson(e))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<QuoteSnapshot?> fetchSnapshotById(int caseId, int snapshotId) async {
    try {
      final res = await _client.get(
        Uri.parse(
            '${AuthService.baseUrl}/api/cases/$caseId/snapshots/$snapshotId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return QuoteSnapshot.fromJson(data['snapshot']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<int?> createSnapshot(int caseId,
      {required String label, required dynamic quoteData}) async {
    try {
      final res = await _client.post(
        Uri.parse('${AuthService.baseUrl}/api/cases/$caseId/snapshots'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'label': label,
          'quote_data': quoteData is String ? quoteData : jsonEncode(quoteData),
        }),
      );
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return data['id'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteSnapshot(int caseId, int snapshotId) async {
    try {
      final res = await _client.delete(
        Uri.parse(
            '${AuthService.baseUrl}/api/cases/$caseId/snapshots/$snapshotId'),
        headers: {'Content-Type': 'application/json'},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
