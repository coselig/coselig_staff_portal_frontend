import 'dart:convert';

import 'package:coselig_staff_portal/services/smart_home_assessment_service.dart';
import 'package:coselig_staff_portal/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

class _OptionConfig {
  final String key;
  final String label;

  const _OptionConfig(this.key, this.label);
}

const List<_OptionConfig> _threeGangOptions = [
  _OptionConfig('single', '單切'),
  _OptionConfig('double', '兩切'),
  _OptionConfig('triple', '三切'),
];

const List<_OptionConfig> _wallRemoteOptions = [
  _OptionConfig('oneGang', '一切'),
  _OptionConfig('twoGang', '兩切'),
  _OptionConfig('threeGang', '三切'),
];

const List<_OptionConfig> _buttonRemoteOptions = [
  _OptionConfig('knob', '旋鈕'),
  _OptionConfig('round', '圓形'),
  _OptionConfig('emergency', '緊急按鈕'),
  _OptionConfig('oval', '蛋形'),
  _OptionConfig('long', '長形'),
];

class SmartHomeAssessmentPage extends StatefulWidget {
  const SmartHomeAssessmentPage({super.key});

  @override
  State<SmartHomeAssessmentPage> createState() =>
      _SmartHomeAssessmentPageState();
}

class _SmartHomeAssessmentPageState extends State<SmartHomeAssessmentPage> {
  final SmartHomeAssessmentService _service = SmartHomeAssessmentService();

  List<SmartHomeAssessmentFormSummary> _forms = [];
  SmartHomeAssessmentFormSummary? _selectedFormSummary;
  SmartHomeAssessmentFormDetail? _loadedForm;
  Map<String, dynamic> _formData = _createDefaultFormData();
  String _formName = '';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String? _error;
  int _editorVersion = 0;

  @override
  void initState() {
    super.initState();
    html.document.title = '智慧型住宅確認表';
    _refreshForms(autoSelectFirst: true);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  static Map<String, dynamic> _createDefaultFormData() {
    return {
      'template': 'smart_home_assessment',
      'version': 1,
      'responses': {
        'entryLightingRelay': _entryChecklistDefaults(6),
        'entrySwitchOriginalController': _optionChecklistDefaults(
          _threeGangOptions,
        ),
        'entrySwitchOriginalSignalDirect': _optionChecklistDefaults(
          _threeGangOptions,
        ),
        'entrySwitchEnergyHarvesting': _optionChecklistDefaults(
          _threeGangOptions,
        ),
        'entrySwitchSceneRemoteWall': _optionChecklistDefaults(
          _wallRemoteOptions,
        ),
        'entrySwitchSceneRemoteButton': _optionChecklistDefaults(
          _buttonRemoteOptions,
        ),
        'entryHost': _hostChecklistDefaults(),
        'upgradeLightingDimmer': _entryChecklistDefaults(6),
        'upgradeLightingDimmerCt': _entryChecklistDefaults(6),
        'upgradeLightingNonZ2m': _entryChecklistDefaults(3),
        'upgradeSwitchOriginalController': _optionChecklistDefaults(
          _threeGangOptions,
        ),
        'upgradeSwitchOriginalSignalDirect': _optionChecklistDefaults(
          _threeGangOptions,
        ),
        'upgradeSwitchSceneRemoteWall': _optionChecklistDefaults(
          _wallRemoteOptions,
        ),
        'upgradeSwitchSceneRemoteButton': _optionChecklistDefaults(
          _buttonRemoteOptions,
        ),
        'upgradeSwitchNonZ2m': _entryChecklistDefaults(3),
        'auxPresenceSensor': _singleQuantityChecklistDefaults(),
        'auxDoorSensor': _singleQuantityChecklistDefaults(),
        'auxInfraredRemote': _singleQuantityChecklistDefaults(),
        'auxSmartLock': _singleQuantityChecklistDefaults(),
        'auxOther': _customQuantityChecklistDefaults(),
        'evaluationWirelessDimmer': _singleQuantityChecklistDefaults(),
        'evaluationCurtain': _curtainChecklistDefaults(),
        'evaluationAirConditioner': _entryChecklistDefaults(5),
        'evaluationMonitor': _entryChecklistDefaults(4),
        'evaluationApiAppliance': _entryChecklistDefaults(5),
        'evaluationHost': _hostChecklistDefaults(),
      },
    };
  }

  static Map<String, dynamic> _entryChecklistDefaults(int defaultRows) {
    return {
      'checked': false,
      'entries': List.generate(
        defaultRows,
        (_) => {'label': '', 'quantity': ''},
      ),
    };
  }

  static Map<String, dynamic> _optionChecklistDefaults(
    List<_OptionConfig> options,
  ) {
    return {
      'checked': false,
      'options': {for (final option in options) option.key: ''},
    };
  }

  static Map<String, dynamic> _singleQuantityChecklistDefaults() {
    return {'checked': false, 'quantity': ''};
  }

  static Map<String, dynamic> _customQuantityChecklistDefaults() {
    return {'checked': false, 'label': '', 'quantity': ''};
  }

  static Map<String, dynamic> _curtainChecklistDefaults() {
    return {
      'checked': false,
      'options': {'pleatedSnake': '', 'roller': ''},
      'other': {'label': '', 'quantity': ''},
    };
  }

  static Map<String, dynamic> _hostChecklistDefaults() {
    return {
      'arm': {'checked': false, 'ethernet': false, 'wifi': false},
      'x86': {'checked': false, 'ethernet': false, 'wifi': false},
    };
  }

  dynamic _deepCopy(dynamic value) {
    return jsonDecode(jsonEncode(value));
  }

  dynamic _deepMerge(dynamic defaults, dynamic incoming) {
    if (defaults is Map && incoming is Map) {
      final result = <String, dynamic>{};
      final defaultMap = Map<String, dynamic>.from(defaults);
      final incomingMap = Map<String, dynamic>.from(incoming);
      final keys = <String>{...defaultMap.keys, ...incomingMap.keys};

      for (final key in keys) {
        if (!incomingMap.containsKey(key)) {
          result[key] = _deepCopy(defaultMap[key]);
        } else if (!defaultMap.containsKey(key)) {
          result[key] = _deepCopy(incomingMap[key]);
        } else {
          result[key] = _deepMerge(defaultMap[key], incomingMap[key]);
        }
      }

      return result;
    }

    if (incoming == null) {
      return _deepCopy(defaults);
    }

    return _deepCopy(incoming);
  }

  Map<String, dynamic> _normalizeFormData(Map<String, dynamic>? raw) {
    final defaults = _createDefaultFormData();
    if (raw == null || raw.isEmpty) {
      return defaults;
    }

    return Map<String, dynamic>.from(_deepMerge(defaults, raw));
  }

  Map<String, dynamic> get _responses =>
      (_formData['responses'] as Map).cast<String, dynamic>();

  Map<String, dynamic> _response(String key) {
    final value = _responses[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      final converted = Map<String, dynamic>.from(value);
      _responses[key] = converted;
      return converted;
    }
    throw StateError('Missing response for $key');
  }

  Map<String, dynamic> _options(Map<String, dynamic> response) {
    final value = response['options'];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      final converted = Map<String, dynamic>.from(value);
      response['options'] = converted;
      return converted;
    }
    final converted = <String, dynamic>{};
    response['options'] = converted;
    return converted;
  }

  List<Map<String, dynamic>> _entries(
    Map<String, dynamic> response, {
    int minimumRows = 0,
  }) {
    final value = response['entries'];
    final converted = value is List
        ? value.map((item) {
            if (item is Map<String, dynamic>) {
              return item;
            }
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{'label': '', 'quantity': ''};
          }).toList()
        : <Map<String, dynamic>>[];

    while (converted.length < minimumRows) {
      converted.add({'label': '', 'quantity': ''});
    }

    response['entries'] = converted;
    return converted;
  }

  void _markDirty() {
    if (_hasUnsavedChanges) {
      return;
    }
    setState(() => _hasUnsavedChanges = true);
  }

  String _displayTimestamp(String value) {
    if (value.trim().isEmpty) {
      return '未記錄';
    }
    return value.replaceFirst('T', ' ');
  }

  Future<void> _refreshForms({
    String? preferredName,
    bool autoSelectFirst = false,
  }) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final forms = await _service.fetchForms();
      if (!mounted) return;

      setState(() {
        _forms = forms;
      });

      String? nextName = preferredName;
      if (nextName == null && _selectedFormSummary != null) {
        final currentName = _selectedFormSummary!.name;
        if (forms.any((form) => form.name == currentName)) {
          nextName = currentName;
        }
      }
      if (nextName == null && autoSelectFirst && forms.isNotEmpty) {
        nextName = forms.first.name;
      }

      if (nextName != null) {
        await _loadForm(nextName, setLoading: false);
        return;
      }

      setState(() {
        _selectedFormSummary = null;
        _loadedForm = null;
        _formData = _createDefaultFormData();
        _formName = '';
        _hasUnsavedChanges = false;
        _isLoading = false;
        _editorVersion += 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '載入表單列表失敗：$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadForm(String name, {bool setLoading = true}) async {
    if (setLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final detail = await _service.loadForm(name);
      if (!mounted) return;

      SmartHomeAssessmentFormSummary? summary;
      for (final form in _forms) {
        if (form.name == name) {
          summary = form;
          break;
        }
      }

      setState(() {
        _loadedForm = detail;
        _selectedFormSummary = summary;
        _formName = detail.name;
        _formData = _normalizeFormData(detail.formData);
        _hasUnsavedChanges = false;
        _isLoading = false;
        _error = null;
        _editorVersion += 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '載入表單失敗：$e';
        _isLoading = false;
      });
    }
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('尚未儲存變更'),
        content: const Text('目前表單有未儲存內容，切換後會遺失，確定要繼續嗎？'),
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

    return confirmed ?? false;
  }

  Future<void> _createNewForm() async {
    if (!await _confirmDiscardChanges()) {
      return;
    }

    final controller = TextEditingController();
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增表單'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '表單名稱',
            hintText: '例如：王先生 4/1 現勘',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('建立'),
          ),
        ],
      ),
    );

    if (!mounted || newName == null || newName.trim().isEmpty) {
      return;
    }

    if (_forms.any((form) => form.name == newName.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已有同名表單，請換一個名稱')),
      );
      return;
    }

    setState(() {
      _selectedFormSummary = null;
      _loadedForm = null;
      _formData = _createDefaultFormData();
      _formName = newName.trim();
      _hasUnsavedChanges = false;
      _error = null;
      _editorVersion += 1;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已建立新表單，記得按下儲存')));
  }

  Future<void> _selectForm(SmartHomeAssessmentFormSummary form) async {
    if (_selectedFormSummary?.name == form.name && !_hasUnsavedChanges) {
      return;
    }

    if (!await _confirmDiscardChanges()) {
      return;
    }

    await _loadForm(form.name);
  }

  Future<void> _saveForm() async {
    final trimmedName = _formName.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請先輸入表單名稱')));
      return;
    }

    final willOverwrite = _forms.any(
      (form) =>
          form.name == trimmedName && form.name != _selectedFormSummary?.name,
    );

    if (willOverwrite) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('覆蓋同名表單'),
          content: Text('已存在「$trimmedName」，儲存後會覆蓋原本內容，確定要繼續嗎？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('覆蓋'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) {
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      await _service.saveForm(trimmedName, _formData);
      if (!mounted) return;

      await _refreshForms(preferredName: trimmedName);
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('表單「$trimmedName」已儲存')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('儲存失敗：$e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteForm(SmartHomeAssessmentFormSummary form) async {
    final isCurrent = _selectedFormSummary?.name == form.name;
    if (isCurrent && _hasUnsavedChanges) {
      final canContinue = await _confirmDiscardChanges();
      if (!canContinue || !mounted) {
        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除表單'),
        content: Text('確定要刪除「${form.name}」嗎？此動作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _service.deleteForm(form.name);
      if (!mounted) return;

      final preferredName = _selectedFormSummary?.name == form.name
          ? null
          : _selectedFormSummary?.name;
      await _refreshForms(
        preferredName: preferredName,
        autoSelectFirst: preferredName == null,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已刪除「${form.name}」')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('刪除失敗：$e')));
    }
  }

  Widget _buildManagementCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.fact_check_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '智慧型住宅確認表',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '依據你提供的 markdown 整理成可編輯的員工確認表單。表單名稱存於資料庫欄位 `name`，表單內容則以 JSON 儲存。',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _createNewForm,
                  icon: const Icon(Icons.add),
                  label: const Text('新增表單'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _refreshForms(autoSelectFirst: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新整理'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '已儲存表單',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (_forms.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '目前還沒有儲存的表單，按「新增表單」就能開始建立。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _forms.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final form = _forms[index];
                  final isSelected = _selectedFormSummary?.name == form.name;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer.withValues(alpha: 0.7)
                          : colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => _selectForm(form),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      title: Text(
                        form.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '建立者：${form.creatorName}\n更新時間：${_displayTimestamp(form.updatedAt)}',
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () => _deleteForm(form),
                        tooltip: '刪除表單',
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red.shade400,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedSummary = _selectedFormSummary;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '表單編輯',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '可直接修改欄位內容後儲存。若把名稱改成新的值，系統會視為另一份表單。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: ValueKey('$_editorVersion-form-name'),
              initialValue: _formName,
              onChanged: (value) {
                _formName = value;
                _markDirty();
              },
              decoration: const InputDecoration(
                labelText: '表單名稱',
                hintText: '請輸入表單名稱',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Chip(
                  avatar: const Icon(Icons.person_outline, size: 18),
                  label: Text(
                    '建立者：${selectedSummary?.creatorName ?? '尚未儲存'}',
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.schedule, size: 18),
                  label: Text(
                    '更新時間：${_displayTimestamp(selectedSummary?.updatedAt ?? _loadedForm?.updatedAt ?? '')}',
                  ),
                ),
                if (_hasUnsavedChanges)
                  Chip(
                    backgroundColor: colorScheme.secondaryContainer,
                    avatar: Icon(
                      Icons.edit_note,
                      size: 18,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    label: Text(
                      '尚未儲存',
                      style: TextStyle(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveForm,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? '儲存中' : '儲存表單'),
                ),
                OutlinedButton.icon(
                  onPressed: selectedSummary == null
                      ? null
                      : () => _loadForm(selectedSummary.name),
                  icon: const Icon(Icons.history),
                  label: const Text('重新載入目前表單'),
                ),
                OutlinedButton.icon(
                  onPressed: selectedSummary == null
                      ? null
                      : () => _deleteForm(selectedSummary),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('刪除目前表單'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistContainer({
    required bool checked,
    required ValueChanged<bool> onChanged,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: checked,
            onChanged: (value) => onChanged(value ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: subtitle == null ? null : Text(subtitle),
          ),
          if (children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(children: children),
            ),
        ],
      ),
    );
  }

  Widget _buildEntryChecklist({
    required String responseKey,
    required String title,
    required String entryLabel,
    required int minimumRows,
    String itemHint = '請輸入項目',
  }) {
    final response = _response(responseKey);
    final checked = response['checked'] == true;
    final entries = _entries(response, minimumRows: minimumRows);

    return _buildChecklistContainer(
      checked: checked,
      onChanged: (value) {
        setState(() {
          response['checked'] = value;
          _hasUnsavedChanges = true;
        });
      },
      title: title,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            entryLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(entries.length, (index) {
          final entry = entries[index];
          final canRemove = entries.length > minimumRows;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 320,
                  child: TextFormField(
                    key: ValueKey('$_editorVersion-$responseKey-label-$index'),
                    initialValue: entry['label']?.toString() ?? '',
                    onChanged: (value) {
                      entry['label'] = value;
                      _markDirty();
                    },
                    enabled: checked,
                    decoration: InputDecoration(
                      labelText: entryLabel,
                      hintText: itemHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: TextFormField(
                    key: ValueKey(
                      '$_editorVersion-$responseKey-quantity-$index',
                    ),
                    initialValue: entry['quantity']?.toString() ?? '',
                    onChanged: (value) {
                      entry['quantity'] = value;
                      _markDirty();
                    },
                    enabled: checked,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '數量',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: checked && canRemove
                      ? () {
                          setState(() {
                            entries.removeAt(index);
                            _hasUnsavedChanges = true;
                          });
                        }
                      : null,
                  tooltip: '刪除這一列',
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: checked
                ? () {
                    setState(() {
                      entries.add({'label': '', 'quantity': ''});
                      _hasUnsavedChanges = true;
                    });
                  }
                : null,
            icon: const Icon(Icons.add),
            label: const Text('新增一列'),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionChecklist({
    required String responseKey,
    required String title,
    required List<_OptionConfig> options,
  }) {
    final response = _response(responseKey);
    final checked = response['checked'] == true;
    final values = _options(response);

    return _buildChecklistContainer(
      checked: checked,
      onChanged: (value) {
        setState(() {
          response['checked'] = value;
          _hasUnsavedChanges = true;
        });
      },
      title: title,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((option) {
            return SizedBox(
              width: 220,
              child: TextFormField(
                key: ValueKey('$_editorVersion-$responseKey-${option.key}'),
                initialValue: values[option.key]?.toString() ?? '',
                onChanged: (value) {
                  values[option.key] = value;
                  _markDirty();
                },
                enabled: checked,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '${option.label} 數量',
                  border: const OutlineInputBorder(),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSingleQuantityChecklist({
    required String responseKey,
    required String title,
  }) {
    final response = _response(responseKey);
    final checked = response['checked'] == true;

    return _buildChecklistContainer(
      checked: checked,
      onChanged: (value) {
        setState(() {
          response['checked'] = value;
          _hasUnsavedChanges = true;
        });
      },
      title: title,
      children: [
        SizedBox(
          width: 220,
          child: TextFormField(
            key: ValueKey('$_editorVersion-$responseKey-quantity'),
            initialValue: response['quantity']?.toString() ?? '',
            onChanged: (value) {
              response['quantity'] = value;
              _markDirty();
            },
            enabled: checked,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '數量',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomQuantityChecklist({
    required String responseKey,
    required String title,
  }) {
    final response = _response(responseKey);
    final checked = response['checked'] == true;

    return _buildChecklistContainer(
      checked: checked,
      onChanged: (value) {
        setState(() {
          response['checked'] = value;
          _hasUnsavedChanges = true;
        });
      },
      title: title,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 300,
              child: TextFormField(
                key: ValueKey('$_editorVersion-$responseKey-label'),
                initialValue: response['label']?.toString() ?? '',
                onChanged: (value) {
                  response['label'] = value;
                  _markDirty();
                },
                enabled: checked,
                decoration: const InputDecoration(
                  labelText: '其它項目名稱',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 160,
              child: TextFormField(
                key: ValueKey('$_editorVersion-$responseKey-quantity'),
                initialValue: response['quantity']?.toString() ?? '',
                onChanged: (value) {
                  response['quantity'] = value;
                  _markDirty();
                },
                enabled: checked,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '數量',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurtainChecklist(String responseKey) {
    final response = _response(responseKey);
    final checked = response['checked'] == true;
    final optionValues = _options(response);
    final other = (response['other'] as Map?)?.cast<String, dynamic>() ??
        {'label': '', 'quantity': ''};
    response['other'] = other;

    return _buildChecklistContainer(
      checked: checked,
      onChanged: (value) {
        setState(() {
          response['checked'] = value;
          _hasUnsavedChanges = true;
        });
      },
      title: '電動窗簾',
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 220,
              child: TextFormField(
                key: ValueKey('$_editorVersion-$responseKey-pleated'),
                initialValue: optionValues['pleatedSnake']?.toString() ?? '',
                onChanged: (value) {
                  optionValues['pleatedSnake'] = value;
                  _markDirty();
                },
                enabled: checked,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '褶簾/蛇形簾 數量',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 220,
              child: TextFormField(
                key: ValueKey('$_editorVersion-$responseKey-roller'),
                initialValue: optionValues['roller']?.toString() ?? '',
                onChanged: (value) {
                  optionValues['roller'] = value;
                  _markDirty();
                },
                enabled: checked,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '捲簾 數量',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 280,
              child: TextFormField(
                key: ValueKey('$_editorVersion-$responseKey-other-label'),
                initialValue: other['label']?.toString() ?? '',
                onChanged: (value) {
                  other['label'] = value;
                  _markDirty();
                },
                enabled: checked,
                decoration: const InputDecoration(
                  labelText: '其它類型',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 160,
              child: TextFormField(
                key: ValueKey('$_editorVersion-$responseKey-other-quantity'),
                initialValue: other['quantity']?.toString() ?? '',
                onChanged: (value) {
                  other['quantity'] = value;
                  _markDirty();
                },
                enabled: checked,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '數量',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHostChecklist(String responseKey) {
    final response = _response(responseKey);
    final arm = (response['arm'] as Map).cast<String, dynamic>();
    final x86 = (response['x86'] as Map).cast<String, dynamic>();

    Widget architectureCard(String title, Map<String, dynamic> item) {
      final checked = item['checked'] == true;
      return Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: checked,
              onChanged: (value) {
                setState(() {
                  item['checked'] = value ?? false;
                  if (value != true) {
                    item['ethernet'] = false;
                    item['wifi'] = false;
                  }
                  _hasUnsavedChanges = true;
                });
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            CheckboxListTile(
              value: item['ethernet'] == true,
              onChanged: checked
                  ? (value) {
                      setState(() {
                        item['ethernet'] = value ?? false;
                        _hasUnsavedChanges = true;
                      });
                    }
                  : null,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Ethernet'),
            ),
            CheckboxListTile(
              value: item['wifi'] == true,
              onChanged: checked
                  ? (value) {
                      setState(() {
                        item['wifi'] = value ?? false;
                        _hasUnsavedChanges = true;
                      });
                    }
                  : null,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('WiFi'),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '主機配置',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              architectureCard('Arm 架構', arm),
              architectureCard('X86 架構', x86),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildFormSections() {
    return Column(
      children: [
        _buildSectionCard(
          title: '1. 入門',
          subtitle: '燈具聯網',
          children: [
            Text(
              '1-a. 燈具',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _buildEntryChecklist(
              responseKey: 'entryLightingRelay',
              title: '燈具迴路加裝「無線訊號通斷器」',
              entryLabel: '燈具形態',
              minimumRows: 6,
            ),
            const SizedBox(height: 8),
            Text(
              '1-b. 開關',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _buildOptionChecklist(
              responseKey: 'entrySwitchOriginalController',
              title: '原開關(控制器 DI)',
              options: _threeGangOptions,
            ),
            _buildOptionChecklist(
              responseKey: 'entrySwitchOriginalSignalDirect',
              title: '原開關(訊號直連 DI)',
              options: _threeGangOptions,
            ),
            _buildOptionChecklist(
              responseKey: 'entrySwitchEnergyHarvesting',
              title: '自發電開關',
              options: _threeGangOptions,
            ),
            _buildOptionChecklist(
              responseKey: 'entrySwitchSceneRemoteWall',
              title: '場景遙控(電池) - 壁控',
              options: _wallRemoteOptions,
            ),
            _buildOptionChecklist(
              responseKey: 'entrySwitchSceneRemoteButton',
              title: '場景遙控(電池) - 按押',
              options: _buttonRemoteOptions,
            ),
            const SizedBox(height: 8),
            Text(
              '1-c. 主機',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _buildHostChecklist('entryHost'),
          ],
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          title: '2. 裝修/升級優化',
          subtitle: '建立光環境',
          children: [
            Text(
              '2-a. 燈具',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _buildEntryChecklist(
              responseKey: 'upgradeLightingDimmer',
              title: '燈具迴路改裝「無線訊號調光控制器」',
              entryLabel: '燈具形態',
              minimumRows: 6,
            ),
            _buildEntryChecklist(
              responseKey: 'upgradeLightingDimmerCt',
              title: '燈具迴路改裝「無線訊號調光/調色控制器」',
              entryLabel: '燈具形態',
              minimumRows: 6,
            ),
            _buildEntryChecklist(
              responseKey: 'upgradeLightingNonZ2m',
              title: '「非Z2M」燈具迴路',
              entryLabel: '燈具形態',
              minimumRows: 3,
            ),
            const SizedBox(height: 8),
            Text(
              '2-b. 開關',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _buildOptionChecklist(
              responseKey: 'upgradeSwitchOriginalController',
              title: '原開關(控制器 DI)',
              options: _threeGangOptions,
            ),
            _buildOptionChecklist(
              responseKey: 'upgradeSwitchOriginalSignalDirect',
              title: '原開關(訊號直連 DI)',
              options: _threeGangOptions,
            ),
            _buildOptionChecklist(
              responseKey: 'upgradeSwitchSceneRemoteWall',
              title: '場景遙控(電池) - 壁控',
              options: _wallRemoteOptions,
            ),
            _buildOptionChecklist(
              responseKey: 'upgradeSwitchSceneRemoteButton',
              title: '場景遙控(電池) - 按押',
              options: _buttonRemoteOptions,
            ),
            _buildEntryChecklist(
              responseKey: 'upgradeSwitchNonZ2m',
              title: '「非Z2M」',
              entryLabel: '形態',
              minimumRows: 3,
            ),
            const SizedBox(height: 8),
            Text(
              '2-c. 輔助裝置',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _buildSingleQuantityChecklist(
              responseKey: 'auxPresenceSensor',
              title: '人體存在感應器',
            ),
            _buildSingleQuantityChecklist(
              responseKey: 'auxDoorSensor',
              title: '門磁開關',
            ),
            _buildSingleQuantityChecklist(
              responseKey: 'auxInfraredRemote',
              title: '紅外線遙控器',
            ),
            _buildSingleQuantityChecklist(
              responseKey: 'auxSmartLock',
              title: '電子門鎖',
            ),
            _buildCustomQuantityChecklist(
              responseKey: 'auxOther',
              title: '其它輔助裝置',
            ),
            const SizedBox(height: 8),
            Text(
              '2-d. 評估項目',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _buildSingleQuantityChecklist(
              responseKey: 'evaluationWirelessDimmer',
              title: '「無線訊號調光器」',
            ),
            _buildCurtainChecklist('evaluationCurtain'),
            _buildEntryChecklist(
              responseKey: 'evaluationAirConditioner',
              title: '冷氣',
              entryLabel: '品牌/型號',
              minimumRows: 5,
              itemHint: '請輸入品牌/型號',
            ),
            _buildEntryChecklist(
              responseKey: 'evaluationMonitor',
              title: '監視器',
              entryLabel: '品牌/型號',
              minimumRows: 4,
              itemHint: '請輸入品牌/型號',
            ),
            _buildEntryChecklist(
              responseKey: 'evaluationApiAppliance',
              title: 'API家電',
              entryLabel: '品牌/型號',
              minimumRows: 5,
              itemHint: '請輸入品牌/型號',
            ),
            const SizedBox(height: 8),
            Text(
              '2-e. 主機',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _buildHostChecklist('evaluationHost'),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('智慧型住宅確認表')),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.primaryContainer.withValues(alpha: 0.25),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_error != null) ...[
                            Material(
                              color: Colors.transparent,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          _buildManagementCard(context),
                          const SizedBox(height: 20),
                          _buildEditorCard(context),
                          const SizedBox(height: 20),
                          _buildFormSections(),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
