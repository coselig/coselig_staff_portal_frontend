import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/models/quote_models.dart';
import 'package:coselig_staff_portal/services/quote_service.dart';

class AddModuleDialog extends StatefulWidget {
  final Function(Module) onAddModule;

  const AddModuleDialog({super.key, required this.onAddModule});

  @override
  State<AddModuleDialog> createState() => _AddModuleDialogState();
}

class _AddModuleDialogState extends State<AddModuleDialog> {
  ModuleOption? selectedOption;

  @override
  Widget build(BuildContext context) {
    final quoteService = Provider.of<QuoteService>(context);

    return StatefulBuilder(
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
              items: quoteService.moduleOptions.map((option) {
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
                    widget.onAddModule(
                      Module(
                        model: selectedOption!.model,
                        channelCount: selectedOption!.channelCount,
                        isDimmable: selectedOption!.isDimmable,
                        maxAmperePerChannel:
                            selectedOption!.maxAmperePerChannel,
                        maxAmpereTotal: selectedOption!.maxAmpereTotal,
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                : null,
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
}