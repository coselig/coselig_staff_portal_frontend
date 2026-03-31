import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/browser_client.dart';
import 'dart:convert';
import 'package:coselig_staff_portal/main.dart';
import 'package:coselig_staff_portal/models/quote/quote_models.dart';
import 'package:universal_html/html.dart' as html;

class QuoteConfiguration {
  final int id;
  final int userId;
  final String name;
  final String chineseName;
  final String userName;
  final String createdAt;
  final String updatedAt;
  final int? customerUserId;
  final String? customerName;
  final String? customerCompany;
  final String? projectName;
  final String? projectAddress;
  final QuoteData? quoteData;

  QuoteConfiguration({
    required this.id,
    required this.userId,
    required this.name,
    required this.chineseName,
    required this.userName,
    required this.createdAt,
    required this.updatedAt,
    this.customerUserId,
    this.customerName,
    this.customerCompany,
    this.projectName,
    this.projectAddress,
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
      customerUserId: json['customer_user_id'],
      customerName: json['customer_name'],
      customerCompany: json['customer_company'],
      projectName: json['project_name'],
      projectAddress: json['project_address'],
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
  final List<OtherDevice> otherDevices;
  final List<PowerSupply> powerSupplies;
  final List<MaterialItem> boardMaterials;
  final List<MaterialItem> wiring;
  final List<SwitchModel> switches;
  final List<String> spaces;

  // 樣態選項
  final bool ceilingHasLn;
  final bool ceilingHasMaintenanceHole;
  final bool switchHasLn;

  QuoteData({
    required this.loops,
    required this.modules,
    required this.switchCount,
    required this.otherDevices,
    required this.powerSupplies,
    required this.boardMaterials,
    required this.wiring,
    required this.switches,
    required this.spaces,
    required this.ceilingHasLn,
    required this.ceilingHasMaintenanceHole,
    required this.switchHasLn,
  });

  factory QuoteData.fromJson(Map<String, dynamic> json) {
    List<OtherDevice> parseOtherDevices(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw.map((d) => OtherDevice.fromJson(d)).toList();
      }
      // 若是空字串或其他型態，直接回傳空陣列
      return [];
    }

    List<MaterialItem> parseMaterialItems(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw.map((m) => MaterialItem.fromJson(m)).toList();
      }
      // 向下相容：若舊資料是字串，轉成單一項目
      if (raw is String && raw.isNotEmpty) {
        return [MaterialItem(name: raw, price: 0)];
      }
      return [];
    }

    return QuoteData(
      loops:
          (json['loops'] as List?)?.map((l) => Loop.fromJson(l)).toList() ?? [],
      modules:
          (json['modules'] as List?)?.map((m) => Module.fromJson(m)).toList() ??
          [],
      switchCount: json['switchCount'] ?? '',
      otherDevices: parseOtherDevices(json['otherDevices']),
      powerSupplies:
          (json['powerSupplies'] as List?)
              ?.map((ps) => PowerSupply.fromJson(ps))
              .toList() ??
          [],
      boardMaterials: parseMaterialItems(json['boardMaterials']),
      wiring: parseMaterialItems(json['wiring']),
      switches:
          (json['switches'] as List?)
              ?.map((s) => SwitchModel.fromJson(s))
              .toList() ??
          [],
      spaces:
          (json['spaces'] as List?)?.map((s) => s.toString()).toList() ?? [],
      ceilingHasLn: json['ceilingHasLn'] ?? false,
      ceilingHasMaintenanceHole: json['ceilingHasMaintenanceHole'] ?? false,
      switchHasLn: json['switchHasLn'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loops': loops.map((l) => l.toJson()).toList(),
      'modules': modules.map((m) => m.toJson()).toList(),
      'switchCount': switchCount,
      'otherDevices': otherDevices.map((d) => d.toJson()).toList(),
      'powerSupplies': powerSupplies.map((ps) => ps.toJson()).toList(),
      'boardMaterials': boardMaterials.map((m) => m.toJson()).toList(),
      'wiring': wiring.map((m) => m.toJson()).toList(),
      'switches': switches.map((s) => s.toJson()).toList(),
      'spaces': spaces,
      'ceilingHasLn': ceilingHasLn,
      'ceilingHasMaintenanceHole': ceilingHasMaintenanceHole,
      'switchHasLn': switchHasLn,
    };
  }
}

class QuoteRealtimeEvent {
  final String type;
  final int? quoteId;
  final String? quoteName;
  final String? action;
  final QuoteData? quoteData;

  const QuoteRealtimeEvent({
    required this.type,
    this.quoteId,
    this.quoteName,
    this.action,
    this.quoteData,
  });

  bool get isConfigurationsUpdated => type == 'quote-configurations-updated';
  bool get isFormSnapshot => type == 'quote-form-snapshot';
  bool get isAccessDenied => type == 'quote-form-access-denied';
}

class QuoteService extends ChangeNotifier {
  final String baseUrl = 'https://employeeservice.coseligtest.workers.dev';
  final BrowserClient _client = BrowserClient()..withCredentials = true;
  final List<QuoteConfiguration> _configurations = [];
  final List<ModuleOption> _moduleOptions = [];
  final List<FixtureTypeData> _fixtureTypeOptions = [];
  final StreamController<QuoteRealtimeEvent> _realtimeEvents =
      StreamController<QuoteRealtimeEvent>.broadcast();
  bool _isLoading = false;
  String? _error;
  bool _isFetchingConfigurations = false;
  html.WebSocket? _quoteSyncSocket;
  Timer? _quoteSyncReconnectTimer;
  bool _shouldKeepQuoteRealtime = false;
  int _quoteSyncReconnectAttempt = 0;
  bool _isQuoteRealtimeConnected = false;
  int? _activeQuoteId;

  List<QuoteConfiguration> get configurations =>
      List.unmodifiable(_configurations);
  List<ModuleOption> get moduleOptions => List.unmodifiable(_moduleOptions);
  List<FixtureTypeData> get fixtureTypeOptions => _fixtureTypeOptions.isNotEmpty
      ? List.unmodifiable(_fixtureTypeOptions)
      : defaultFixtureTypeData.values.toList();
  List<String> get fixtureTypes => _fixtureTypeOptions.isNotEmpty
      ? _fixtureTypeOptions.map((e) => e.type).toList()
      : defaultFixtureTypes;
  Map<String, FixtureTypeData> get fixtureTypeDataMap =>
      _fixtureTypeOptions.isNotEmpty
      ? {for (var e in _fixtureTypeOptions) e.type: e}
      : defaultFixtureTypeData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isQuoteRealtimeConnected => _isQuoteRealtimeConnected;
  Stream<QuoteRealtimeEvent> get realtimeEvents => _realtimeEvents.stream;

  Uri get _quoteSyncWebSocketUri {
    final uri = Uri.parse('$baseUrl/api/quote-sync/ws');
    final socketScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri.replace(scheme: socketScheme);
  }

  int? _normalizeQuoteId(dynamic value) {
    final normalized = int.tryParse(value?.toString() ?? '');
    if (normalized == null || normalized <= 0) {
      return null;
    }

    return normalized;
  }

  Future<void> fetchConfigurations({bool silent = false}) async {
    if (_isFetchingConfigurations) {
      return;
    }

    _isFetchingConfigurations = true;
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

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
      _isFetchingConfigurations = false;
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<int?> saveConfiguration(
    String name,
    QuoteData quoteData, {
    int? customerUserId,
    String? projectName,
    String? projectAddress,
    bool broadcastListUpdate = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final requestBody = {'name': name, 'quoteData': quoteData.toJson()};
      if (customerUserId != null) {
        requestBody['customerUserId'] = customerUserId;
      }
      if (projectName != null && projectName.isNotEmpty) {
        requestBody['projectName'] = projectName;
      }
      if (projectAddress != null && projectAddress.isNotEmpty) {
        requestBody['projectAddress'] = projectAddress;
      }
      requestBody['broadcastListUpdate'] = broadcastListUpdate;
      final response = await _client.post(
        Uri.parse('$baseUrl/api/quote-configurations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final configurationId = _normalizeQuoteId(data['configurationId']);
        if (broadcastListUpdate) {
          await fetchConfigurations(); // Refresh the list
        }
        return configurationId;
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

    return null;
  }

  void startQuoteRealtimeSync() {
    _shouldKeepQuoteRealtime = true;
    _quoteSyncReconnectTimer?.cancel();

    final socket = _quoteSyncSocket;
    if (socket != null &&
        (socket.readyState == html.WebSocket.OPEN ||
            socket.readyState == html.WebSocket.CONNECTING)) {
      return;
    }

    _connectQuoteSyncSocket();
  }

  void stopQuoteRealtimeSync() {
    _shouldKeepQuoteRealtime = false;
    _quoteSyncReconnectTimer?.cancel();
    _quoteSyncReconnectTimer = null;
    _quoteSyncReconnectAttempt = 0;
    _activeQuoteId = null;

    final socket = _quoteSyncSocket;
    _quoteSyncSocket = null;
    _setQuoteRealtimeConnected(false);

    if (socket != null) {
      try {
        socket.close(1000, 'quote-sync-stopped');
      } catch (_) {
        debugPrint('關閉估價同步 WebSocket 失敗');
      }
    }
  }

  void setActiveQuoteSyncId(int? quoteId) {
    _activeQuoteId = _normalizeQuoteId(quoteId);
    final socket = _quoteSyncSocket;
    if (socket == null || socket.readyState != html.WebSocket.OPEN) {
      return;
    }

    if (_activeQuoteId == null) {
      _sendQuoteSyncMessage({'type': 'unsubscribe-quote-form'});
    } else {
      _sendQuoteSyncMessage({
        'type': 'subscribe-quote-form',
        'quoteId': _activeQuoteId,
      });
    }
  }

  void publishQuoteFormSnapshot(int quoteId, QuoteData quoteData) {
    final normalizedQuoteId = _normalizeQuoteId(quoteId);
    if (normalizedQuoteId == null) {
      return;
    }

    _activeQuoteId = normalizedQuoteId;
    _sendQuoteSyncMessage({
      'type': 'quote-form-snapshot',
      'quoteId': normalizedQuoteId,
      'quoteData': quoteData.toJson(),
    });
  }

  void _connectQuoteSyncSocket() {
    try {
      final socket = html.WebSocket(_quoteSyncWebSocketUri.toString());
      _quoteSyncSocket = socket;

      socket.onOpen.listen((_) {
        if (_quoteSyncSocket != socket) return;
        _quoteSyncReconnectAttempt = 0;
        _setQuoteRealtimeConnected(true);
        if (_activeQuoteId != null) {
          _sendQuoteSyncMessage({
            'type': 'subscribe-quote-form',
            'quoteId': _activeQuoteId,
          });
        }
      });

      socket.onMessage.listen((event) {
        if (_quoteSyncSocket != socket) return;
        final data = event.data;
        if (data is String) {
          unawaited(_handleQuoteSyncMessage(data));
        }
      });

      socket.onError.listen((_) {
        if (_quoteSyncSocket != socket) return;
        debugPrint('估價同步 WebSocket 發生錯誤');
      });

      socket.onClose.listen((_) {
        if (_quoteSyncSocket != socket) return;
        _quoteSyncSocket = null;
        _setQuoteRealtimeConnected(false);
        _scheduleQuoteSyncReconnect();
      });
    } catch (e) {
      debugPrint('建立估價同步 WebSocket 失敗: $e');
      _scheduleQuoteSyncReconnect();
    }
  }

  Future<void> _handleQuoteSyncMessage(String rawMessage) async {
    try {
      final decoded = jsonDecode(rawMessage);
      if (decoded is! Map) {
        return;
      }

      final payload = Map<String, dynamic>.from(decoded);
      final type = payload['type'];

      if (type == 'quote-configurations-updated') {
        unawaited(fetchConfigurations(silent: true));
        _realtimeEvents.add(
          QuoteRealtimeEvent(
            type: type,
            quoteId: _normalizeQuoteId(payload['quoteId']),
            action: payload['action']?.toString(),
            quoteName: payload['quoteName']?.toString(),
          ),
        );
        return;
      }

      if (type == 'quote-form-snapshot') {
        final quoteId = _normalizeQuoteId(payload['quoteId']);
        final quoteDataJson = payload['quoteData'];
        if (quoteId == null || quoteDataJson is! Map) {
          return;
        }

        _realtimeEvents.add(
          QuoteRealtimeEvent(
            type: type,
            quoteId: quoteId,
            quoteName: payload['quoteName']?.toString(),
            quoteData: QuoteData.fromJson(
              Map<String, dynamic>.from(quoteDataJson),
            ),
          ),
        );
        return;
      }

      if (type == 'quote-form-access-denied') {
        final quoteId = _normalizeQuoteId(payload['quoteId']);
        _realtimeEvents.add(
          QuoteRealtimeEvent(
            type: type,
            quoteId: quoteId,
            quoteName: payload['quoteName']?.toString(),
          ),
        );
      }
    } catch (e) {
      debugPrint('解析估價同步訊息失敗: $e');
    }
  }

  void _scheduleQuoteSyncReconnect() {
    if (!_shouldKeepQuoteRealtime || _quoteSyncReconnectTimer != null) {
      return;
    }

    const retryDelays = [1, 2, 5, 10, 20, 30];
    final delayIndex = _quoteSyncReconnectAttempt < retryDelays.length
        ? _quoteSyncReconnectAttempt
        : retryDelays.length - 1;
    final delaySeconds = retryDelays[delayIndex];
    _quoteSyncReconnectAttempt += 1;

    _quoteSyncReconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _quoteSyncReconnectTimer = null;
      if (_shouldKeepQuoteRealtime && _quoteSyncSocket == null) {
        _connectQuoteSyncSocket();
      }
    });
  }

  void _sendQuoteSyncMessage(Map<String, dynamic> payload) {
    final socket = _quoteSyncSocket;
    if (socket == null || socket.readyState != html.WebSocket.OPEN) {
      return;
    }

    try {
      socket.send(jsonEncode(payload));
    } catch (e) {
      debugPrint('送出估價同步訊息失敗: $e');
    }
  }

  void _setQuoteRealtimeConnected(bool connected) {
    if (_isQuoteRealtimeConnected == connected) {
      return;
    }

    _isQuoteRealtimeConnected = connected;
    notifyListeners();
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
      rethrow;
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
                  brand: json['brand'] ?? '',
                  channelCount: json['channelCount'],
                  isDimmable: json['isDimmable'],
                  maxAmperePerChannel:
                      json['maxAmperePerChannel']?.toDouble() ?? 0.0,
                  maxAmpereTotal: json['maxAmpereTotal']?.toDouble() ?? 0.0,
                  price: json['price']?.toDouble() ?? 0.0,
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

  // 管理模組選項的方法
  Future<List<Map<String, dynamic>>> fetchAllModuleOptions() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/module-options'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['moduleOptions']);
      } else if (response.statusCode == 401) {
        navigatorKey.currentState?.pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch module options');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> addModuleOption(ModuleOption option) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/module-options'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': option.model,
          'brand': option.brand,
          'channelCount': option.channelCount,
          'isDimmable': option.isDimmable,
          'maxAmperePerChannel': option.maxAmperePerChannel,
          'maxAmpereTotal': option.maxAmpereTotal,
          'price': option.price,
        }),
      );

      if (response.statusCode == 201) {
        await fetchModuleOptions(); // 重新載入列表
      } else if (response.statusCode == 401) {
        navigatorKey.currentState?.pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to add module option');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> updateModuleOption(int id, Map<String, dynamic> updates) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/api/module-options?id=$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        await fetchModuleOptions(); // 重新載入列表
      } else if (response.statusCode == 401) {
        navigatorKey.currentState?.pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update module option');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> deleteModuleOption(int id) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/api/module-options?id=$id'),
      );

      if (response.statusCode == 200) {
        await fetchModuleOptions(); // 重新載入列表
      } else if (response.statusCode == 401) {
        navigatorKey.currentState?.pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete module option');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ===== 電源供應器選項 =====

  Future<List<Map<String, dynamic>>> fetchAllPowerSupplyOptions() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/power-supply-options'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['powerSupplyOptions']);
      } else if (response.statusCode == 401) {
        navigatorKey.currentState?.pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['error'] ?? 'Failed to fetch power supply options',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> addPowerSupplyOption(PowerSupply option) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/power-supply-options'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': option.name,
          'wattage': option.wattage,
          'type': option.type,
          'inputVoltage': option.inputVoltage,
          'supportsBothInputs': option.supportsBothInputs,
          'price': option.price,
        }),
      );

      if (response.statusCode != 201) {
        if (response.statusCode == 401) {
          navigatorKey.currentState?.pushReplacementNamed('/login');
          throw Exception('Unauthorized');
        }
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to add power supply option');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> updatePowerSupplyOption(
    int id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/api/power-supply-options?id=$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      );

      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          navigatorKey.currentState?.pushReplacementNamed('/login');
          throw Exception('Unauthorized');
        }
        final error = jsonDecode(response.body);
        throw Exception(
          error['error'] ?? 'Failed to update power supply option',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> deletePowerSupplyOption(int id) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/api/power-supply-options?id=$id'),
      );

      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          navigatorKey.currentState?.pushReplacementNamed('/login');
          throw Exception('Unauthorized');
        }
        final error = jsonDecode(response.body);
        throw Exception(
          error['error'] ?? 'Failed to delete power supply option',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ===== 燈具類型選項 =====

  Future<void> fetchFixtureTypeOptions() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/fixture-type-options'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final options = data['fixtureTypeOptions'] as List;
        _fixtureTypeOptions.clear();
        _fixtureTypeOptions.addAll(
          options
              .map(
                (json) => FixtureTypeData(
                  id: json['id'],
                  type: json['type'],
                  quantityLabel: json['quantityLabel'] ?? '燈具數量',
                  unitLabel: json['unitLabel'] ?? '每顆瓦數 (W)',
                  isMeterBased: json['isMeterBased'] ?? false,
                  price: (json['price'] ?? 0.0).toDouble(),
                  defaultUnitWatt: json['defaultUnitWatt'] ?? 0,
                ),
              )
              .toList(),
        );
        notifyListeners();
      }
    } catch (e) {
      // 靜默失敗，使用預設值
      debugPrint('載入燈具類型失敗: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllFixtureTypeOptions() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/fixture-type-options'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['fixtureTypeOptions']);
      } else if (response.statusCode == 401) {
        navigatorKey.currentState?.pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['error'] ?? 'Failed to fetch fixture type options',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> addFixtureTypeOption(FixtureTypeData option) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/fixture-type-options'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': option.type,
          'quantityLabel': option.quantityLabel,
          'unitLabel': option.unitLabel,
          'isMeterBased': option.isMeterBased,
          'price': option.price,
          'defaultUnitWatt': option.defaultUnitWatt,
        }),
      );

      if (response.statusCode == 201) {
        await fetchFixtureTypeOptions();
      } else if (response.statusCode == 401) {
        navigatorKey.currentState?.pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to add fixture type option');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> updateFixtureTypeOption(
    int id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/api/fixture-type-options?id=$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        await fetchFixtureTypeOptions();
      } else if (response.statusCode == 401) {
        navigatorKey.currentState?.pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['error'] ?? 'Failed to update fixture type option',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> deleteFixtureTypeOption(int id) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/api/fixture-type-options?id=$id'),
      );

      if (response.statusCode == 200) {
        await fetchFixtureTypeOptions();
      } else if (response.statusCode == 401) {
        navigatorKey.currentState?.pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['error'] ?? 'Failed to delete fixture type option',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ===== 開關選項 CRUD =====

  Future<List<SwitchModel>> fetchSwitchOptions() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/switch-options'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final options = data['switchOptions'] as List;
        return options.map((json) => SwitchModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        navigatorKey.currentState?.pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch switch options');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> addSwitchOption(SwitchModel model) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/switch-options'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(model.toJson()),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to add switch option');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> updateSwitchOption(int id, SwitchModel model) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/api/switch-options'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, ...model.toJson()}),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update switch option');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> deleteSwitchOption(int id) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/api/switch-options?id=$id'),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete switch option');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> savePatternSelection(Map<String, dynamic> patternData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/pattern-selection'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(patternData),
      );

      if (response.statusCode == 200) {
        // 成功保存樣態選擇
        notifyListeners();
      } else if (response.statusCode == 401) {
        _error = 'Unauthorized';
        navigatorKey.currentState?.pushReplacementNamed('/login');
      } else {
        final error = jsonDecode(response.body);
        _error = error['error'] ?? 'Failed to save pattern selection';
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

  Future<void> saveSwitchConfigurations(List<SwitchModel> switches) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/switch-configurations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'switches': switches.map((s) => s.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        // 成功保存開關配置
        notifyListeners();
      } else if (response.statusCode == 401) {
        _error = 'Unauthorized';
        navigatorKey.currentState?.pushReplacementNamed('/login');
      } else {
        final error = jsonDecode(response.body);
        _error = error['error'] ?? 'Failed to save switch configurations';
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

  @override
  void dispose() {
    stopQuoteRealtimeSync();
    _realtimeEvents.close();
    _client.close();
    super.dispose();
  }
}
