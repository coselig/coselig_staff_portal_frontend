import 'package:flutter/material.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';

class ThemeProvider extends ChangeNotifier {
  final AuthService _authService;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider(this._authService) {
    _loadThemeFromUser();
    _authService.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    _loadThemeFromUser();
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  ThemeMode get themeMode => _themeMode;

  void _loadThemeFromUser() {
    if (_authService.themeMode != null) {
      switch (_authService.themeMode) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
        default:
          _themeMode = ThemeMode.system;
          break;
      }
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    // 轉換為字串並儲存到資料庫
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }

    await _authService.updateThemeMode(modeString);
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFfEBC82),
    brightness: Brightness.light,
  ),
  useMaterial3: true,
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFfEBC82),
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
);
