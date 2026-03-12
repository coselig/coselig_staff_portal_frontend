import 'dart:async';
import 'package:coselig_staff_portal/pages/customer/widgets/edit_fixture_dialog.dart';
import 'package:coselig_staff_portal/services/quote_service.dart';
import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/widgets/app_drawer.dart';
import 'package:universal_html/html.dart' as html;
import 'package:coselig_staff_portal/services/customer_service.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:coselig_staff_portal/models/quote/quote_models.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/utils/icon_utils.dart';
import 'widgets/step_loop_switch_widget.dart';
import 'widgets/step_module_widget.dart';
import 'widgets/step_power_supply_widget.dart';
import 'widgets/step_material_widget.dart';
import 'widgets/add_loop_dialog.dart';
import 'widgets/add_switch_dialog.dart';
import 'widgets/add_module_dialog.dart';
import 'widgets/add_fixture_dialog.dart';
import 'widgets/quote_result_dialog.dart';
import 'widgets/edit_loop_dialog.dart';

import 'package:coselig_staff_portal/models/quote/loop_info.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _currentStep = 0;

  // 樣態選擇
  bool _ceilingHasLn = false;
  bool _ceilingHasMaintenanceHole = false;
  bool _switchHasLn = false;

  // 第一步：迴路+設備配置
  final List<Loop> _loops = [];
  final List<SwitchModel> _switches = [];
  final TextEditingController _switchCountController = TextEditingController();
  List<OtherDevice> _otherDevices = [];
  final List<String> _spaces = ['未分類'];

  void _addSpace(String name) {
    if (!_spaces.contains(name)) {
      setState(() => _spaces.add(name));
      _autoSave();
    }
  }

  void _removeSpace(String name) {
    if (name == '未分類') return;
    setState(() {
      _spaces.remove(name);
      // 將該空間下的迴路移至「未分類」
      for (int i = 0; i < _loops.length; i++) {
        if (_loops[i].space == name) {
          _loops[i] = _loops[i].copyWith(space: '未分類');
        }
      }
      // 將該空間下的開關移至「未分類」
      for (int i = 0; i < _switches.length; i++) {
        if (_switches[i].space == name) {
          _switches[i] = _switches[i].copyWith(space: '未分類');
        }
      }
    });
    _autoSave();
  }

  void _renameSpace(String oldName, String newName) {
    if (oldName == '未分類' || _spaces.contains(newName)) return;
    setState(() {
      final idx = _spaces.indexOf(oldName);
      if (idx != -1) _spaces[idx] = newName;
      // 更新所有迴路的空間名稱
      for (int i = 0; i < _loops.length; i++) {
        if (_loops[i].space == oldName) {
          _loops[i] = _loops[i].copyWith(space: newName);
        }
      }
      // 更新所有開關的空間名稱
      for (int i = 0; i < _switches.length; i++) {
        if (_switches[i].space == oldName) {
          _switches[i] = _switches[i].copyWith(space: newName);
        }
      }
    });
    _autoSave();
  }

  /// 從迴路和開關中重建空間列表
  void _rebuildSpacesFromLoops() {
    final spacesFromLoops = _loops.map((l) => l.space).toSet();
    final spacesFromSwitches = _switches.map((s) => s.space).toSet();
    final allSpaces = {...spacesFromLoops, ...spacesFromSwitches};
    for (final space in allSpaces) {
      if (!_spaces.contains(space)) {
        _spaces.add(space);
      }
    }
  }

  /// 在同一空間內重新排序迴路
  void _reorderLoopsInSpace(
    String space,
    int oldLocalIndex,
    int newLocalIndex,
  ) {
    // 取得該空間內的迴路的全域 index
    final globalIndices = <int>[];
    for (int i = 0; i < _loops.length; i++) {
      if (_loops[i].space == space) {
        globalIndices.add(i);
      }
    }
    if (oldLocalIndex < 0 || oldLocalIndex >= globalIndices.length) return;
    if (newLocalIndex < 0 || newLocalIndex > globalIndices.length) return;
    if (newLocalIndex > oldLocalIndex) newLocalIndex -= 1;
    if (oldLocalIndex == newLocalIndex) return;

    setState(() {
      final movedLoop = _loops.removeAt(globalIndices[oldLocalIndex]);
      // 重新計算 globalIndices，因為已經 removeAt 了
      final updatedIndices = <int>[];
      for (int i = 0; i < _loops.length; i++) {
        if (_loops[i].space == space) {
          updatedIndices.add(i);
        }
      }
      final insertAt = newLocalIndex < updatedIndices.length
          ? updatedIndices[newLocalIndex]
          : (updatedIndices.isNotEmpty
                ? updatedIndices.last + 1
                : _loops.length);
      _loops.insert(insertAt, movedLoop);
    });
    _autoSave();
  }

  /// 將迴路移動到另一個空間
  void _moveLoopToSpace(int loopIndex, String targetSpace) {
    if (loopIndex < 0 || loopIndex >= _loops.length) return;
    if (_loops[loopIndex].space == targetSpace) return;
    setState(() {
      _loops[loopIndex] = _loops[loopIndex].copyWith(space: targetSpace);
    });
    _autoSave();
  }

  /// 在同一空間內重新排序開關
  void _reorderSwitchesInSpace(
    String space,
    int oldLocalIndex,
    int newLocalIndex,
  ) {
    final globalIndices = <int>[];
    for (int i = 0; i < _switches.length; i++) {
      if (_switches[i].space == space) {
        globalIndices.add(i);
      }
    }
    if (oldLocalIndex < 0 || oldLocalIndex >= globalIndices.length) return;
    if (newLocalIndex < 0 || newLocalIndex > globalIndices.length) return;
    if (newLocalIndex > oldLocalIndex) newLocalIndex -= 1;
    if (oldLocalIndex == newLocalIndex) return;

    setState(() {
      final movedSwitch = _switches.removeAt(globalIndices[oldLocalIndex]);
      final updatedIndices = <int>[];
      for (int i = 0; i < _switches.length; i++) {
        if (_switches[i].space == space) {
          updatedIndices.add(i);
        }
      }
      final insertAt = newLocalIndex < updatedIndices.length
          ? updatedIndices[newLocalIndex]
          : (updatedIndices.isNotEmpty
                ? updatedIndices.last + 1
                : _switches.length);
      _switches.insert(insertAt, movedSwitch);
    });
    _autoSave();
  }

  /// 將開關移動到另一個空間
  void _moveSwitchToSpace(int switchIndex, String targetSpace) {
    if (switchIndex < 0 || switchIndex >= _switches.length) return;
    if (_switches[switchIndex].space == targetSpace) return;
    setState(() {
      _switches[switchIndex] = _switches[switchIndex].copyWith(
        space: targetSpace,
      );
    });
    _autoSave();
  }

  void _addOtherDevice() {
    setState(() {
      _otherDevices.add(OtherDevice(name: '', price: 0));
    });
    _autoSave();
  }

  void _removeOtherDevice(int index) {
    setState(() {
      _otherDevices.removeAt(index);
    });
    _autoSave();
  }

  void _updateOtherDevice(int index, {String? name, double? price}) {
    setState(() {
      final old = _otherDevices[index];
      _otherDevices[index] = OtherDevice(
        name: name ?? old.name,
        price: price ?? old.price,
      );
    });
    _autoSave();
  }

  // 開關管理方法
  void _showAddSwitchDialog() async {
    try {
      setState(() => _isLoading = true);
      final switchOptions = await _quoteService
          .fetchSwitchOptions(); // 從資料庫撈取開關資料

      if (switchOptions.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('沒有可用的開關選項，請聯繫管理員新增')));
        return;
      }

      final loopCount = _loops.length; // 傳遞當前迴路數量

      showDialog(
        context: context,
        builder: (context) => AddSwitchDialog(
          switchOptions: switchOptions,
          loopCount: loopCount,
          spaces: _spaces,
          onSelectSwitch: (selectedSwitch) {
            setState(() {
              _switches.add(selectedSwitch);
            });
            _saveSwitchConfigurations();
            _autoSave();
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('載入開關選項失敗: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateSwitch(int index, SwitchModel updatedSwitch) {
    setState(() {
      _switches[index] = updatedSwitch;
    });
    _saveSwitchConfigurations();
    _autoSave();
  }

  void _removeSwitch(int index) {
    setState(() {
      _switches.removeAt(index);
    });
    _saveSwitchConfigurations();
    _autoSave();
  }

  // 第二步：模組配置
  final List<Module> _modules = [];

  // 第四步：電源供應器與材料配置
  List<PowerSupply> _powerSupplies = [];
  List<PowerSupply> _powerSupplyOptions = [];
  List<MaterialItem> _boardMaterials = [];
  List<MaterialItem> _wiringItems = [];

  late QuoteService _quoteService;
  late CustomerService _customerService;
  String _currentConfigurationName = '新估價配置';
  String? _selectedConfigurationName; // 追蹤下拉選單中選中的配置
  bool _isLoading = false;
  Customer? _selectedCustomer; // 選中的客戶
  Timer? _autoSaveTimer;
  bool _autoSaving = false;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    html.document.title = authService.isCustomer
        ? 'Coselig 顧客系統'
        : 'Coselig 員工系統 - 估價系統';
    _quoteService = Provider.of<QuoteService>(context, listen: false);
    _customerService = Provider.of<CustomerService>(context, listen: false);
    _loadConfigurations();
    if (!authService.isCustomer) {
      _loadCustomers();
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _switchCountController.dispose();
    super.dispose();
  }

  /// 自動存檔（帶 debounce，僅在已有已存儲配置時才會觸發）
  void _autoSave() {
    if (_selectedConfigurationName == null) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 800), () async {
      if (_autoSaving) return;
      _autoSaving = true;
      try {
        final quoteData = QuoteData(
          switches: _switches,
          loops: _loops,
          modules: _modules,
          switchCount: _switchCountController.text,
          otherDevices: _otherDevices,
          powerSupplies: _powerSupplies,
          boardMaterials: _boardMaterials,
          wiring: _wiringItems,
          ceilingHasLn: _ceilingHasLn,
          ceilingHasMaintenanceHole: _ceilingHasMaintenanceHole,
          switchHasLn: _switchHasLn,
        );
        final authService = Provider.of<AuthService>(context, listen: false);
        final effectiveCustomerId = authService.isCustomer
            ? int.tryParse(authService.userId ?? '')
            : _selectedCustomer?.userId;
        await _quoteService.saveConfiguration(
          _currentConfigurationName,
          quoteData,
          customerUserId: effectiveCustomerId,
        );
      } catch (_) {
        // 靜默處理自動存檔錯誤
      } finally {
        _autoSaving = false;
      }
    });
  }

  void _saveSwitchConfigurations() async {
    try {
      await _quoteService.saveSwitchConfigurations(_switches);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('開關配置已保存')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存開關配置失敗: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final loopCount = _loops.length; // 獲取當前迴路數量

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('估價系統'),
              ],
            ),
            if (_selectedCustomer != null && !authService.isCustomer)
              Text(
                '客戶: ${_selectedCustomer!.name}${_selectedCustomer!.company != null ? ' (${_selectedCustomer!.company})' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                ),
              ),
            // 新增顯示迴路數量
            Text(
              '當前迴路數量: $loopCount',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 2,
        shadowColor: Theme.of(
          context,
        ).colorScheme.shadow.withValues(alpha: 0.1),
        actions: [
          if (_isLoading)
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          else ...[
            if (!authService.isCustomer) ...[
              DropdownButton<Customer?>(
                value: _selectedCustomer,
                hint: Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: context.scaledIconSize(18),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '選擇客戶',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                selectedItemBuilder: (BuildContext context) {
                  return _customerService.customers.map((customer) {
                    return Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: context.scaledIconSize(18),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            customer.name,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  }).toList()..insert(
                    0,
                    Row(
                      children: [
                        Icon(
                          Icons.person_off,
                          size: context.scaledIconSize(18),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '未選擇客戶',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.primary,
                ),
                underline: const SizedBox(),
                dropdownColor: Theme.of(context).colorScheme.surface,
                items: [
                  DropdownMenuItem<Customer?>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_off,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '未選擇客戶',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._customerService.customers.map((customer) {
                    return DropdownMenuItem<Customer?>(
                      value: customer,
                      child: Text(
                        customer.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    );
                  }),
                ],
                onChanged: (Customer? customer) {
                  setState(() {
                    _selectedCustomer = customer;
                    _selectedConfigurationName = null;
                  });
                },
              ),
            ],
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: VerticalDivider(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
                thickness: 1,
              ),
            ),
            Consumer<QuoteService>(
              builder: (context, quoteService, child) {
                final allConfigurations = quoteService.configurations;
                final configurations = authService.isCustomer
                    ? allConfigurations
                          .where(
                            (c) =>
                                c.customerUserId ==
                                int.tryParse(authService.userId ?? ''),
                          )
                          .toList()
                    : allConfigurations
                          .where(
                            (c) => _selectedCustomer == null
                                ? c.customerUserId == null
                                : c.customerUserId == _selectedCustomer!.userId,
                          )
                          .toList();
                return configurations.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: DropdownButton<String>(
                          value: _selectedConfigurationName,
                          hint: Row(
                            children: [
                              Icon(
                                Icons.folder_open,
                                size: context.scaledIconSize(18),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '載入配置',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          selectedItemBuilder: (BuildContext context) {
                            return configurations.map((config) {
                              return Row(
                                children: [
                                  Icon(
                                    Icons.folder_open,
                                    size: context.scaledIconSize(18),
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    config.name,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            }).toList();
                          },
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          underline: const SizedBox(),
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          items: configurations.map((config) {
                            return DropdownMenuItem<String>(
                              value: config.name,
                              child: Text(
                                config.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? configName) {
                            if (configName != null) {
                              setState(() {
                                _selectedConfigurationName = configName;
                                _currentConfigurationName = configName;
                              });
                              _loadSelectedConfiguration(configName);
                            }
                          },
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),

            //新建配置按鈕
            IconButton(
              iconSize: context.scaledIconSize(24),
              icon: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: _createNewConfiguration,
              tooltip: '新建配置',
            ),

            //儲存配置按鈕
            IconButton(
              iconSize: context.scaledIconSize(24),
              icon: Icon(
                Icons.save,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: _saveConfiguration,
              tooltip: '儲存配置',
            ),

            //刪除配置按鈕
            IconButton(
              iconSize: context.scaledIconSize(24),
              icon: Icon(
                Icons.delete,
                color: _selectedConfigurationName != null
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.outline,
              ),
              onPressed: _selectedConfigurationName != null
                  ? () => _showDeleteConfirmation(_currentConfigurationName)
                  : null,
              tooltip: _selectedConfigurationName != null ? '刪除當前配置' : '尚未載入配置',
            ),
          ],
        ],
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 4) {
                  setState(() {
                    _currentStep += 1;
                  });
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => QuoteResultDialog(
                      loops: _loops,
                      modules: _modules,
                      switchCount: _switchCountController.text,
                      otherDevices: _otherDevices,
                      powerSupplies: _powerSupplies,
                      boardMaterials: _boardMaterials,
                      wiring: _wiringItems,
                      ceilingHasLn: _ceilingHasLn,
                      ceilingHasMaintenanceHole: _ceilingHasMaintenanceHole,
                      switchHasLn: _switchHasLn,
                    ),
                  );
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() {
                    _currentStep -= 1;
                  });
                }
              },
              onStepTapped: (step) {
                setState(() {
                  _currentStep = step;
                });
              },
              controlsBuilder: (BuildContext context, ControlsDetails details) {
                return Container(
                  margin: const EdgeInsets.only(top: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmallScreen = constraints.maxWidth < 600;
                      return isSmallScreen
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_currentStep > 0)
                                  OutlinedButton.icon(
                                    onPressed: details.onStepCancel,
                                    icon: const Icon(Icons.arrow_back),
                                    label: const Text('上一步'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                if (_currentStep > 0 && _currentStep < 4)
                                  const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: details.onStepContinue,
                                  icon: _currentStep < 4
                                      ? const Icon(Icons.arrow_forward)
                                      : const Icon(Icons.calculate),
                                  label: Text(
                                    _currentStep < 4 ? '下一步' : '生成報價',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                if (_currentStep > 0)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: details.onStepCancel,
                                      icon: const Icon(Icons.arrow_back),
                                      label: const Text('上一步'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_currentStep > 0 && _currentStep < 4)
                                  const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: details.onStepContinue,
                                    icon: _currentStep < 4
                                        ? const Icon(Icons.arrow_forward)
                                        : const Icon(Icons.calculate),
                                    label: Text(
                                      _currentStep < 4 ? '下一步' : '生成報價',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                    },
                  ),
                );
              },
              steps: [
                // 第一個步驟：樣態選擇
                Step(
                  title: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _currentStep >= 0
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '1',
                            style: TextStyle(
                              color: _currentStep >= 0
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '樣態選擇',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        title: const Text('天花版是否有LN'),
                        value: _ceilingHasLn,
                        onChanged: (v) {
                          setState(() => _ceilingHasLn = v!);
                          _autoSave();
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('天花版是否有維修孔'),
                        value: _ceilingHasMaintenanceHole,
                        onChanged: (v) {
                          setState(() => _ceilingHasMaintenanceHole = v!);
                          _autoSave();
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('開關是否有LN'),
                        value: _switchHasLn,
                        onChanged: (v) {
                          setState(() => _switchHasLn = v!);
                          _autoSave();
                        },
                      ),
                    ],
                  ),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0
                      ? StepState.complete
                      : StepState.indexed,
                ),
                // 原來的迴路+設備步驟現在編號為2
                Step(
                  title: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _currentStep >= 1
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '2',
                            style: TextStyle(
                              color: _currentStep >= 1
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '迴路+設備配置',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  content: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        StepLoopSwitchWidget(
                          loops: _loops,
                          switches: _switches,
                          switchCountController: _switchCountController,
                          otherDevices: _otherDevices,
                          spaces: _spaces,
                          onAddOtherDevice: _addOtherDevice,
                          onRemoveOtherDevice: _removeOtherDevice,
                          onUpdateOtherDevice: _updateOtherDevice,
                          onAddLoop: _showAddLoopDialog,
                          onAddSwitch: _showAddSwitchDialog,
                          onRemoveLoop: _removeLoop,
                          onUpdateLoop: _updateLoop,
                          onAddFixtureToLoop: _showAddFixtureDialog,
                          onRemoveFixtureFromLoop: _removeFixtureFromLoop,
                          onEditFixtureInLoop: _showEditFixtureDialog,
                          onUpdateSwitch: _updateSwitch,
                          onRemoveSwitch: _removeSwitch,
                          onAddSpace: _addSpace,
                          onRemoveSpace: _removeSpace,
                          onRenameSpace: _renameSpace,
                          onReorderLoopsInSpace: _reorderLoopsInSpace,
                          onMoveLoopToSpace: _moveLoopToSpace,
                          onReorderSwitchesInSpace: _reorderSwitchesInSpace,
                          onMoveSwitchToSpace: _moveSwitchToSpace,
                        ),
                      ],
                    ),
                  ),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1
                      ? StepState.complete
                      : (_currentStep == 1
                            ? StepState.editing
                            : StepState.indexed),
                ),
                Step(
                  title: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _currentStep >= 2
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '3',
                            style: TextStyle(
                              color: _currentStep >= 2
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '模組配置',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  content: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: StepModuleWidget(
                      modules: _modules,
                      onAddModule: _showAddModuleDialog,
                      onAutoAssign: _autoAssignModules,
                      onRemoveModule: _removeModule,
                      onAssignLoopToModule: _assignLoopToModule,
                      onRemoveLoopFromModule: _removeLoopFromModule,
                      onEditLoopInModule: _showEditLoopDialog,
                      unassignedLoops: _getUnassignedLoops(),
                    ),
                  ),
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2
                      ? StepState.complete
                      : (_currentStep == 2
                            ? StepState.editing
                            : StepState.indexed),
                ),
                Step(
                  title: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _currentStep >= 3
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '4',
                            style: TextStyle(
                              color: _currentStep >= 3
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '電源供應器配置',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  content: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: StepPowerSupplyWidget(
                      powerSupplies: _powerSupplies,
                      availableOptions: _powerSupplyOptions,
                      moduleCount: _modules.length,
                      onChanged: (list) {
                        setState(() {
                          _powerSupplies.clear();
                          _powerSupplies.addAll(list);
                        });
                        _autoSave();
                      },
                      onAutoAssign: _showAutoAssignPowerSuppliesDialog,
                    ),
                  ),
                  isActive: _currentStep >= 3,
                  state: _currentStep > 3
                      ? StepState.complete
                      : (_currentStep == 3
                            ? StepState.editing
                            : StepState.indexed),
                ),
                Step(
                  title: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _currentStep >= 4
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '5',
                            style: TextStyle(
                              color: _currentStep >= 4
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '材料配置',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  content: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: StepMaterialWidget(
                      boardMaterials: _boardMaterials,
                      onBoardMaterialsChanged: (list) {
                        setState(() {
                          _boardMaterials.clear();
                          _boardMaterials.addAll(list);
                        });
                        _autoSave();
                      },
                      wiringItems: _wiringItems,
                      onWiringItemsChanged: (list) {
                        setState(() {
                          _wiringItems.clear();
                          _wiringItems.addAll(list);
                        });
                        _autoSave();
                      },
                    ),
                  ),
                  isActive: _currentStep >= 4,
                  state: _currentStep == 4
                      ? StepState.editing
                      : StepState.indexed,
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '處理中...',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddModuleDialog() {
    showDialog(
      context: context,
      builder: (context) => AddModuleDialog(
        onAddModule: (module) {
          setState(() {
            _modules.add(module);
          });
          _autoSave();
        },
      ),
    );
  }

  void _removeModule(int index) {
    setState(() {
      _modules.removeAt(index);
    });
    _autoSave();
  }

  void _showAddLoopDialog() {
    showDialog(
      context: context,
      builder: (context) => AddLoopDialog(
        spaces: _spaces,
        onAddLoop: (name, space) {
          setState(() {
            if (!_spaces.contains(space)) {
              _spaces.add(space);
            }
            _loops.add(Loop(name: name, space: space));
          });
          _autoSave();
        },
      ),
    );
  }

  // 更新迴路
  void _updateLoop(int index, Loop updatedLoop) {
    setState(() {
      _loops[index] = updatedLoop;
    });
    _autoSave();
  }

  // 刪除迴路
  void _removeLoop(int index) {
    setState(() {
      _loops.removeAt(index);
    });
    _autoSave();
  }

  // 向迴路添加燈具
  void _showAddFixtureDialog(int loopIndex) {
    showDialog(
      context: context,
      builder: (context) => AddFixtureDialog(
        onAddFixture: (fixture) {
          setState(() {
            final loop = _loops[loopIndex];
            final updatedFixtures = List<LoopFixture>.from(loop.fixtures)
              ..add(fixture);
            _loops[loopIndex] = loop.copyWith(fixtures: updatedFixtures);
          });
          _autoSave();
        },
      ),
    );
  }

  // 修改迴路中的燈具
  void _showEditFixtureDialog(int loopIndex, int fixtureIndex) {
    final fixture = _loops[loopIndex].fixtures[fixtureIndex];
    showDialog(
      context: context,
      builder: (context) => EditFixtureDialog(
        fixture: fixture,
        onUpdateFixture: (updatedFixture) {
          setState(() {
            final loop = _loops[loopIndex];
            final updatedFixtures = List<LoopFixture>.from(loop.fixtures);
            updatedFixtures[fixtureIndex] = updatedFixture;
            _loops[loopIndex] = loop.copyWith(fixtures: updatedFixtures);
          });
          _autoSave();
        },
      ),
    );
  }

  // 從迴路移除燈具
  void _removeFixtureFromLoop(int loopIndex, int fixtureIndex) {
    setState(() {
      final loop = _loops[loopIndex];
      final updatedFixtures = List<LoopFixture>.from(loop.fixtures)
        ..removeAt(fixtureIndex);
      _loops[loopIndex] = loop.copyWith(fixtures: updatedFixtures);
    });
    _autoSave();
  }

  // 獲取未分配的迴路
  List<Loop> _getUnassignedLoops() {
    final assignedLoopNames = <String>{};
    for (final module in _modules) {
      for (final allocation in module.loopAllocations) {
        assignedLoopNames.add(allocation.loop.name);
      }
    }
    return _loops
        .where((loop) => !assignedLoopNames.contains(loop.name))
        .toList();
  }

  // 將迴路分配到模組
  void _assignLoopToModule(int moduleIndex, Loop loop) async {
    final module = _modules[moduleIndex];
    final ampereCheck = module.checkLoopAmpereLimit(loop, 1);

    if (ampereCheck == AmpereCheckResult.blocked) {
      // 超過最大限制，顯示錯誤對話框
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('無法添加迴路'),
          content: Text(
            '添加此迴路將使模組總安培數超過最大限制 (${module.maxAmpereTotal}A)。\n'
            '請選擇其他模組或減少負載。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('確定'),
            ),
          ],
        ),
      );
      return;
    }

    if (ampereCheck == AmpereCheckResult.warning) {
      // 超過80%，顯示警告但允許繼續
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('安培數警告'),
          content: Text(
            '添加此迴路將使模組總安培數超過80%的額定值。\n'
            '建議檢查電路安全性和散熱條件。\n\n'
            '確定要繼續嗎？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('繼續'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) {
        return;
      }
    }

    // 正常添加迴路
    setState(() {
      if (module.canAssignLoop(loop, 1)) {
        final allocation = LoopAllocation(loop: loop);
        final updatedLoopAllocations = List<LoopAllocation>.from(
          module.loopAllocations,
        )..add(allocation);
        _modules[moduleIndex] = module.copyWith(
          loopAllocations: updatedLoopAllocations,
        );
      }
    });
    _autoSave();
  }

  // 從模組移除迴路分配
  void _removeLoopFromModule(int moduleIndex, int allocationIndex) {
    setState(() {
      final module = _modules[moduleIndex];
      final updatedLoopAllocations = List<LoopAllocation>.from(
        module.loopAllocations,
      )..removeAt(allocationIndex);
      _modules[moduleIndex] = module.copyWith(
        loopAllocations: updatedLoopAllocations,
      );
    });
    _autoSave();
  }

  // 編輯模組中的迴路
  void _showEditLoopDialog(int moduleIndex, int allocationIndex) {
    final module = _modules[moduleIndex];
    final allocation = module.loopAllocations[allocationIndex];
    final loop = allocation.loop;

    showDialog(
      context: context,
      builder: (context) => EditLoopDialog(
        loop: loop,
        onUpdateLoop: (updatedLoop) {
          setState(() {
            final updatedAllocation = allocation.copyWith(loop: updatedLoop);
            final updatedLoopAllocations = List<LoopAllocation>.from(
              module.loopAllocations,
            );
            updatedLoopAllocations[allocationIndex] = updatedAllocation;
            _modules[moduleIndex] = module.copyWith(
              loopAllocations: updatedLoopAllocations,
            );
          });
          _autoSave();
        },
      ),
    );
  }

  // 自動分配模組
  void _autoAssignModules() {
    final quoteService = Provider.of<QuoteService>(context, listen: false);
    final allModuleOptions = quoteService.moduleOptions;

    if (allModuleOptions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('沒有可用的模組選項，請先在管理頁面添加模組')));
      return;
    }

    if (_loops.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('沒有迴路可分配，請先在第一步添加迴路')));
      return;
    }

    // 收集可用的廠牌列表
    final brands = <String>{};
    for (final opt in allModuleOptions) {
      brands.add(opt.brand.isEmpty ? '' : opt.brand);
    }
    final brandList = brands.toList()
      ..sort((a, b) {
        if (a.isEmpty) return -1;
        if (b.isEmpty) return 1;
        return a.compareTo(b);
      });

    // 顯示廠牌選擇對話框
    showDialog(
      context: context,
      builder: (context) {
        String? selectedBrand; // null 表示不限
        bool groupBySpace = true; // 是否依空間分組
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('選擇廠牌'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('選擇要使用的模組廠牌進行自動分配：'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedBrand,
                    decoration: const InputDecoration(
                      labelText: '廠牌',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('不限（使用所有廠牌）'),
                      ),
                      ...brandList.map((brand) {
                        return DropdownMenuItem<String?>(
                          value: brand,
                          child: Text(brand.isEmpty ? '(未設定廠牌)' : brand),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedBrand = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('依空間分組'),
                    subtitle: const Text(
                      '不同空間的迴路不會共用同一個模組',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: groupBySpace,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setDialogState(() {
                        groupBySpace = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (groupBySpace) {
                      _runAutoAssignBySpace(selectedBrand);
                    } else {
                      _runAutoAssign(selectedBrand);
                    }
                  },
                  child: const Text('開始分配'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 執行自動分配
  void _runAutoAssign(String? brandFilter) {
    final quoteService = Provider.of<QuoteService>(context, listen: false);
    final allModuleOptions = quoteService.moduleOptions;

    // 根據廠牌篩選模組選項
    final moduleOptions = brandFilter == null
        ? allModuleOptions
        : allModuleOptions.where((o) => o.brand == brandFilter).toList();

    if (moduleOptions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('該廠牌沒有可用的模組選項')));
      return;
    }

    // 輔助函數：取得迴路需要的通道數
    int getChannelsPerLoop(String dimmingType) {
      switch (dimmingType) {
        case 'WRGB':
          return 4;
        case 'RGB':
          return 3;
        case '雙色溫':
          return 2;
        case '單色溫':
        case '繼電器':
          return 1;
        default:
          return 1;
      }
    }

    // 輔助函數：計算迴路的安培數
    double getLoopAmpere(Loop loop) {
      final totalWatt = loop.fixtures.fold(0, (sum, f) => sum + f.totalWatt);
      return loop.voltage > 0 ? totalWatt / loop.voltage : 0;
    }

    // 輔助函數：計算迴路每通道安培數
    double getLoopAmperePerChannel(Loop loop) {
      final channels = getChannelsPerLoop(loop.dimmingType);
      return channels > 0 ? getLoopAmpere(loop) / channels : 0;
    }

    // 準備所有迴路，按需要通道數降序排列（大迴路優先分配）
    final sortedLoops = List<Loop>.from(_loops);
    sortedLoops.sort((a, b) {
      final channelsA = getChannelsPerLoop(a.dimmingType);
      final channelsB = getChannelsPerLoop(b.dimmingType);
      if (channelsA != channelsB) return channelsB.compareTo(channelsA);
      return getLoopAmpere(b).compareTo(getLoopAmpere(a));
    });

    // 判斷迴路是否為繼電器類型
    bool isRelayLoop(Loop loop) => loop.dimmingType == '繼電器';

    // 將模組選項按通道數排序（優先嘗試大的，減少模組總數）
    final sortedDimmableOptions =
        moduleOptions.where((o) => o.isDimmable).toList()
          ..sort((a, b) => b.channelCount.compareTo(a.channelCount));
    final sortedRelayOptions =
        moduleOptions.where((o) => !o.isDimmable).toList()
          ..sort((a, b) => b.channelCount.compareTo(a.channelCount));

    // 用臨時列表做分配
    final newModules = <Module>[];
    final unassigned = <Loop>[];

    // 預先計算每個迴路的資訊
    final loopInfos = <LoopInfo>[];
    for (final loop in sortedLoops) {
      loopInfos.add(
        LoopInfo(
          loop: loop,
          channels: getChannelsPerLoop(loop.dimmingType),
          ampere: getLoopAmpere(loop),
          amperePerCh: getLoopAmperePerChannel(loop),
          isRelay: isRelayLoop(loop),
        ),
      );
    }

    for (int li = 0; li < loopInfos.length; li++) {
      final info = loopInfos[li];

      // 嘗試放進已建立的模組（Best Fit：選剩餘通道最少但夠用的）
      int bestModuleIndex = -1;
      int bestAvailable = 999;

      for (int i = 0; i < newModules.length; i++) {
        final m = newModules[i];
        // 類型必須匹配
        if (info.isRelay && m.isDimmable) continue;
        if (!info.isRelay && !m.isDimmable) continue;

        if (m.availableChannels >= info.channels &&
            info.amperePerCh <= m.maxAmperePerChannel &&
            m.totalMaxAmpere + info.ampere <= m.maxAmpereTotal) {
          if (m.availableChannels < bestAvailable) {
            bestAvailable = m.availableChannels;
            bestModuleIndex = i;
          }
        }
      }

      if (bestModuleIndex >= 0) {
        // 放進現有模組
        final m = newModules[bestModuleIndex];
        final updatedAllocations = List<LoopAllocation>.from(m.loopAllocations)
          ..add(LoopAllocation(loop: info.loop));
        newModules[bestModuleIndex] = m.copyWith(
          loopAllocations: updatedAllocations,
        );
      } else {
        // 需要建立新模組 - 計算剩餘同類型迴路所需的總通道數
        int remainingChannels = info.channels;
        for (int j = li + 1; j < loopInfos.length; j++) {
          final other = loopInfos[j];
          if (other.isRelay == info.isRelay) {
            remainingChannels += other.channels;
          }
        }

        final options = info.isRelay
            ? sortedRelayOptions
            : sortedDimmableOptions;
        final fallbackOptions = options.isEmpty
            ? (info.isRelay ? sortedDimmableOptions : sortedRelayOptions)
            : options;

        // 選擇策略：選能容納最多剩餘迴路的最大模組
        // 但如果剩餘通道數較少，則選剛好夠用的最小模組（避免浪費）
        ModuleOption? chosen;

        // 先按通道數降序嘗試（優先大模組）
        for (final opt in fallbackOptions) {
          if (opt.channelCount >= info.channels &&
              info.amperePerCh <= opt.maxAmperePerChannel &&
              info.ampere <= opt.maxAmpereTotal) {
            chosen ??= opt;
            // 如果有剛好夠裝所有剩餘迴路的模組，優先選它
            if (opt.channelCount >= remainingChannels) {
              chosen = opt;
            } else if (opt.channelCount < remainingChannels &&
                opt.channelCount >= info.channels) {
              // 不夠裝全部，但仍是可用的 → 選最大的
              // chosen 已經是最大的了，不用替換
            }
          }
        }

        // 如果找到的模組通道數大於剩餘所需的2倍，嘗試找更小但仍夠用的
        if (chosen != null && chosen.channelCount > remainingChannels * 2) {
          // 從小到大找一個剛好夠的
          for (final opt in fallbackOptions.reversed) {
            if (opt.channelCount >= remainingChannels &&
                info.amperePerCh <= opt.maxAmperePerChannel &&
                info.ampere <= opt.maxAmpereTotal) {
              chosen = opt;
              break;
            }
          }
        }

        if (chosen != null) {
          final newModule = Module(
            model: chosen.model,
            brand: chosen.brand,
            channelCount: chosen.channelCount,
            isDimmable: chosen.isDimmable,
            maxAmperePerChannel: chosen.maxAmperePerChannel,
            maxAmpereTotal: chosen.maxAmpereTotal,
            price: chosen.price,
            loopAllocations: [LoopAllocation(loop: info.loop)],
          );
          newModules.add(newModule);
        } else {
          unassigned.add(info.loop);
        }
      }
    }

    // 顯示確認對話框
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('自動分配結果'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('將建立 ${newModules.length} 個模組：'),
                const SizedBox(height: 8),
                ...newModules.asMap().entries.map((entry) {
                  final m = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${m.brand.isNotEmpty ? "[${m.brand}] " : ""}${m.model}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '通道: ${m.usedChannels}/${m.channelCount}  '
                              '安培: ${m.totalMaxAmpere.toStringAsFixed(2)}/${m.maxAmpereTotal}A',
                              style: const TextStyle(fontSize: 12),
                            ),
                            ...m.loopAllocations.map(
                              (a) => Text(
                                '  • ${a.loop.name} (${a.loop.dimmingType}, ${a.loop.voltage}V)',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                if (unassigned.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '⚠ 以下迴路無法自動分配（沒有適合的模組選項）：',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  ...unassigned.map((l) => Text('  • ${l.name}')),
                ],
                const SizedBox(height: 12),
                const Text(
                  '此操作將清除現有的模組配置，確定要套用嗎？',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _modules.clear();
                  _modules.addAll(newModules);
                });
                _autoSave();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '已自動分配 ${_loops.length - unassigned.length} 個迴路到 ${newModules.length} 個模組'
                      '${unassigned.isNotEmpty ? "，${unassigned.length} 個迴路未分配" : ""}',
                    ),
                  ),
                );
              },
              child: const Text('套用'),
            ),
          ],
        );
      },
    );
  }

  // 依空間分組的自動分配
  void _runAutoAssignBySpace(String? brandFilter) {
    final quoteService = Provider.of<QuoteService>(context, listen: false);
    final allModuleOptions = quoteService.moduleOptions;

    // 根據廠牌篩選模組選項
    final moduleOptions = brandFilter == null
        ? allModuleOptions
        : allModuleOptions.where((o) => o.brand == brandFilter).toList();

    if (moduleOptions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('該廠牌沒有可用的模組選項')));
      return;
    }

    // 輔助函數
    int getChannelsPerLoop(String dimmingType) {
      switch (dimmingType) {
        case 'WRGB':
          return 4;
        case 'RGB':
          return 3;
        case '雙色溫':
          return 2;
        case '單色溫':
        case '繼電器':
          return 1;
        default:
          return 1;
      }
    }

    double getLoopAmpere(Loop loop) {
      final totalWatt = loop.fixtures.fold(0, (sum, f) => sum + f.totalWatt);
      return loop.voltage > 0 ? totalWatt / loop.voltage : 0;
    }

    double getLoopAmperePerChannel(Loop loop) {
      final channels = getChannelsPerLoop(loop.dimmingType);
      return channels > 0 ? getLoopAmpere(loop) / channels : 0;
    }

    bool isRelayLoop(Loop loop) => loop.dimmingType == '繼電器';

    final sortedDimmableOptions =
        moduleOptions.where((o) => o.isDimmable).toList()
          ..sort((a, b) => b.channelCount.compareTo(a.channelCount));
    final sortedRelayOptions =
        moduleOptions.where((o) => !o.isDimmable).toList()
          ..sort((a, b) => b.channelCount.compareTo(a.channelCount));

    // 按空間分組迴路
    final spaceLoopsMap = <String, List<Loop>>{};
    for (final loop in _loops) {
      final space = loop.space;
      spaceLoopsMap.putIfAbsent(space, () => []).add(loop);
    }

    // 保持空間順序與 _spaces 一致
    final orderedSpaces = <String>[];
    for (final space in _spaces) {
      if (spaceLoopsMap.containsKey(space)) {
        orderedSpaces.add(space);
      }
    }
    // 加入不在 _spaces 中的空間
    for (final space in spaceLoopsMap.keys) {
      if (!orderedSpaces.contains(space)) {
        orderedSpaces.add(space);
      }
    }

    final allNewModules = <Module>[];
    final allUnassigned = <Loop>[];
    // 記錄每個模組屬於哪個空間（用於結果顯示）
    final moduleSpaceMap = <int, String>{};

    for (final space in orderedSpaces) {
      final spaceLoops = spaceLoopsMap[space]!;

      // 對此空間的迴路排序（大迴路優先）
      spaceLoops.sort((a, b) {
        final channelsA = getChannelsPerLoop(a.dimmingType);
        final channelsB = getChannelsPerLoop(b.dimmingType);
        if (channelsA != channelsB) return channelsB.compareTo(channelsA);
        return getLoopAmpere(b).compareTo(getLoopAmpere(a));
      });

      final loopInfos = spaceLoops
          .map(
            (loop) => LoopInfo(
              loop: loop,
              channels: getChannelsPerLoop(loop.dimmingType),
              ampere: getLoopAmpere(loop),
              amperePerCh: getLoopAmperePerChannel(loop),
              isRelay: isRelayLoop(loop),
            ),
          )
          .toList();

      // 此空間獨立的模組列表
      final spaceModules = <Module>[];

      for (int li = 0; li < loopInfos.length; li++) {
        final info = loopInfos[li];

        // 嘗試放進此空間已建立的模組（Best Fit）
        int bestModuleIndex = -1;
        int bestAvailable = 999;

        for (int i = 0; i < spaceModules.length; i++) {
          final m = spaceModules[i];
          if (info.isRelay && m.isDimmable) continue;
          if (!info.isRelay && !m.isDimmable) continue;

          if (m.availableChannels >= info.channels &&
              info.amperePerCh <= m.maxAmperePerChannel &&
              m.totalMaxAmpere + info.ampere <= m.maxAmpereTotal) {
            if (m.availableChannels < bestAvailable) {
              bestAvailable = m.availableChannels;
              bestModuleIndex = i;
            }
          }
        }

        if (bestModuleIndex >= 0) {
          final m = spaceModules[bestModuleIndex];
          final updatedAllocations = List<LoopAllocation>.from(
            m.loopAllocations,
          )..add(LoopAllocation(loop: info.loop));
          spaceModules[bestModuleIndex] = m.copyWith(
            loopAllocations: updatedAllocations,
          );
        } else {
          // 建立新模組 - 計算此空間剩餘同類型迴路所需通道數
          int remainingChannels = info.channels;
          for (int j = li + 1; j < loopInfos.length; j++) {
            final other = loopInfos[j];
            if (other.isRelay == info.isRelay) {
              remainingChannels += other.channels;
            }
          }

          final options = info.isRelay
              ? sortedRelayOptions
              : sortedDimmableOptions;
          final fallbackOptions = options.isEmpty
              ? (info.isRelay ? sortedDimmableOptions : sortedRelayOptions)
              : options;

          ModuleOption? chosen;
          for (final opt in fallbackOptions) {
            if (opt.channelCount >= info.channels &&
                info.amperePerCh <= opt.maxAmperePerChannel &&
                info.ampere <= opt.maxAmpereTotal) {
              chosen ??= opt;
              if (opt.channelCount >= remainingChannels) {
                chosen = opt;
              }
            }
          }

          if (chosen != null && chosen.channelCount > remainingChannels * 2) {
            for (final opt in fallbackOptions.reversed) {
              if (opt.channelCount >= remainingChannels &&
                  info.amperePerCh <= opt.maxAmperePerChannel &&
                  info.ampere <= opt.maxAmpereTotal) {
                chosen = opt;
                break;
              }
            }
          }

          if (chosen != null) {
            final newModule = Module(
              model: chosen.model,
              brand: chosen.brand,
              channelCount: chosen.channelCount,
              isDimmable: chosen.isDimmable,
              maxAmperePerChannel: chosen.maxAmperePerChannel,
              maxAmpereTotal: chosen.maxAmpereTotal,
              price: chosen.price,
              loopAllocations: [LoopAllocation(loop: info.loop)],
            );
            spaceModules.add(newModule);
          } else {
            allUnassigned.add(info.loop);
          }
        }
      }

      // 將此空間的模組加入總列表，並記錄空間
      for (final m in spaceModules) {
        moduleSpaceMap[allNewModules.length] = space;
        allNewModules.add(m);
      }
    }

    // 顯示確認對話框
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('自動分配結果（依空間分組）'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '將建立 ${allNewModules.length} 個模組（${orderedSpaces.length} 個空間）：',
                ),
                const SizedBox(height: 8),
                ...orderedSpaces.map((space) {
                  // 找出屬於此空間的模組
                  final spaceModuleEntries = allNewModules
                      .asMap()
                      .entries
                      .where((e) => moduleSpaceMap[e.key] == space)
                      .toList();
                  if (spaceModuleEntries.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '📍 $space',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...spaceModuleEntries.map((entry) {
                        final m = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${m.brand.isNotEmpty ? "[${m.brand}] " : ""}${m.model}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '通道: ${m.usedChannels}/${m.channelCount}  '
                                    '安培: ${m.totalMaxAmpere.toStringAsFixed(2)}/${m.maxAmpereTotal}A',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  ...m.loopAllocations.map(
                                    (a) => Text(
                                      '  • ${a.loop.name} (${a.loop.dimmingType}, ${a.loop.voltage}V)',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  );
                }),
                if (allUnassigned.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '⚠ 以下迴路無法自動分配（沒有適合的模組選項）：',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  ...allUnassigned.map((l) => Text('  • ${l.name}')),
                ],
                const SizedBox(height: 12),
                const Text(
                  '此操作將清除現有的模組配置，確定要套用嗎？',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _modules.clear();
                  _modules.addAll(allNewModules);
                });
                _autoSave();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '已依空間分組分配 ${_loops.length - allUnassigned.length} 個迴路到 ${allNewModules.length} 個模組'
                      '${allUnassigned.isNotEmpty ? "，${allUnassigned.length} 個迴路未分配" : ""}',
                    ),
                  ),
                );
              },
              child: const Text('套用'),
            ),
          ],
        );
      },
    );
  }

  void _createNewConfiguration() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建估價配置'),
        content: const Text('確定要新建配置嗎？這將清除所有當前數據。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // 重置所有數據
                _loops.clear();
                _modules.clear();
                _switchCountController.clear();
                _otherDevices.clear();
                _powerSupplies.clear();
                _boardMaterials.clear();
                _wiringItems.clear();
                _spaces.clear();
                _spaces.add('未分類');
                // reset style options
                _ceilingHasLn = false;
                _ceilingHasMaintenanceHole = false;
                _switchHasLn = false;
                _currentConfigurationName = '新估價配置';
                _selectedConfigurationName = null; // 重置下拉選單選擇狀態
                _currentStep = 0; // 返回第一步
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('已新建配置')));
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  void _saveConfiguration() async {
    _saveSwitchConfigurations();
    final TextEditingController nameController = TextEditingController(
      text: _currentConfigurationName,
    );
    final TextEditingController projectNameController = TextEditingController();
    final TextEditingController projectAddressController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('儲存估價配置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '配置名稱',
                hintText: '輸入配置名稱',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: projectNameController,
              decoration: const InputDecoration(
                labelText: '項目名稱 (選填)',
                hintText: '輸入項目名稱',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: projectAddressController,
              decoration: const InputDecoration(
                labelText: '項目地址 (選填)',
                hintText: '輸入項目地址',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                setState(() => _isLoading = true);
                try {
                  final quoteData = QuoteData(
                    switches: _switches,
                    loops: _loops,
                    modules: _modules,
                    switchCount: _switchCountController.text,
                    otherDevices: _otherDevices,
                    powerSupplies: _powerSupplies,
                    boardMaterials: _boardMaterials,
                    wiring: _wiringItems,
                    ceilingHasLn: _ceilingHasLn,
                    ceilingHasMaintenanceHole: _ceilingHasMaintenanceHole,
                    switchHasLn: _switchHasLn,
                  );

                  final authService = Provider.of<AuthService>(
                    context,
                    listen: false,
                  );
                  final effectiveCustomerId = authService.isCustomer
                      ? int.tryParse(authService.userId ?? '')
                      : _selectedCustomer?.userId;

                  await _quoteService.saveConfiguration(
                    nameController.text.trim(),
                    quoteData,
                    customerUserId: effectiveCustomerId,
                    projectName: projectNameController.text.trim().isNotEmpty
                        ? projectNameController.text.trim()
                        : null,
                    projectAddress:
                        projectAddressController.text.trim().isNotEmpty
                        ? projectAddressController.text.trim()
                        : null,
                  );
                  _currentConfigurationName = nameController.text.trim();
                  _loadConfigurations(); // 刷新配置列表
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('配置已儲存')));
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('儲存失敗: $e')));
                } finally {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }

  void _loadConfigurations() async {
    try {
      await _quoteService.fetchConfigurations();
      await _quoteService.fetchModuleOptions();
      final rawPowerSupplyOptions = await _quoteService
          .fetchAllPowerSupplyOptions();
      await _quoteService.fetchFixtureTypeOptions();
      setState(() {
        _powerSupplyOptions = rawPowerSupplyOptions
            .map(
              (item) => PowerSupply(
                name: item['name']?.toString() ?? '',
                wattage: (item['wattage'] ?? 0).toDouble(),
                type: item['type']?.toString() ?? 'UHP',
                inputVoltage:
                    int.tryParse(
                      (item['inputVoltage'] ?? item['input_voltage'] ?? 110)
                          .toString(),
                    ) ??
                    110,
                price: (item['price'] ?? 0).toDouble(),
              ),
            )
            .toList();
      });
    } catch (e) {
      // 静默处理错误，用户可以稍後重试
      print('載入配置列表失敗: $e');
    }
  }

  double _calculateModuleRequiredWatt(Module module) {
    double total = 0;

    for (final allocation in module.loopAllocations) {
      final count = allocation.allocatedCount <= 0
          ? 1
          : allocation.allocatedCount;
      total += allocation.loop.totalWatt * count;
    }

    if (total <= 0) {
      for (final allocation in module.allocations) {
        total += allocation.fixture.watt * allocation.allocatedCount;
      }
    }

    return total;
  }

  void _showAutoAssignPowerSuppliesDialog() {
    if (_modules.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('沒有模組可分配，請先完成模組配置')));
      return;
    }

    if (_powerSupplyOptions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('沒有可用電源選項，請聯繫管理員建立')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        String selectedType = 'UHP';
        bool allow110 = true;
        bool allow220 = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('自動分配電源供應器'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('每個模組將自動分配 1 個最小可用瓦數的電源供應器'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: '電源類型',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'UHP', child: Text('UHP (預設)')),
                      DropdownMenuItem(value: 'HLG', child: Text('HLG')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedType = value ?? 'UHP';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('交流電電供（可複選）：'),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: allow110,
                    title: const Text('110V'),
                    onChanged: (value) {
                      setDialogState(() {
                        allow110 = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: allow220,
                    title: const Text('220V'),
                    onChanged: (value) {
                      setDialogState(() {
                        allow220 = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!allow110 && !allow220) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('請至少勾選一種輸入電壓（110 或 220）')),
                      );
                      return;
                    }
                    Navigator.of(context).pop();
                    _autoAssignPowerSupplies(
                      selectedType: selectedType,
                      allow110: allow110,
                      allow220: allow220,
                    );
                  },
                  child: const Text('開始分配'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _autoAssignPowerSupplies({
    required String selectedType,
    required bool allow110,
    required bool allow220,
  }) {
    final allowedInputs = <int>{if (allow110) 110, if (allow220) 220};

    final candidates =
        _powerSupplyOptions
            .where(
              (option) =>
                  option.type.toUpperCase() == selectedType.toUpperCase() &&
                  allowedInputs.contains(option.inputVoltage),
            )
            .toList()
          ..sort((a, b) {
            final wattCompare = a.wattage.compareTo(b.wattage);
            if (wattCompare != 0) return wattCompare;
            return a.price.compareTo(b.price);
          });

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('找不到符合條件的 $selectedType 電源選項')));
      return;
    }

    final assigned = <PowerSupply>[];
    final assignmentPairs = <Map<String, dynamic>>[];
    final unassignedModules = <Map<String, dynamic>>[];

    for (final module in _modules) {
      final requiredWatt = _calculateModuleRequiredWatt(module);
      PowerSupply? chosen;

      for (final option in candidates) {
        if (option.wattage >= requiredWatt) {
          chosen = PowerSupply(
            name: option.name,
            wattage: option.wattage,
            type: option.type,
            inputVoltage: option.inputVoltage,
            price: option.price,
          );
          break;
        }
      }

      if (chosen != null) {
        assigned.add(chosen);
        assignmentPairs.add({'module': module, 'supply': chosen});
      } else {
        unassignedModules.add({'module': module, 'requiredWatt': requiredWatt});
      }
    }

    setState(() {
      _powerSupplies = assigned;
    });
    _autoSave();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('電源自動分配結果'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('已成功分配 ${assigned.length}/${_modules.length} 個模組'),
              const SizedBox(height: 8),
              ...assignmentPairs.map((pair) {
                final module = pair['module'] as Module;
                final supply = pair['supply'] as PowerSupply;
                return Text(
                  '• ${module.model} → ${supply.name} (${supply.type}, ${supply.inputVoltage}V, ${supply.wattage.toStringAsFixed(0)}W)',
                );
              }),
              if (unassignedModules.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '以下模組未分配成功：',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                ...unassignedModules.map((item) {
                  final module = item['module'] as Module;
                  final requiredWatt = item['requiredWatt'] as double;
                  return Text(
                    '• ${module.model} 需要 ${requiredWatt.toStringAsFixed(0)}W',
                  );
                }),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  void _loadCustomers() async {
    try {
      await _customerService.fetchCustomers();
    } catch (e) {
      print('載入客戶列表失敗: $e');
    }
  }

  void _loadSelectedConfiguration(String configName) async {
    final previousConfigName = _currentConfigurationName;
    setState(() => _isLoading = true);
    try {
      final quoteData = await _quoteService.loadConfiguration(configName);
      if (quoteData != null) {
        setState(() {
          _loops.clear();
          _loops.addAll(quoteData.loops);
          _modules.clear();
          _modules.addAll(quoteData.modules);
          _switchCountController.text = quoteData.switchCount;
          _otherDevices = List<OtherDevice>.from(quoteData.otherDevices);
          _powerSupplies = List<PowerSupply>.from(quoteData.powerSupplies);
          _boardMaterials = List<MaterialItem>.from(quoteData.boardMaterials);
          _wiringItems = List<MaterialItem>.from(quoteData.wiring);
          // restore new style options
          _ceilingHasLn = quoteData.ceilingHasLn;
          _ceilingHasMaintenanceHole = quoteData.ceilingHasMaintenanceHole;
          _switchHasLn = quoteData.switchHasLn;
          _currentConfigurationName = configName;
          _currentStep = 0; // 回到起始步驟

          // 載入開關資料
          _switches.clear();
          _switches.addAll(quoteData.switches);

          // 從迴路重建空間列表
          _spaces.clear();
          _spaces.add('未分類');
          _rebuildSpacesFromLoops();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('配置已載入')));
      }
    } catch (e) {
      // 載入失敗時恢復之前的配置名稱
      setState(() {
        _currentConfigurationName = previousConfigName;
        _selectedConfigurationName = null; // 重置下拉選單選擇狀態
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('載入失敗: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDeleteConfirmation(String configName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除配置 "$configName" 嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteSelectedConfiguration(configName);
    }
  }

  void _deleteSelectedConfiguration(String configName) async {
    setState(() => _isLoading = true);
    try {
      await _quoteService.deleteConfiguration(configName);
      // 重置當前狀態
      setState(() {
        _currentConfigurationName = '新估價配置';
        _selectedConfigurationName = null;
        _loops.clear();
        _modules.clear();
        _spaces.clear();
        _spaces.add('未分類');
        _ceilingHasLn = false;
        _ceilingHasMaintenanceHole = false;
        _switchHasLn = false;
        _currentStep = 0;
      });
      // 重新載入配置列表
      _loadConfigurations();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('配置已刪除')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('刪除失敗: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

// 已移至 models/loop_info.dart
