import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/theme_provider.dart';

class ThemeToggleSwitch extends StatelessWidget {
  const ThemeToggleSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentMode = themeProvider.themeMode;

    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment<ThemeMode>(
          value: ThemeMode.light,
          icon: Icon(Icons.light_mode),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.dark,
          icon: Icon(Icons.dark_mode),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.system,
          icon: Icon(Icons.settings),
        ),
      ],
      selected: {currentMode},
      onSelectionChanged: (Set<ThemeMode> selected) {
        themeProvider.setThemeMode(selected.first);
      },
    );
  }
}
