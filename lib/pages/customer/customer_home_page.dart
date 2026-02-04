import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coselig_staff_portal/widgets/app_drawer.dart';
import 'package:universal_html/html.dart' as html;

class LightFixture {
  String name;
  int count = 1;
  int watt = 10;
  int volt = 12;
  bool isCustomVolt = false;
  String dimmingType = 'WRGB';
  bool needsRelay = false;
  String relayType = '大功率';

  LightFixture({
    required this.name,
    int? count,
    int? watt,
    int? volt,
    bool? isCustomVolt,
    String? dimmingType,
    bool? needsRelay,
    String? relayType,
  }) {
    this.count = count ?? this.count;
    this.watt = watt ?? this.watt;
    this.volt = volt ?? this.volt;
    this.isCustomVolt = isCustomVolt ?? this.isCustomVolt;
    this.dimmingType = dimmingType ?? this.dimmingType;
    this.needsRelay = needsRelay ?? this.needsRelay;
    this.relayType = relayType ?? this.relayType;
  }

  LightFixture copyWith({
    String? name,
    int? count,
    int? watt,
    int? volt,
    bool? isCustomVolt,
    String? dimmingType,
    bool? needsRelay,
    String? relayType,
  }) {
    return LightFixture(
      name: name ?? this.name,
      count: count ?? this.count,
      watt: watt ?? this.watt,
      volt: volt ?? this.volt,
      isCustomVolt: isCustomVolt ?? this.isCustomVolt,
      dimmingType: dimmingType ?? this.dimmingType,
      needsRelay: needsRelay ?? this.needsRelay,
      relayType: relayType ?? this.relayType,
    );
  }

  // 獲取燈具需要的總通道數 (數量 × 單個燈具需要的通道數)
  int get requiredChannels {
    int channelsPerFixture;
    switch (dimmingType) {
      case 'WRGB':
        channelsPerFixture = 4;
        break;
      case 'RGB':
        channelsPerFixture = 3;
        break;
      case '雙色溫':
        channelsPerFixture = 2;
        break;
      case '單色溫':
      case '繼電器':
        channelsPerFixture = 1;
        break;
      default:
        channelsPerFixture = 1;
    }
    return count * channelsPerFixture;
  }
}

class FixtureAllocation {
  LightFixture fixture;
  int allocatedCount;

  FixtureAllocation({required this.fixture, required this.allocatedCount});

  // 獲取本次分配需要的通道數
  int get requiredChannels {
    int channelsPerFixture;
    switch (fixture.dimmingType) {
      case 'WRGB':
        channelsPerFixture = 4;
        break;
      case 'RGB':
        channelsPerFixture = 3;
        break;
      case '雙色溫':
        channelsPerFixture = 2;
        break;
      case '單色溫':
      case '繼電器':
        channelsPerFixture = 1;
        break;
      default:
        channelsPerFixture = 1;
    }
    return allocatedCount * channelsPerFixture;
  }

  FixtureAllocation copyWith({LightFixture? fixture, int? allocatedCount}) {
    return FixtureAllocation(
      fixture: fixture ?? this.fixture,
      allocatedCount: allocatedCount ?? this.allocatedCount,
    );
  }
}

class LoopAllocation {
  Loop loop;
  int allocatedCount; // 分配的迴路數量（通常為1，因為一個迴路對應一個模組通道組）

  LoopAllocation({required this.loop, this.allocatedCount = 1});

  // 獲取本次分配需要的通道數（基於迴路的調光類型）
  int get requiredChannels {
    int channelsPerLoop;
    switch (loop.dimmingType) {
      case 'WRGB':
        channelsPerLoop = 4;
        break;
      case 'RGB':
        channelsPerLoop = 3;
        break;
      case '雙色溫':
        channelsPerLoop = 2;
        break;
      case '單色溫':
      case '繼電器':
        channelsPerLoop = 1;
        break;
      default:
        channelsPerLoop = 1;
    }
    return allocatedCount * channelsPerLoop;
  }

  LoopAllocation copyWith({Loop? loop, int? allocatedCount}) {
    return LoopAllocation(
      loop: loop ?? this.loop,
      allocatedCount: allocatedCount ?? this.allocatedCount,
    );
  }
}

class ModuleOption {
  final String model;
  final int channelCount;
  final bool isDimmable;

  const ModuleOption({
    required this.model,
    required this.channelCount,
    required this.isDimmable,
  });
}

class Module {
  String model;
  int channelCount;
  bool isDimmable;
  List<FixtureAllocation> allocations;
  List<LoopAllocation> loopAllocations;

  Module({
    required this.model,
    required this.channelCount,
    required this.isDimmable,
    this.allocations = const [],
    this.loopAllocations = const [],
  });

  Module copyWith({
    String? model,
    int? channelCount,
    bool? isDimmable,
    List<FixtureAllocation>? allocations,
    List<LoopAllocation>? loopAllocations,
  }) {
    return Module(
      model: model ?? this.model,
      channelCount: channelCount ?? this.channelCount,
      isDimmable: isDimmable ?? this.isDimmable,
      allocations: allocations ?? this.allocations,
      loopAllocations: loopAllocations ?? this.loopAllocations,
    );
  }

  // 獲取已使用的通道數
  int get usedChannels =>
      allocations.fold(
        0,
        (sum, allocation) => sum + allocation.requiredChannels,
      ) +
      loopAllocations.fold(
        0,
        (sum, allocation) => sum + allocation.requiredChannels,
      );

  // 獲取可用通道數
  int get availableChannels => channelCount - usedChannels;

  // 檢查是否可以分配指定數量的燈具
  bool canAssignFixture(LightFixture fixture, int count) {
    int requiredChannels = count * fixture.requiredChannels ~/ fixture.count;
    return availableChannels >= requiredChannels;
  }

  // 檢查是否可以分配迴路
  bool canAssignLoop(Loop loop, int count) {
    int requiredChannels = count * _getChannelsPerLoop(loop.dimmingType);
    return availableChannels >= requiredChannels;
  }

  // 獲取迴路需要的通道數
  int _getChannelsPerLoop(String dimmingType) {
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
}

// 預定義模組選項
const List<ModuleOption> moduleOptions = [
  ModuleOption(model: 'P210', channelCount: 2, isDimmable: true),
  ModuleOption(model: 'P404', channelCount: 4, isDimmable: true),
  ModuleOption(model: 'R410', channelCount: 4, isDimmable: false),
  ModuleOption(model: 'P805', channelCount: 8, isDimmable: true),
  ModuleOption(model: 'P305', channelCount: 3, isDimmable: true),
];

// 燈具類型選項
const List<String> fixtureTypes = [
  '軌道燈',
  '燈帶',
  '崁燈',
  '射燈',
  '吊燈',
];

class FixtureTypeData {
  final String type;
  final String quantityLabel;
  final String unitLabel;
  final bool isMeterBased;

  const FixtureTypeData({
    required this.type,
    required this.quantityLabel,
    required this.unitLabel,
    this.isMeterBased = false,
  });
}

const Map<String, FixtureTypeData> fixtureTypeData = {
  '軌道燈': FixtureTypeData(
    type: '軌道燈',
    quantityLabel: '燈具數量',
    unitLabel: '每顆瓦數 (W)',
  ),
  '燈帶': FixtureTypeData(
    type: '燈帶',
    quantityLabel: '米數',
    unitLabel: '每米瓦數 (W/m)',
    isMeterBased: true,
  ),
  '崁燈': FixtureTypeData(
    type: '崁燈',
    quantityLabel: '燈具數量',
    unitLabel: '每顆瓦數 (W)',
  ),
  '射燈': FixtureTypeData(
    type: '射燈',
    quantityLabel: '燈具數量',
    unitLabel: '每顆瓦數 (W)',
  ),
  '吊燈': FixtureTypeData(
    type: '吊燈',
    quantityLabel: '燈具數量',
    unitLabel: '每顆瓦數 (W)',
  ),
};

class LoopFixture {
  String name;
  int totalWatt;

  LoopFixture({
    required this.name,
    required this.totalWatt});

  LoopFixture copyWith({
    String? name,
    int? totalWatt,
  }) {
    return LoopFixture(
      name: name ?? this.name,
      totalWatt: totalWatt ?? this.totalWatt,
    );
  }
}

class Loop {
  String name;
  int voltage;
  String dimmingType;
  List<LoopFixture> fixtures;

  Loop({
    required this.name,
    this.voltage = 12,
    this.dimmingType = 'WRGB',
    this.fixtures = const [],
  });

  Loop copyWith({
    String? name,
    int? voltage,
    String? dimmingType,
    List<LoopFixture>? fixtures,
  }) {
    return Loop(
      name: name ?? this.name,
      voltage: voltage ?? this.voltage,
      dimmingType: dimmingType ?? this.dimmingType,
      fixtures: fixtures ?? this.fixtures,
    );
  }

  // 獲取總瓦數
  int get totalWatt =>
      fixtures.fold(0, (sum, fixture) => sum + fixture.totalWatt);
}

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

  @override
  void initState() {
    super.initState();
    html.document.title = '光悅顧客系統';
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
                value: selectedOption,
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
                    value: loop.voltage,
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
                    value: loop.dimmingType,
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
                value: selectedType,
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
}