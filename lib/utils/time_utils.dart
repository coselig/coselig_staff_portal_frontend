/// 時間格式化工具，將 yyyy-MM-dd HH:mm:ss 轉為台灣時區（+8）並回傳 HH:mm
String formatTime(String? dt) {
  if (dt == null || dt.isEmpty) return '--';
  try {
    final parts = dt.split(' ');
    if (parts.length == 2) {
      final datePart = parts[0];
      final timePart = parts[1];
      final dateTime = DateTime.parse('$datePart $timePart');
      final twDateTime = dateTime.toUtc().add(const Duration(hours: 16));
      return '${twDateTime.hour.toString().padLeft(2, '0')}:${twDateTime.minute.toString().padLeft(2, '0')}';
    }
    return dt;
  } catch (_) {
    return dt;
  }
}
