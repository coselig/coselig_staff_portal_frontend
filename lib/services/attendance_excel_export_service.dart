import 'package:universal_html/html.dart' as html;

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

class ExcelExportService {
  /// 匯出員工的打卡記錄到Excel
  Future<void> exportAttendanceRecords({
    required String employeeName,
    required String employeeId,
    required Map<int, dynamic> monthRecords,
    required DateTime month,
  }) async {
    try {
      // 創建Excel檔案
      var excel = Excel.createExcel();

      // 創建打卡記錄工作表
      _createAttendanceSheet(excel, employeeName, employeeId, monthRecords, month);

      // 刪除預設的空白Sheet1
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // 下載檔案
      _downloadExcelFile(excel, '${employeeName}_打卡記錄_${month.year}_${month.month}');
    } catch (e) {
      rethrow;
    }
  }

  /// 創建打卡記錄工作表
  void _createAttendanceSheet(
    Excel excel,
    String employeeName,
    String employeeId,
    Map<int, dynamic> monthRecords,
    DateTime month,
  ) {
    var sheet = excel['打卡記錄'];

    // 設定標題列
    final headers = [
      '日期',
      '員工編號',
      '員工姓名',
      '時段',
      '上班時間',
      '下班時間',
      '工作時數',
      '狀態',
    ];

    // 寫入標題
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue200,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // 獲取該月的天數
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // 寫入資料
    var rowIndex = 1;
    double totalSeconds = 0.0;

    for (var day = 1; day <= daysInMonth; day++) {
      final record = monthRecords[day];
      final date = DateTime(month.year, month.month, day);

      if (record != null) {
        // 提取所有時段（找出所有 _check_in_time 結尾的欄位）
        final periods = <String>[];
        record.forEach((key, value) {
          if (key is String && key.endsWith('_check_in_time')) {
            final period = key.replaceAll('_check_in_time', '');
            periods.add(period);
          }
        });

        if (periods.isEmpty) {
          // 如果沒有任何時段打卡記錄，當作未打卡
          _writeRow(
            sheet,
            rowIndex,
            date,
            employeeId,
            employeeName,
            '',
            null,
            null,
            '未打卡',
          );
          rowIndex++;
        } else {
          // 為每個時段寫一行
          for (final period in periods) {
            final checkInTime = record['${period}_check_in_time'];
            final checkOutTime = record['${period}_check_out_time'];

            String status = '已打卡';
            double? workHours;
            if (checkInTime != null && checkOutTime != null) {
              workHours = _calculateWorkHours(checkInTime, checkOutTime);
              status = '已打卡';
              totalSeconds += workHours;
            } else if (checkInTime != null && checkOutTime == null) {
              status = '上班未下班';
            } else if (checkInTime == null && checkOutTime != null) {
              status = '下班未上班';
            }

            _writeRow(
              sheet,
              rowIndex,
              date,
              employeeId,
              employeeName,
              period, // 直接使用時段名稱
              checkInTime,
              checkOutTime,
              status,
              workHours: workHours,
            );
            rowIndex++;
          }
        }
      } else {
        // 未打卡
        _writeRow(
          sheet,
          rowIndex,
          date,
          employeeId,
          employeeName,
          '',
          null,
          null,
          '未打卡',
        );
        rowIndex++;
      }
    }

    // 寫入總計行
    _writeTotalRow(sheet, rowIndex, totalSeconds);
    rowIndex++;
  }

  void _writeRow(
    Sheet sheet,
    int rowIndex,
    DateTime date,
    String employeeId,
    String employeeName,
    String periodName,
    String? checkInTime,
    String? checkOutTime,
    String status, {
    double? workHours,
  }) {
    // 日期
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .value = TextCellValue(
      _formatDate(date),
    );

    // 員工編號
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        .value = TextCellValue(
      employeeId,
    );

    // 員工姓名
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
        .value = TextCellValue(
      employeeName,
    );

    // 時段
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
        .value = TextCellValue(
      periodName,
    );

    // 上班時間
    if (checkInTime != null) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(
        checkInTime,
      );
    }

    // 下班時間
    if (checkOutTime != null) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(
        checkOutTime,
      );
    }

    // 工作時數
    if (workHours != null) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(
        _formatDuration(workHours),
      );
    }

    // 狀態
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
        .value = TextCellValue(
      status,
    );
  }

  void _writeTotalRow(Sheet sheet, int rowIndex, double totalSeconds) {
    // 狀態
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
        .value = TextCellValue(
      '總計',
    );

    // 工作時數
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
        .value = TextCellValue(
      _formatDuration(totalSeconds),
    );
  }

  /// 下載Excel檔案
  void _downloadExcelFile(Excel excel, String baseName) {
    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('無法編碼Excel檔案');
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '${baseName}_$timestamp.xlsx';

    // 創建Blob並下載
    final blob = html.Blob([
      bytes,
    ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  /// 格式化日期
  String _formatDate(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd').format(dateTime);
  }

  /// 格式化持續時間為 HH:MM
  String _formatDuration(double seconds) {
    int totalSeconds = seconds.toInt();
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  /// 計算工作時數
  double _calculateWorkHours(String checkInTime, String checkOutTime) {
    try {
      final checkIn = DateTime.parse(checkInTime);
      var checkOut = DateTime.parse(checkOutTime);
      // 若下班時間早於上班時間，視為跨日班次，將下班時間加一天
      if (checkOut.isBefore(checkIn)) {
        checkOut = checkOut.add(Duration(days: 1));
      }
      final duration = checkOut.difference(checkIn);
      return duration.inSeconds.toDouble();
    } catch (e) {
      return 0.0;
    }
  }
}