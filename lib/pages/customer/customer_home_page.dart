import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/widgets/app_drawer.dart';
import 'package:universal_html/html.dart' as html;
import 'package:coselig_staff_portal/services/quote_service.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:coselig_staff_portal/models/quote_models.dart';
import 'package:provider/provider.dart';
import 'widgets/step1_widget.dart';
import 'widgets/step2_widget.dart';
import 'widgets/step3_widget.dart';
import 'widgets/add_loop_dialog.dart';
import 'widgets/add_module_dialog.dart';
import 'widgets/add_fixture_dialog.dart';
import 'widgets/quote_result_dialog.dart';
import 'widgets/edit_loop_dialog.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _currentStep = 0;

  // 第一步：迴路+設備配置
  final List<Loop> _loops = [];
  final TextEditingController _switchCountController = TextEditingController();
  final TextEditingController _otherDevicesController = TextEditingController();

  // 第二步：模組配置
  final List<LightFixture> _lightFixtures = [];
  final List<Module> _modules = [];

  // 第三步：材料配置
  final TextEditingController _powerSupplyController = TextEditingController();
  final TextEditingController _boardMaterialsController =
      TextEditingController();
  final TextEditingController _wiringController = TextEditingController();

  late QuoteService _quoteService;
  String _currentConfigurationName = '新估價配置';
  String? _selectedConfigurationName; // 追蹤下拉選單中選中的配置
  bool _isLoading = false;
  List<QuoteConfiguration> _configurations = [];

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    html.document.title = authService.isCustomer ? '光悅顧客系統' : '光悅員工系統 - 估價系統';
    _quoteService = Provider.of<QuoteService>(context, listen: false);
    _loadConfigurations();
  }

  @override
  void dispose() {
    _switchCountController.dispose();
    _otherDevicesController.dispose();
    _powerSupplyController.dispose();
    _boardMaterialsController.dispose();
    _wiringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.calculate, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('估價系統'),
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
            IconButton(
              icon: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: _createNewConfiguration,
              tooltip: '新建配置',
            ),
            IconButton(
              icon: Icon(
                Icons.save,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: _saveConfiguration,
              tooltip: '儲存配置',
            ),
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
            if (_configurations.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButton<String>(
                  value: _selectedConfigurationName,
                  hint: Row(
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 18,
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
                    return _configurations.map((config) {
                      return Row(
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            config.name,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
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
                  items: _configurations.map((config) {
                    return DropdownMenuItem<String>(
                      value: config.name,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              config.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              config.updatedAt,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
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
            else
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: _loadConfigurations,
                tooltip: '重新載入配置列表',
              ),
            if (_configurations.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButton<String>(
                  value: null,
                  hint: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '刪除配置',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  underline: const SizedBox(),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  items: _configurations.map((config) {
                    return DropdownMenuItem<String>(
                      value: config.name,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              config.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              config.updatedAt,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? configName) {
                    if (configName != null) {
                      _showDeleteConfirmation(configName);
                    }
                  },
                ),
              )
            else
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.outline,
                ),
                onPressed: null,
                tooltip: '無配置可刪除',
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
                if (_currentStep < 2) {
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
                      otherDevices: _otherDevicesController.text,
                      powerSupply: _powerSupplyController.text,
                      boardMaterials: _boardMaterialsController.text,
                      wiring: _wiringController.text,
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
                  child: Row(
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
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      if (_currentStep > 0 && _currentStep < 2)
                        const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: details.onStepContinue,
                          icon: _currentStep < 2
                              ? const Icon(Icons.arrow_forward)
                              : const Icon(Icons.calculate),
                          label: Text(_currentStep < 2 ? '下一步' : '生成報價'),
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
                  ),
                );
              },
              steps: [
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
                    child: Step1Widget(
                      loops: _loops,
                      switchCountController: _switchCountController,
                      otherDevicesController: _otherDevicesController,
                      onAddLoop: _showAddLoopDialog,
                      onRemoveLoop: _removeLoop,
                      onUpdateLoop: _updateLoop,
                      onAddFixtureToLoop: _showAddFixtureDialog,
                      onRemoveFixtureFromLoop: _removeFixtureFromLoop,
                    ),
                  ),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0
                      ? StepState.complete
                      : StepState.indexed,
                ),
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
                    child: Step2Widget(
                      modules: _modules,
                      onAddModule: _showAddModuleDialog,
                      onRemoveModule: _removeModule,
                      onAssignLoopToModule: _assignLoopToModule,
                      onRemoveLoopFromModule: _removeLoopFromModule,
                      onEditLoopInModule: _showEditLoopDialog,
                      unassignedLoops: _getUnassignedLoops(),
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
                    child: Step3Widget(
                      powerSupplyController: _powerSupplyController,
                      boardMaterialsController: _boardMaterialsController,
                      wiringController: _wiringController,
                    ),
                  ),
                  isActive: _currentStep >= 2,
                  state: _currentStep == 2
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
        },
      ),
    );
  }

  void _removeModule(int index) {
    setState(() {
      _modules.removeAt(index);
    });
  }

  void _showAddLoopDialog() {
    showDialog(
      context: context,
      builder: (context) => AddLoopDialog(
        onAddLoop: (name) {
          setState(() {
            _loops.add(Loop(name: name));
          });
        },
      ),
    );
  }

  // 更新迴路
  void _updateLoop(int index, Loop updatedLoop) {
    setState(() {
      _loops[index] = updatedLoop;
    });
  }

  // 刪除迴路
  void _removeLoop(int index) {
    setState(() {
      _loops.removeAt(index);
    });
  }

  // 向迴路添加燈具
  void _showAddFixtureDialog(int loopIndex) {
    showDialog(
      context: context,
      builder: (context) => AddFixtureDialog(
        onAddFixture: (name, totalWatt) {
          setState(() {
            final loop = _loops[loopIndex];
            final updatedFixtures = List<LoopFixture>.from(loop.fixtures)
              ..add(LoopFixture(name: name, totalWatt: totalWatt));
            _loops[loopIndex] = loop.copyWith(fixtures: updatedFixtures);
          });
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
  void _assignLoopToModule(int moduleIndex, Loop loop) {
    setState(() {
      final module = _modules[moduleIndex];
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
            final updatedLoopAllocations = List<LoopAllocation>.from(module.loopAllocations);
            updatedLoopAllocations[allocationIndex] = updatedAllocation;
            _modules[moduleIndex] = module.copyWith(loopAllocations: updatedLoopAllocations);
          });
        },
      ),
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
                _otherDevicesController.clear();
                _powerSupplyController.clear();
                _boardMaterialsController.clear();
                _wiringController.clear();
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
    final TextEditingController nameController = TextEditingController(
      text: _currentConfigurationName,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('儲存估價配置'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '配置名稱',
            hintText: '輸入配置名稱',
          ),
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
                    loops: _loops,
                    modules: _modules,
                    switchCount: _switchCountController.text,
                    otherDevices: _otherDevicesController.text,
                    powerSupply: _powerSupplyController.text,
                    boardMaterials: _boardMaterialsController.text,
                    wiring: _wiringController.text,
                  );

                  await _quoteService.saveConfiguration(
                    nameController.text.trim(),
                    quoteData,
                  );
                  _currentConfigurationName = nameController.text.trim();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('配置已儲存')));
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
      setState(() {
        _configurations = _quoteService.configurations;
      });
    } catch (e) {
      // 靜默處理錯誤，用戶可以稍後重試
      print('載入配置列表失敗: $e');
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
          _otherDevicesController.text = quoteData.otherDevices;
          _powerSupplyController.text = quoteData.powerSupply;
          _boardMaterialsController.text = quoteData.boardMaterials;
          _wiringController.text = quoteData.wiring;
          _currentConfigurationName = configName;
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
      // 重新載入配置列表
      _loadConfigurations();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('配置已刪除')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('刪除失敗: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}