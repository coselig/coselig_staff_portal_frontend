import 'package:package_info_plus/package_info_plus.dart';

class AppConstants {
  static PackageInfo? _packageInfo;

  // 初始化 PackageInfo（在 app 啟動時調用）
  static Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  // 動態從 pubspec.yaml 讀取版本號
  static String get appVersion => _packageInfo?.version ?? '0.0.0';
  static String get buildNumber => _packageInfo?.buildNumber ?? '0';
  
  static String get fullVersion => 'v$appVersion (Build #$buildNumber)';
}