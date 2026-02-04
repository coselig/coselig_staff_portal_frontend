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

class Module {
  String model;
  int channelCount;
  int maxCurrentPerChannel;
  bool isDimmable;
  List<FixtureAllocation> allocations;

  Module({
    required this.model,
    required this.channelCount,
    required this.maxCurrentPerChannel,
    required this.isDimmable,
    this.allocations = const [],
  });

  Module copyWith({
    String? model,
    int? channelCount,
    int? maxCurrentPerChannel,
    bool? isDimmable,
    List<FixtureAllocation>? allocations,
  }) {
    return Module(
      model: model ?? this.model,
      channelCount: channelCount ?? this.channelCount,
      maxCurrentPerChannel: maxCurrentPerChannel ?? this.maxCurrentPerChannel,
      isDimmable: isDimmable ?? this.isDimmable,
      allocations: allocations ?? this.allocations,
    );
  }

  // 獲取可用通道數
  int get availableChannels => channelCount - usedChannels;

  // 獲取已使用的通道數
  int get usedChannels {
    return allocations.fold(
      0,
      (sum, allocation) => sum + allocation.requiredChannels,
    );
  }

  // 檢查是否可以分配給指定的燈具和數量
  bool canAssignFixture(LightFixture fixture, int count) {
    if (count <= 0) return false;
    final allocation = FixtureAllocation(
      fixture: fixture,
      allocatedCount: count,
    );
    if (usedChannels + allocation.requiredChannels > channelCount) return false;
    if (!isDimmable && fixture.dimmingType != '繼電器') return false;
    if (isDimmable && fixture.dimmingType == '繼電器') return false;

    // 檢查電流是否符合
    final current = fixture.watt / fixture.volt;
    return current <= maxCurrentPerChannel;
  }

  // 獲取已分配的燈具列表（用於顯示）
  List<LightFixture> get assignedFixtures {
    return allocations.map((allocation) => allocation.fixture).toList();
  }
}

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _currentStep = 0;

  // 第一步：設備配置 - 動態燈具列表
  final List<LightFixture> _lightFixtures = [];
  final TextEditingController _switchCountController = TextEditingController();
  final TextEditingController _otherDevicesController = TextEditingController();

  // 第二步：模組配置 - 動態模組列表
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

  void _addLightFixture() {
    setState(() {
      _lightFixtures.add(LightFixture(name: '燈具 ${_lightFixtures.length + 1}'));
    });
  }

  void _removeLightFixture(int index) {
    setState(() {
      _lightFixtures.removeAt(index);
    });
  }

  void _updateLightFixture(int index, LightFixture updatedFixture) {
    setState(() {
      _lightFixtures[index] = updatedFixture;
    });
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
            title: const Text('第一步：設備配置'),
            content: _buildStep1(),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('第二步：模組選擇'),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '燈具配置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _addLightFixture,
              icon: const Icon(Icons.add),
              label: const Text('添加燈具'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_lightFixtures.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                '尚未添加任何燈具\n點擊上方按鈕添加第一個燈具',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ..._lightFixtures.asMap().entries.map((entry) {
            final index = entry.key;
            final fixture = entry.value;
            return _buildLightFixtureCard(index, fixture);
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

  Widget _buildLightFixtureCard(int index, LightFixture fixture) {
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
                  fixture.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _removeLightFixture(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: '刪除此燈具',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: fixture.name,
                    decoration: const InputDecoration(
                      labelText: '燈具名稱',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updateLightFixture(index, fixture.copyWith(name: value));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: fixture.count.toString(),
                    decoration: const InputDecoration(
                      labelText: '數量',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final count = int.tryParse(value) ?? 1;
                      _updateLightFixture(
                        index,
                        fixture.copyWith(count: count),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: fixture.watt.toString(),
                    decoration: const InputDecoration(
                      labelText: '瓦數 (W)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final watt = int.tryParse(value) ?? 10;
                      _updateLightFixture(index, fixture.copyWith(watt: watt));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: fixture.isCustomVolt
                            ? '其他'
                            : fixture.volt.toString(),
                        decoration: const InputDecoration(
                          labelText: '電壓 (V)',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: '220', child: Text('220V')),
                          DropdownMenuItem(value: '110', child: Text('110V')),
                          DropdownMenuItem(value: '36', child: Text('36V')),
                          DropdownMenuItem(value: '24', child: Text('24V')),
                          DropdownMenuItem(value: '12', child: Text('12V')),
                          DropdownMenuItem(value: '其他', child: Text('其他')),
                        ],
                        onChanged: (value) {
                          if (value == '其他') {
                            _updateLightFixture(
                              index,
                              fixture.copyWith(isCustomVolt: true),
                            );
                          } else {
                            final volt = int.tryParse(value!) ?? 12;
                            _updateLightFixture(
                              index,
                              fixture.copyWith(volt: volt, isCustomVolt: false),
                            );
                          }
                        },
                      ),
                      if (fixture.isCustomVolt) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: fixture.volt.toString(),
                          decoration: const InputDecoration(
                            labelText: '自定義電壓 (V)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            final volt = int.tryParse(value) ?? 12;
                            _updateLightFixture(
                              index,
                              fixture.copyWith(volt: volt),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: fixture.dimmingType,
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
                _updateLightFixture(
                  index,
                  fixture.copyWith(
                    dimmingType: value!,
                    needsRelay: value == '繼電器',
                  ),
                );
              },
            ),
            if (fixture.needsRelay) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('繼電器類型：'),
                  const SizedBox(width: 16),
                  Radio<String>(
                    value: '大功率',
                    groupValue: fixture.relayType,
                    onChanged: (value) {
                      _updateLightFixture(
                        index,
                        fixture.copyWith(relayType: value!),
                      );
                    },
                  ),
                  const Text('大功率'),
                  const SizedBox(width: 16),
                  Radio<String>(
                    value: '小功率',
                    groupValue: fixture.relayType,
                    onChanged: (value) {
                      _updateLightFixture(
                        index,
                        fixture.copyWith(relayType: value!),
                      );
                    },
                  ),
                  const Text('小功率'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    // 獲取未分配的燈具
    final unassignedFixtures = _getUnassignedFixtures();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '模組配置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 未分配燈具總覽
        if (unassignedFixtures.isNotEmpty) ...[
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '待分配燈具：',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...unassignedFixtures.map(
                    (item) {
                    final fixture = item['fixture'] as LightFixture;
                    final remaining = item['remaining'] as int;
                    return Text(
                      '• ${fixture.name} (剩餘${remaining}個${fixture.dimmingType})',
                      style: const TextStyle(color: Colors.orange),
                    );
                  },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 添加模組按鈕
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

        // 模組列表
        if (_modules.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                '尚未添加任何模組\n點擊上方按鈕添加第一個模組',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ..._modules.asMap().entries.map((entry) {
            final index = entry.key;
            final module = entry.value;
            return _buildModuleCard(index, module);
          }),

        const SizedBox(height: 24),
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
              const SizedBox(height: 8),
              Text(
                '開關：${_switchCountController.text.isNotEmpty ? '${_switchCountController.text}個' : '未配置'}',
              ),
              if (_otherDevicesController.text.isNotEmpty)
                Text('其他設備：${_otherDevicesController.text}'),
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
                  (module) => Text(
                    '• ${module.model} (${module.usedChannels}/${module.channelCount}通道): ${module.allocations.map((a) => '${a.fixture.name}(${a.allocatedCount}個)').join(', ')}',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                '材料配置：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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

  // 獲取未完全分配的燈具及其剩餘數量
  List<Map<String, dynamic>> _getUnassignedFixtures() {
    final allocatedCounts = <String, int>{};

    // 統計每個燈具已經分配的數量
    for (final module in _modules) {
      for (final allocation in module.allocations) {
        final key = '${allocation.fixture.name}_${allocation.fixture.hashCode}';
        allocatedCounts[key] =
            (allocatedCounts[key] ?? 0) + allocation.allocatedCount;
      }
    }

    // 返回還有剩餘數量的燈具
    return _lightFixtures
        .map((fixture) {
          final key = '${fixture.name}_${fixture.hashCode}';
          final allocated = allocatedCounts[key] ?? 0;
          final remaining = fixture.count - allocated;

          return {'fixture': fixture, 'remaining': remaining};
        })
        .where((item) => (item['remaining'] as int) > 0)
        .toList();
  }

  // 添加模組
  void _addModule() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選擇模組類型'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('R410 - 繼電器模組 (4通道)'),
              subtitle: const Text('適用於繼電器控制，不可調光'),
              onTap: () {
                setState(() {
                  _modules.add(
                    Module(
                      model: 'R410',
                      channelCount: 4,
                      maxCurrentPerChannel: 10,
                      isDimmable: false,
                    ),
                  );
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('P404 - 可調光模組 (4通道)'),
              subtitle: const Text('每通道4安培，適用於多種燈具'),
              onTap: () {
                setState(() {
                  _modules.add(
                    Module(
                      model: 'P404',
                      channelCount: 4,
                      maxCurrentPerChannel: 4,
                      isDimmable: true,
                    ),
                  );
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('P210 - 可調光模組 (2通道)'),
              subtitle: const Text('每通道10安培，適用於大功率燈具'),
              onTap: () {
                setState(() {
                  _modules.add(
                    Module(
                      model: 'P210',
                      channelCount: 2,
                      maxCurrentPerChannel: 10,
                      isDimmable: true,
                    ),
                  );
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('P805 - 可調光模組 (8通道)'),
              subtitle: const Text('每通道5安培，適用於多燈具控制'),
              onTap: () {
                setState(() {
                  _modules.add(
                    Module(
                      model: 'P805',
                      channelCount: 8,
                      maxCurrentPerChannel: 5,
                      isDimmable: true,
                    ),
                  );
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('P305 - 可調光模組 (3通道)'),
              subtitle: const Text('總電流10安培，適用於混合燈具'),
              onTap: () {
                setState(() {
                  _modules.add(
                    Module(
                      model: 'P305',
                      channelCount: 3,
                      maxCurrentPerChannel: 5,
                      isDimmable: true,
                    ),
                  );
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  // 刪除模組
  void _removeModule(int index) {
    setState(() {
      _modules.removeAt(index);
    });
  }

  // 顯示模組卡片
  Widget _buildModuleCard(int index, Module module) {
    final unassignedFixtures = _getUnassignedFixtures();

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
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: '刪除此模組',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '通道: ${module.usedChannels}/${module.channelCount} (可用: ${module.availableChannels})',
              style: TextStyle(
                color: module.availableChannels > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              module.isDimmable ? '可調光' : '繼電器控制',
              style: TextStyle(
                color: module.isDimmable ? Colors.blue : Colors.orange,
              ),
            ),
            const SizedBox(height: 16),

            // 已分配的燈具
            if (module.allocations.isNotEmpty) ...[
              const Text(
                '已分配燈具:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...module.allocations.asMap().entries.map((entry) {
                final allocationIndex = entry.key;
                final allocation = entry.value;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '• ${allocation.fixture.name} (${allocation.allocatedCount}個, ${allocation.fixture.dimmingType})',
                    ),
                    IconButton(
                      onPressed: () =>
                          _removeAllocationFromModule(index, allocationIndex),
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      iconSize: 20,
                      tooltip: '移除此分配',
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
            ],

            // 添加燈具按鈕
            if (module.availableChannels > 0 &&
                unassignedFixtures.isNotEmpty) ...[
              const Text(
                '添加燈具:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: unassignedFixtures
                    .where((item) {
                      final fixture = item['fixture'] as LightFixture;
                      return module.canAssignFixture(
                        fixture,
                        1,
                      ); // 檢查是否可以分配至少1個
                    })
                    .map(
                      (item) {
                      final fixture = item['fixture'] as LightFixture;
                      final remaining = item['remaining'] as int;
                      return ElevatedButton(
                        onPressed: () =>
                            _showAllocationDialog(index, fixture, remaining),
                        child: Text('${fixture.name} (${remaining}個剩餘)'),
                      );
                    },
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 顯示分配數量選擇對話框
  void _showAllocationDialog(
    int moduleIndex,
    LightFixture fixture,
    int maxCount,
  ) {
    int selectedCount = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('分配 ${fixture.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('剩餘數量: $maxCount 個'),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('分配數量: '),
                  Expanded(
                    child: Slider(
                      value: selectedCount.toDouble(),
                      min: 1,
                      max: maxCount.toDouble(),
                      divisions: maxCount - 1,
                      label: selectedCount.toString(),
                      onChanged: (value) {
                        setState(() {
                          selectedCount = value.toInt();
                        });
                      },
                    ),
                  ),
                  Text('$selectedCount 個'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '需要通道: ${selectedCount * _getChannelsPerFixture(fixture.dimmingType)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
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
                _assignFixtureToModule(moduleIndex, fixture, selectedCount);
                Navigator.of(context).pop();
              },
              child: const Text('分配'),
            ),
          ],
        ),
      ),
    );
  }

  // 獲取每個燈具類型需要的通道數
  int _getChannelsPerFixture(String dimmingType) {
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

  // 分配燈具到模組（指定數量）
  void _assignFixtureToModule(
    int moduleIndex,
    LightFixture fixture,
    int count,
  ) {
    setState(() {
      final module = _modules[moduleIndex];
      if (module.canAssignFixture(fixture, count)) {
        final allocation = FixtureAllocation(
          fixture: fixture,
          allocatedCount: count,
        );
        final updatedAllocations = List<FixtureAllocation>.from(
          module.allocations,
        )..add(allocation);
        _modules[moduleIndex] = module.copyWith(
          allocations: updatedAllocations,
        );
      }
    });
  }

  // 從模組移除分配記錄
  void _removeAllocationFromModule(int moduleIndex, int allocationIndex) {
    setState(() {
      final module = _modules[moduleIndex];
      final updatedAllocations = List<FixtureAllocation>.from(
        module.allocations,
      )..removeAt(allocationIndex);
      _modules[moduleIndex] = module.copyWith(allocations: updatedAllocations);
    });
  }
}