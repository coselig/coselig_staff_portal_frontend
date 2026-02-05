import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/widgets/app_drawer.dart';
import 'package:universal_html/html.dart' as html;
import 'package:coselig_staff_portal/services/quote_service.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    html.document.title = '光悅顧客系統';
    _quoteService = Provider.of<QuoteService>(context, listen: false);
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
        title: const Text('估價系統'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveConfiguration,
            tooltip: '儲存配置',
          ),
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: _isLoading ? null : _loadConfiguration,
            tooltip: '載入配置',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _deleteConfiguration,
            tooltip: '刪除配置',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Stepper(
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
        steps: [
          Step(
            title: const Text('第一步：迴路+設備配置'),
            content: Step1Widget(
              loops: _loops,
              switchCountController: _switchCountController,
              otherDevicesController: _otherDevicesController,
              onAddLoop: _showAddLoopDialog,
              onRemoveLoop: _removeLoop,
              onUpdateLoop: _updateLoop,
              onAddFixtureToLoop: _showAddFixtureDialog,
              onRemoveFixtureFromLoop: _removeFixtureFromLoop,
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('第二步：模組配置'),
            content: Step2Widget(
              modules: _modules,
              onAddModule: _showAddModuleDialog,
              onRemoveModule: _removeModule,
              onAssignLoopToModule: _assignLoopToModule,
              onRemoveLoopFromModule: _removeLoopFromModule,
              onEditLoopInModule: _showEditLoopDialog,
              unassignedLoops: _getUnassignedLoops(),
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('第三步：材料配置'),
            content: Step3Widget(
              powerSupplyController: _powerSupplyController,
              boardMaterialsController: _boardMaterialsController,
              wiringController: _wiringController,
            ),
            isActive: _currentStep >= 2,
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

  void _loadConfiguration() async {
    setState(() => _isLoading = true);
    try {
      await _quoteService.fetchConfigurations();
      final configurations = _quoteService.configurations;

      if (configurations.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('沒有可用的配置')));
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('載入估價配置'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: configurations.length,
              itemBuilder: (context, index) {
                final config = configurations[index];
                return ListTile(
                  title: Text(config.name),
                  subtitle: Text('${config.chineseName} - ${config.updatedAt}'),
                  onTap: () async {
                    try {
                      final quoteData = await _quoteService.loadConfiguration(
                        config.name,
                      );
                      if (quoteData != null) {
                        setState(() {
                          _loops.clear();
                          _loops.addAll(quoteData.loops);
                          _modules.clear();
                          _modules.addAll(quoteData.modules);
                          _switchCountController.text = quoteData.switchCount;
                          _otherDevicesController.text = quoteData.otherDevices;
                          _powerSupplyController.text = quoteData.powerSupply;
                          _boardMaterialsController.text =
                              quoteData.boardMaterials;
                          _wiringController.text = quoteData.wiring;
                          _currentConfigurationName = config.name;
                        });
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('配置已載入')));
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('載入失敗: $e')));
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('載入配置列表失敗: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _deleteConfiguration() async {
    setState(() => _isLoading = true);
    try {
      await _quoteService.fetchConfigurations();
      final configurations = _quoteService.configurations;

      if (configurations.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('沒有可用的配置')));
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('刪除估價配置'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: configurations.length,
              itemBuilder: (context, index) {
                final config = configurations[index];
                return ListTile(
                  title: Text(config.name),
                  subtitle: Text('${config.chineseName} - ${config.updatedAt}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('確認刪除'),
                          content: Text('確定要刪除配置 "${config.name}" 嗎？'),
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
                        try {
                          await _quoteService.deleteConfiguration(config.name);
                          Navigator.of(
                            context,
                          ).pop(); // Close the delete dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('配置已刪除')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('刪除失敗: $e')));
                        }
                      }
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('關閉'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('載入配置列表失敗: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}