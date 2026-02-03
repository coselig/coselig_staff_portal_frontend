import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coselig_staff_portal/services/ui_settings_provider.dart';
import 'package:coselig_staff_portal/utils/time_utils.dart';

/// 打卡卡片元件
/// 顯示單一時段的打卡狀態和操作按鈕
class AttendancePunchCard extends StatelessWidget {
  final String period;
  final String displayName;
  final String? checkInTime;
  final String? checkOutTime;
  final VoidCallback? onEditName;
  final VoidCallback? onCheckIn;
  final VoidCallback? onCheckOut;

  const AttendancePunchCard({
    super.key,
    required this.period,
    required this.displayName,
    this.checkInTime,
    this.checkOutTime,
    this.onEditName,
    this.onCheckIn,
    this.onCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    final uiSettings = context.watch<UiSettingsProvider>();
    final hasCheckedIn = checkInTime != null;
    final hasCheckedOut = checkOutTime != null;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 時段名稱編輯行
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 18 * uiSettings.fontSizeScale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onEditName != null)
                  IconButton(
                    icon: Icon(Icons.edit, size: 20),
                    tooltip: '編輯時段名稱',
                    onPressed: onEditName,
                  ),
              ],
            ),
            SizedBox(height: 8),
            // 打卡狀態和按鈕
            if (hasCheckedIn && hasCheckedOut)
              _buildCompletedStatus(context)
            else if (hasCheckedIn)
              _buildCheckOutButton(context)
            else
              _buildCheckInButton(context),
          ],
        ),
      ),
    );
  }

  /// 已完成打卡的狀態
  Widget _buildCompletedStatus(BuildContext context) {
    final uiSettings = context.watch<UiSettingsProvider>();
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
          SizedBox(width: 8),
          Text(
            '${formatTime(checkInTime)} ~ ${formatTime(checkOutTime)}',
            style: TextStyle(
              fontSize: (16 * uiSettings.fontSizeScale).toDouble(),
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  /// 下班打卡按鈕（已上班）
  Widget _buildCheckOutButton(BuildContext context) {
    final uiSettings = context.watch<UiSettingsProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(isMobile ? 8 : 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.login,
                  color: Theme.of(context).colorScheme.primary,
                  size: isMobile ? 16 : 20,
                ),
                SizedBox(width: isMobile ? 4 : 8),
                Text(
                  '上班時間：${formatTime(checkInTime)}',
                  style: TextStyle(
                    fontSize: ((isMobile ? 12 : 14) * uiSettings.fontSizeScale)
                        .toDouble(),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: isMobile ? 8 : 16),
        ElevatedButton.icon(
          icon: Icon(Icons.logout, size: isMobile ? 16 : 20),
          label: Text(
            '下班打卡',
            style: TextStyle(
              fontSize: ((isMobile ? 12 : 14) * uiSettings.fontSizeScale)
                  .toDouble(),
            ),
          ),
          onPressed: onCheckOut,
        ),
      ],
    );
  }

  /// 上班打卡按鈕（尚未打卡）
  Widget _buildCheckInButton(BuildContext context) {
    final uiSettings = context.watch<UiSettingsProvider>();
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 8),
                Text(
                  '尚未打卡',
                  style: TextStyle(
                    fontSize: (14 * uiSettings.fontSizeScale).toDouble(),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 16),
        ElevatedButton.icon(
          icon: Icon(Icons.login),
          label: Text(
            '上班打卡',
            style: TextStyle(
              fontSize: (14 * uiSettings.fontSizeScale).toDouble(),
            ),
          ),
          onPressed: onCheckIn,
        ),
      ],
    );
  }
}
