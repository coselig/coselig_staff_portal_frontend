import 'package:flutter/material.dart';
import 'package:http/browser_client.dart';
import 'dart:convert';
import 'package:coselig_staff_portal/main.dart';

class Customer {
  final int id;
  final int userId;
  final String name;
  final String? chineseName;
  final String? company;
  final String? email;
  final String? phone;
  final String? address;
  final String? projectName;
  final String? projectAddress;
  final String? contactPerson;
  final String? notes;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  Customer({
    required this.id,
    required this.userId,
    required this.name,
    this.chineseName,
    this.company,
    this.email,
    this.phone,
    this.address,
    this.projectName,
    this.projectAddress,
    this.contactPerson,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      chineseName: json['chinese_name'],
      company: json['company'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      projectName: json['project_name'],
      projectAddress: json['project_address'],
      contactPerson: json['contact_person'],
      notes: json['notes'],
      isActive: json['is_active'] == 1,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'chinese_name': chineseName,
      'company': company,
      'email': email,
      'phone': phone,
      'address': address,
      'project_name': projectName,
      'project_address': projectAddress,
      'contact_person': contactPerson,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Customer copyWith({
    int? id,
    int? userId,
    String? name,
    String? chineseName,
    String? company,
    String? email,
    String? phone,
    String? address,
    String? projectName,
    String? projectAddress,
    String? contactPerson,
    String? notes,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      chineseName: chineseName ?? this.chineseName,
      company: company ?? this.company,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      projectName: projectName ?? this.projectName,
      projectAddress: projectAddress ?? this.projectAddress,
      contactPerson: contactPerson ?? this.contactPerson,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CustomerService extends ChangeNotifier {
  final String baseUrl = 'https://employeeservice.coseligtest.workers.dev';
  final BrowserClient _client = BrowserClient()..withCredentials = true;
  final List<Customer> _customers = [];
  bool _isLoading = false;
  String? _error;

  List<Customer> get customers => List.unmodifiable(_customers);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 獲取所有客戶
  Future<void> fetchCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.get(Uri.parse('$baseUrl/api/customers'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final customersData = data['customers'] as List;
        _customers.clear();
        _customers.addAll(customersData.map((json) => Customer.fromJson(json)));
      } else {
        _error = 'Failed to load customers: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error loading customers: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 創建新客戶
  Future<Customer?> createCustomer(Map<String, dynamic> customerData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/customers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(customerData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final customerId = data['customerId'];
        // 重新獲取客戶列表
        await fetchCustomers();
        return _customers.firstWhere((c) => c.id == customerId);
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Failed to create customer';
        return null;
      }
    } catch (e) {
      _error = 'Error creating customer: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 更新客戶
  Future<bool> updateCustomer(int customerId, Map<String, dynamic> customerData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/api/customers/$customerId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(customerData),
      );

      if (response.statusCode == 200) {
        // 重新獲取客戶列表
        await fetchCustomers();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Failed to update customer';
        return false;
      }
    } catch (e) {
      _error = 'Error updating customer: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 刪除客戶
  Future<bool> deleteCustomer(int customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/api/customers/$customerId'),
      );

      if (response.statusCode == 200) {
        // 從本地列表移除
        _customers.removeWhere((c) => c.id == customerId);
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Failed to delete customer';
        return false;
      }
    } catch (e) {
      _error = 'Error deleting customer: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 根據ID獲取客戶
  Customer? getCustomerById(int id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}