import 'package:flutter/material.dart';
import 'auth_service.dart';

class UiSettingsProvider extends ChangeNotifier {
  AuthService? _authService;
  bool _showWorkingStaffCard = true;
  double _fontSizeScale = 1.0;

  bool get showWorkingStaffCard => _showWorkingStaffCard;
  double get fontSizeScale => _fontSizeScale;

  /// 綁定 AuthService，並從中載入已儲存的偏好
  void bindAuthService(AuthService authService) {
    _authService = authService;
    loadFromAuth();
  }

  /// 從 AuthService 載入已儲存的設定
  void loadFromAuth() {
    if (_authService == null) return;
    bool changed = false;
    if (_authService!.fontSizeScale != null) {
      _fontSizeScale = _authService!.fontSizeScale!;
      changed = true;
    }
    if (_authService!.showWorkingStaffCard != null) {
      _showWorkingStaffCard = _authService!.showWorkingStaffCard!;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void toggleWorkingStaffCard() {
    _showWorkingStaffCard = !_showWorkingStaffCard;
    notifyListeners();
    _saveToBackend();
  }

  void setShowWorkingStaffCard(bool show) {
    _showWorkingStaffCard = show;
    notifyListeners();
    _saveToBackend(showWorkingStaffCardOnly: true);
  }

  void setFontSizeScale(double scale) {
    _fontSizeScale = scale;
    notifyListeners();
    _saveToBackend(fontSizeScaleOnly: true);
  }

  void _saveToBackend({
    bool fontSizeScaleOnly = false,
    bool showWorkingStaffCardOnly = false,
  }) {
    if (_authService == null || !_authService!.isLoggedIn) return;
    _authService!.updateUiPreferences(
      fontSizeScale: fontSizeScaleOnly
          ? _fontSizeScale
          : (showWorkingStaffCardOnly ? null : _fontSizeScale),
      showWorkingStaffCard: showWorkingStaffCardOnly
          ? _showWorkingStaffCard
          : (fontSizeScaleOnly ? null : _showWorkingStaffCard),
    );
  }
}