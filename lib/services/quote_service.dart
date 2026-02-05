import 'package:flutter/material.dart';
import 'package:http/browser_client.dart';
import 'dart:convert';
import 'package:coselig_staff_portal/main.dart';
import 'package:coselig_staff_portal/models/quote_models.dart';

class QuoteConfiguration {
  final int id;
  final int userId;
  final String name;
  final String chineseName;
  final String userName;
  final String createdAt;
  final String updatedAt;
  final QuoteData? quoteData;

  QuoteConfiguration({
    required this.id,
    required this.userId,
    required this.name,
    required this.chineseName,
    required this.userName,
    required this.createdAt,
    required this.updatedAt,
    this.quoteData,
  });

  factory QuoteConfiguration.fromJson(Map<String, dynamic> json) {
    return QuoteConfiguration(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      chineseName: json['chinese_name'] ?? json['user_name'] ?? 'Unknown',
      userName: json['user_name'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      quoteData: json['quote_data'] != null
          ? QuoteData.fromJson(jsonDecode(json['quote_data']))
          : null,
    );
  }
}

class QuoteData {
  final List<Loop> loops;
  final List<Module> modules;
  final String switchCount;
  final String otherDevices;
  final String powerSupply;
  final String boardMaterials;
  final String wiring;

  QuoteData({
    required this.loops,
    required this.modules,
    required this.switchCount,
    required this.otherDevices,
    required this.powerSupply,
    required this.boardMaterials,
    required this.wiring,
  });

  factory QuoteData.fromJson(Map<String, dynamic> json) {
    return QuoteData(
      loops: (json['loops'] as List?)?.map((l) => Loop.fromJson(l)).toList() ?? [],
      modules: (json['modules'] as List?)?.map((m) => Module.fromJson(m)).toList() ?? [],
      switchCount: json['switchCount'] ?? '',
      otherDevices: json['otherDevices'] ?? '',
      powerSupply: json['powerSupply'] ?? '',
      boardMaterials: json['boardMaterials'] ?? '',
      wiring: json['wiring'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loops': loops.map((l) => l.toJson()).toList(),
      'modules': modules.map((m) => m.toJson()).toList(),
      'switchCount': switchCount,
      'otherDevices': otherDevices,
      'powerSupply': powerSupply,
      'boardMaterials': boardMaterials,
      'wiring': wiring,
    };
  }
}

class QuoteService extends ChangeNotifier {
  final String baseUrl = 'https://employeeservice.coseligtest.workers.dev';
  final BrowserClient _client = BrowserClient()..withCredentials = true;
  final List<QuoteConfiguration> _configurations = [];
  List<ModuleOption> _moduleOptions = [];
  bool _isLoading = false;
  String? _error;

  List<QuoteConfiguration> get configurations => List.unmodifiable(_configurations);
  List<ModuleOption> get moduleOptions => List.unmodifiable(_moduleOptions);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchConfigurations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/quote-configurations'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final configs = data['configurations'] as List;
        _configurations.clear();
        _configurations.addAll(
          configs.map((json) => QuoteConfiguration.fromJson(json)).toList(),
        );
      } else if (response.statusCode == 401) {
        _error = 'Unauthorized';
        navigatorKey.currentState?.pushReplacementNamed('/login');
      } else {
        final error = jsonDecode(response.body);
        _error = error['error'] ?? 'Failed to fetch configurations';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveConfiguration(String name, QuoteData quoteData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/quote-configurations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'quoteData': quoteData.toJson()}),
      );

      if (response.statusCode == 200) {
        await fetchConfigurations(); // Refresh the list
      } else if (response.statusCode == 401) {
        _error = 'Unauthorized';
        navigatorKey.currentState?.pushReplacementNamed('/login');
      } else {
        final error = jsonDecode(response.body);
        _error = error['error'] ?? 'Failed to save configuration';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<QuoteData?> loadConfiguration(String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/quote-configurations/load?name=$name'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final quoteData = QuoteData.fromJson(data['quoteData']);
        _isLoading = false;
        notifyListeners();
        return quoteData;
      } else if (response.statusCode == 401) {
        _error = 'Unauthorized';
        navigatorKey.currentState?.pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      } else {
        final error = jsonDecode(response.body);
        _error = error['error'] ?? 'Failed to load configuration';
        notifyListeners();
        throw Exception(_error);
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteConfiguration(String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/api/quote-configurations?name=$name'),
      );

      if (response.statusCode == 200) {
        await fetchConfigurations(); // Refresh the list
      } else if (response.statusCode == 401) {
        _error = 'Unauthorized';
        navigatorKey.currentState?.pushReplacementNamed('/login');
      } else {
        final error = jsonDecode(response.body);
        _error = error['error'] ?? 'Failed to delete configuration';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchModuleOptions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/module-options'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final options = data['moduleOptions'] as List;
        _moduleOptions.clear();
        _moduleOptions.addAll(
          options
              .map(
                (json) => ModuleOption(
                  model: json['model'],
                  channelCount: json['channelCount'],
                  isDimmable: json['isDimmable'],
                  maxAmperePerChannel:
                      json['maxAmperePerChannel']?.toDouble() ?? 0.0,
                  maxAmpereTotal: json['maxAmpereTotal']?.toDouble() ?? 0.0,
                ),
              )
              .toList(),
        );
      } else if (response.statusCode == 401) {
        _error = 'Unauthorized';
        navigatorKey.currentState?.pushReplacementNamed('/login');
      } else {
        final error = jsonDecode(response.body);
        _error = error['error'] ?? 'Failed to fetch module options';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}