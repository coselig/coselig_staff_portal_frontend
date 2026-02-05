import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coselig_staff_portal/widgets/app_drawer.dart';
import 'package:universal_html/html.dart' as html;
import 'package:coselig_staff_portal/services/quote_service.dart';
import 'package:coselig_staff_portal/models/quote_models.dart';
import 'package:provider/provider.dart';

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
            icon: const Icon(Icons.folder_open),
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
            _showQuoteResult();
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
            content: _buildStep1(),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('第二步：模組配置'),
            content: _buildStep2(),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('第三步：材料配置'),
            content: _buildStep3(),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '迴路配置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 添加迴路按鈕
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '已配置迴路',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _addLoop,
              icon: const Icon(Icons.add),
              label: const Text('添加迴路'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 迴路列表
        if (_loops.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                '尚未添加任何迴路\n點擊上方按鈕添加第一個迴路',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          )
        else
          ..._loops.asMap().entries.map((entry) {
            final index = entry.key;
            final loop = entry.value;
            return _buildLoopCard(index, loop);
          }),

        const SizedBox(height: 24),
        const Text(
          '開關配置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _switchCountController,
          decoration: const InputDecoration(
            labelText: '開關數量',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 24),
        const Text(
          '其他設備',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _otherDevicesController,
          decoration: const InputDecoration(
            labelText: '其他感應器、設備 (例如：冷氣、窗簾等)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '模組配置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '已配置模組',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _addModule,
              icon: const Icon(Icons.add),
              label: const Text('添加模組'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_modules.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                '尚未添加任何模組\n點擊上方按鈕添加第一個模組',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          )
        else
          ..._modules.asMap().entries.map((entry) {
            final index = entry.key;
            final module = entry.value;
            return _buildModuleCard(index, module);
          }),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '材料配置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _powerSupplyController,
          decoration: const InputDecoration(
            labelText: '電源供應配置',
            border: OutlineInputBorder(),
            hintText: '例如：12V/5A電源供應器 x 2',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _boardMaterialsController,
          decoration: const InputDecoration(
            labelText: '板材、配電箱配置',
            border: OutlineInputBorder(),
            hintText: '例如：配電箱 400x300x150mm x 1',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _wiringController,
          decoration: const InputDecoration(
            labelText: '線材配置',
            border: OutlineInputBorder(),
            hintText: '例如：2.5mm²電線 50m, 1.5mm²電線 30m',
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  void _showQuoteResult() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('估價摘要'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '設備配置：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '開關：${_switchCountController.text.isNotEmpty ? '${_switchCountController.text}個' : '未配置'}',
              ),
              if (_otherDevicesController.text.isNotEmpty)
                Text('其他設備：${_otherDevicesController.text}'),
              const SizedBox(height: 16),
              const Text(
                '迴路配置：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_loops.isEmpty)
                const Text('尚未配置任何迴路')
              else ...[
                Text('總共 ${_loops.length} 個迴路：'),
                const SizedBox(height: 8),
                ..._loops.map(
                  (loop) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ${loop.name} (${loop.voltage}V, ${loop.dimmingType}, 總瓦數: ${loop.totalWatt}W)',
                      ),
                      if (loop.fixtures.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ...loop.fixtures.map(
                          (fixture) => Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              '- ${fixture.name}: ${fixture.totalWatt}W',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                '燈具配置：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_lightFixtures.isNotEmpty) ...[
                const Text(
                  '燈具：',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                ..._lightFixtures.map(
                  (fixture) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Text(
                      '${fixture.name}：${fixture.count}個，${fixture.watt}W，${fixture.volt}V，${fixture.dimmingType}${fixture.needsRelay ? ' (${fixture.relayType})' : ''}',
                    ),
                  ),
                ),
              ] else
                const Text('燈具：未配置'),
              const SizedBox(height: 16),
              const Text(
                '模組配置：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_modules.isEmpty)
                const Text('尚未配置任何模組')
              else ...[
                Text('總共 ${_modules.length} 個模組：'),
                const SizedBox(height: 8),
                ..._modules.map(
                  (module) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ${module.model} (${module.channelCount}通道, ${module.isDimmable ? '可調光' : '繼電器控制'})',
                      ),
                      if (module.allocations.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ...module.allocations.map(
                          (allocation) => Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              '- ${allocation.fixture.name}: ${allocation.allocatedCount}個',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (_powerSupplyController.text.isNotEmpty)
                Text('電源：$_powerSupplyController.text'),
              if (_boardMaterialsController.text.isNotEmpty)
                Text('板材：$_boardMaterialsController.text'),
              if (_wiringController.text.isNotEmpty)
                Text('線材：$_wiringController.text'),
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

  void _addModule() {
    ModuleOption? selectedOption;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加新模組'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ModuleOption>(
                initialValue: selectedOption,
                decoration: const InputDecoration(
                  labelText: '選擇模組型號',
                  border: OutlineInputBorder(),
                ),
                items: moduleOptions.map((option) {
                  return DropdownMenuItem<ModuleOption>(
                    value: option,
                    child: Text(
                      '${option.model} - ${option.channelCount}通道 ${option.isDimmable ? '(可調光)' : '(繼電器)'}',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedOption = value;
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
              onPressed: selectedOption != null
                  ? () {
                      // 使用widget的setState來更新模組列表
                      this.setState(() {
                        _modules.add(
                          Module(
                            model: selectedOption!.model,
                            channelCount: selectedOption!.channelCount,
                            isDimmable: selectedOption!.isDimmable,
                          ),
                        );
                      });
                      Navigator.of(context).pop();
                    }
                  : null,
              child: const Text('確定'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeModule(int index) {
    setState(() {
      _modules.removeAt(index);
    });
  }

  // 添加迴路
  void _addLoop() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加新迴路'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '迴路名稱',
                border: OutlineInputBorder(),
                hintText: '例如：客廳主燈、廚房燈具',
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
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() {
                  _loops.add(Loop(name: nameController.text.trim()));
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
  // 構建迴路卡片
  Widget _buildLoopCard(int index, Loop loop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 迴路標題和刪除按鈕
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loop.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _removeLoop(index),
                  icon: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  tooltip: '刪除迴路',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 迴路設定
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: loop.voltage,
                    decoration: const InputDecoration(
                      labelText: '電壓 (V)',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 220, child: Text('220V')),
                      DropdownMenuItem(value: 110, child: Text('110V')),
                      DropdownMenuItem(value: 36, child: Text('36V')),
                      DropdownMenuItem(value: 24, child: Text('24V')),
                      DropdownMenuItem(value: 12, child: Text('12V')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _updateLoop(index, loop.copyWith(voltage: value));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: loop.dimmingType,
                    decoration: const InputDecoration(
                      labelText: '調光類型',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'WRGB', child: Text('WRGB')),
                      DropdownMenuItem(value: 'RGB', child: Text('RGB')),
                      DropdownMenuItem(value: '雙色溫', child: Text('雙色溫')),
                      DropdownMenuItem(value: '單色溫', child: Text('單色溫')),
                      DropdownMenuItem(value: '繼電器', child: Text('繼電器')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _updateLoop(index, loop.copyWith(dimmingType: value));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 總瓦數顯示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '總瓦數:',
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${loop.totalWatt} W',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 燈具列表
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '燈具 (${loop.fixtures.length} 個)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _addFixtureToLoop(index),
                  icon: const Icon(Icons.add),
                  label: const Text('添加燈具'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (loop.fixtures.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '尚未添加燈具',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              )
            else
              ...loop.fixtures.asMap().entries.map((entry) {
                final fixtureIndex = entry.key;
                final fixture = entry.value;
                return Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fixture.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${fixture.totalWatt} W',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _removeFixtureFromLoop(index, fixtureIndex),
                          icon: Icon(
                            Icons.remove_circle,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          iconSize: 20,
                          tooltip: '移除燈具',
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
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
  void _addFixtureToLoop(int loopIndex) {
    String selectedType = fixtureTypes[0]; // 預設選擇第一個
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController unitWattController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加燈具'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 燈具類型下拉選單
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: '燈具類型',
                  border: OutlineInputBorder(),
                ),
                items: fixtureTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedType = value!;
                    // 清空控制器以避免混亂
                    quantityController.clear();
                    unitWattController.clear();
                  });
                },
              ),
              const SizedBox(height: 16),

              // 燈具名稱輸入
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '燈具名稱',
                  border: const OutlineInputBorder(),
                  hintText: '例如：${selectedType}A區、${selectedType}B區',
                ),
              ),
              const SizedBox(height: 16),

              // 動態輸入欄位基於選擇的類型
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      decoration: InputDecoration(
                        labelText: fixtureTypeData[selectedType]!.quantityLabel,
                        border: const OutlineInputBorder(),
                        hintText: fixtureTypeData[selectedType]!.isMeterBased ? '例如：5' : '例如：3',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: unitWattController,
                      decoration: InputDecoration(
                        labelText: fixtureTypeData[selectedType]!.unitLabel,
                        border: const OutlineInputBorder(),
                        hintText: '例如：10',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),

              // 總瓦數顯示
              if (quantityController.text.isNotEmpty && unitWattController.text.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '總瓦數:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${_calculateTotalWatt(quantityController.text, unitWattController.text)} W',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
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
              onPressed: () {
                final name = nameController.text.trim();
                final quantity = int.tryParse(quantityController.text) ?? 0;
                final unitWatt = int.tryParse(unitWattController.text) ?? 0;
                final totalWatt = _calculateTotalWatt(quantityController.text, unitWattController.text);

                if (name.isNotEmpty && quantity > 0 && unitWatt > 0 && totalWatt > 0) {
                  this.setState(() {
                    final loop = _loops[loopIndex];
                    final updatedFixtures = List<LoopFixture>.from(loop.fixtures)
                      ..add(LoopFixture(name: name, totalWatt: totalWatt));
                    _loops[loopIndex] = loop.copyWith(fixtures: updatedFixtures);
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('確定'),
            ),
          ],
        ),
      ),
    );
  }

  // 計算總瓦數
  int _calculateTotalWatt(String quantityText, String unitWattText) {
    final quantity = int.tryParse(quantityText) ?? 0;
    final unitWatt = int.tryParse(unitWattText) ?? 0;
    return quantity * unitWatt;
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

  Widget _buildModuleCard(int index, Module module) {
    final unassignedLoops = _getUnassignedLoops();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${module.model} 模組',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _removeModule(index),
                  icon: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  tooltip: '刪除此模組',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '通道: ${module.usedChannels}/${module.channelCount} (可用: ${module.availableChannels})',
              style: TextStyle(
                color: module.availableChannels > 0
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              module.isDimmable ? '可調光' : '繼電器控制',
              style: TextStyle(
                color: module.isDimmable
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 16),

            // 已分配的迴路
            if (module.loopAllocations.isNotEmpty) ...[
              const Text(
                '已分配迴路:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...module.loopAllocations.asMap().entries.map((entry) {
                final allocationIndex = entry.key;
                final allocation = entry.value;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '• ${allocation.loop.name} (${allocation.loop.voltage}V, ${allocation.loop.dimmingType})',
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () =>
                              _editLoopInModule(index, allocationIndex),
                          icon: Icon(
                            Icons.edit,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          iconSize: 20,
                          tooltip: '編輯此迴路',
                        ),
                        IconButton(
                          onPressed: () =>
                              _removeLoopFromModule(index, allocationIndex),
                          icon: Icon(
                            Icons.remove_circle,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          iconSize: 20,
                          tooltip: '移除此分配',
                        ),
                      ],
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
            ],

            // 添加迴路按鈕
            if (module.availableChannels > 0 && unassignedLoops.isNotEmpty) ...[
              const Text(
                '添加迴路:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: unassignedLoops
                    .where((loop) => module.canAssignLoop(loop, 1))
                    .map((loop) {
                      return ElevatedButton(
                        onPressed: () => _assignLoopToModule(index, loop),
                        child: Text(
                          '${loop.name} (${loop.voltage}V, ${loop.dimmingType})',
                        ),
                      );
                    })
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
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
  void _editLoopInModule(int moduleIndex, int allocationIndex) {
    final module = _modules[moduleIndex];
    final allocation = module.loopAllocations[allocationIndex];
    final loop = allocation.loop;

    final TextEditingController nameController = TextEditingController(
      text: loop.name,
    );
    int selectedVoltage = loop.voltage;
    String selectedDimmingType = loop.dimmingType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('編輯迴路'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '迴路名稱',
                  border: OutlineInputBorder(),
                  hintText: '例如：客廳主燈、廚房燈具',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: selectedVoltage,
                decoration: const InputDecoration(
                  labelText: '電壓 (V)',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 220, child: Text('220V')),
                  DropdownMenuItem(value: 110, child: Text('110V')),
                  DropdownMenuItem(value: 36, child: Text('36V')),
                  DropdownMenuItem(value: 24, child: Text('24V')),
                  DropdownMenuItem(value: 12, child: Text('12V')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedVoltage = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedDimmingType,
                decoration: const InputDecoration(
                  labelText: '調光類型',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'WRGB', child: Text('WRGB')),
                  DropdownMenuItem(value: 'RGB', child: Text('RGB')),
                  DropdownMenuItem(value: '雙色溫', child: Text('雙色溫')),
                  DropdownMenuItem(value: '單色溫', child: Text('單色溫')),
                  DropdownMenuItem(value: '繼電器', child: Text('繼電器')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedDimmingType = value!;
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
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  this.setState(() {
                    final updatedLoop = loop.copyWith(
                      name: name,
                      voltage: selectedVoltage,
                      dimmingType: selectedDimmingType,
                    );
                    final updatedAllocation = allocation.copyWith(
                      loop: updatedLoop,
                    );
                    final updatedLoopAllocations = List<LoopAllocation>.from(
                      module.loopAllocations,
                    );
                    updatedLoopAllocations[allocationIndex] = updatedAllocation;
                    _modules[moduleIndex] = module.copyWith(
                      loopAllocations: updatedLoopAllocations,
                    );
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('確定'),
            ),
          ],
        ),
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