import 'package:flutter/material.dart';

/// 擴展 BuildContext，提供 Icon 大小縮放功能。
/// 根據全域 IconTheme（已在 main.dart 中設置為 24 * fontSizeScale）
/// 計算縮放後的 icon 大小。
extension IconScaling on BuildContext {
  /// 將基礎 icon 大小乘以全域縮放比例。
  /// 例如：context.scaledIconSize(18) 在 fontSizeScale=1.2 時回傳 21.6
  double scaledIconSize(double baseSize) {
    final themeSize = IconTheme.of(this).size ?? 24.0;
    return baseSize * themeSize / 24.0;
  }
}
