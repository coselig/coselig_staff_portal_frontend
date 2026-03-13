import 'package:coselig_staff_portal/services/ui_settings_provider.dart';
import 'package:coselig_staff_portal/widgets/theme_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileUiSettingsSection extends StatelessWidget {
  final TextStyle? titleStyle;

  const ProfileUiSettingsSection({super.key, this.titleStyle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '顯示與外觀設定',
          style: titleStyle ?? const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Consumer<UiSettingsProvider>(
          builder: (context, uiSettings, child) {
            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.work),
              title: const Text('顯示目前工作的員工'),
              value: uiSettings.showWorkingStaffCard,
              onChanged: uiSettings.setShowWorkingStaffCard,
            );
          },
        ),
        const SizedBox(height: 8),
        Consumer<UiSettingsProvider>(
          builder: (context, uiSettings, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('字體大小：${(uiSettings.fontSizeScale * 100).round()}%'),
                Slider(
                  value: uiSettings.fontSizeScale,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: '${(uiSettings.fontSizeScale * 100).round()}%',
                  onChanged: uiSettings.setFontSizeScale,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.brightness_6),
            SizedBox(width: 12),
            Expanded(child: ThemeToggleSwitch()),
          ],
        ),
      ],
    );
  }
}
