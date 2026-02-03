import 'package:flutter/material.dart';

class UiSettingsProvider extends ChangeNotifier {
  bool _showWorkingStaffCard = true;
  double _fontSizeScale = 1.0;

  bool get showWorkingStaffCard => _showWorkingStaffCard;
  double get fontSizeScale => _fontSizeScale;

  void toggleWorkingStaffCard() {
    _showWorkingStaffCard = !_showWorkingStaffCard;
    notifyListeners();
  }

  void setShowWorkingStaffCard(bool show) {
    _showWorkingStaffCard = show;
    notifyListeners();
  }

  void setFontSizeScale(double scale) {
    _fontSizeScale = scale;
    notifyListeners();
  }
}