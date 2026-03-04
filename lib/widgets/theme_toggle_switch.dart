import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/theme_provider.dart';
import 'package:coselig_staff_portal/utils/icon_utils.dart';

class ThemeToggleSwitch extends StatelessWidget {
  const ThemeToggleSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentMode = themeProvider.themeMode;
    final iconSize = context.scaledIconSize(24);

    return SegmentedButton<ThemeMode>(
      segments: [
        ButtonSegment<ThemeMode>(
          value: ThemeMode.light,
          icon: Icon(Icons.light_mode, size: iconSize),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.dark,
          icon: Icon(Icons.dark_mode, size: iconSize),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.system,
          icon: Icon(Icons.settings, size: iconSize),
        ),
      ],
      selected: {currentMode},
      onSelectionChanged: (Set<ThemeMode> selected) {
        themeProvider.setThemeMode(selected.first);
      },
    );
  }
}
