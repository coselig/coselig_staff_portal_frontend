import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/theme_provider.dart';

class ThemeToggleSwitch extends StatelessWidget {
  const ThemeToggleSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.light_mode),
        Switch(
          value: isDark,
          onChanged: (value) {
            themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
          },
        ),
        const Icon(Icons.dark_mode),
      ],
    );
  }
}
