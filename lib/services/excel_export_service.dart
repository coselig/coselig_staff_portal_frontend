import 'dart:html' as html;

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
      print('========== 開始匯出Excel ==========');
      print('員工: $employeeName ($employeeId)');
      print('月份: ${month.year}/${month.month}');

      // 創建Excel檔案
      print('開始創建Excel檔案...');
      var excel = Excel.createExcel();

      // 創建打卡記錄工作表
      _createAttendanceSheet(excel, employeeName, employeeId, monthRecords, month);

      // 刪除預設的空白Sheet1
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
        print('✓ 已刪除預設的空白工作表 Sheet1');
      }

      // 下載檔案
      _downloadExcelFile(excel, '${employeeName}_打卡記錄_${month.year}_${month.month}');
    } catch (e) {
      print('匯出Excel失敗: $e');
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
    print('創建打卡記錄工作表，共 ${monthRecords.length} 筆記錄');
    var sheet = excel['打卡記錄'];

    // 設定標題列
    final headers = [
      '日期',
      '員工編號',
      '員工姓名',
      '上班時間',
      '下班時間',
      '工作時數',
      '狀態',
    ];

    print('設定標題列...');

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
    print('開始寫入資料...');
    var rowIndex = 1;

    for (var day = 1; day <= daysInMonth; day++) {
      final record = monthRecords[day];
      final date = DateTime(month.year, month.month, day);

      // 日期
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(date));

      // 員工編號
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(employeeId);

      // 員工姓名
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(employeeName);

      if (record != null) {
        // 上班時間
        final checkInTime = record['check_in_time'];
        if (checkInTime != null) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
              .value = TextCellValue(checkInTime);
        }

        // 下班時間
        final checkOutTime = record['check_out_time'];
        if (checkOutTime != null) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
              .value = TextCellValue(checkOutTime);
        }

        // 工作時數
        if (checkInTime != null && checkOutTime != null) {
          final workHours = _calculateWorkHours(checkInTime, checkOutTime);
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
              .value = DoubleCellValue(workHours);
        }

        // 狀態
        String status = '已打卡';
        if (checkInTime != null && checkOutTime == null) {
          status = '上班未下班';
        } else if (checkInTime == null && checkOutTime != null) {
          status = '下班未上班';
        }
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
            .value = TextCellValue(status);
      } else {
        // 狀態 - 未打卡
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
            .value = TextCellValue('未打卡');
      }

      rowIndex++;
    }

    print('✓ 打卡記錄工作表創建完成');
  }

  /// 下載Excel檔案
  void _downloadExcelFile(Excel excel, String baseName) {
    print('開始編碼Excel檔案...');

    final bytes = excel.encode();
    if (bytes == null) {
      print('❌ Excel編碼失敗');
      throw Exception('無法編碼Excel檔案');
    }

    print('✓ Excel檔案大小: ${bytes.length} bytes');

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '${baseName}_$timestamp.xlsx';

    print('準備下載檔案: $fileName');

    // 創建Blob並下載
    final blob = html.Blob([
      bytes,
    ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);

    print('✓ Excel檔案已下載');
  }

  /// 格式化日期
  String _formatDate(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd').format(dateTime);
  }

  /// 計算工作時數
  double _calculateWorkHours(String checkInTime, String checkOutTime) {
    try {
      // 假設時間格式為 HH:mm 或 HH:mm:ss
      final checkInParts = checkInTime.split(':');
      final checkOutParts = checkOutTime.split(':');

      final checkInHour = int.parse(checkInParts[0]);
      final checkInMinute = int.parse(checkInParts[1]);

      final checkOutHour = int.parse(checkOutParts[0]);
      final checkOutMinute = int.parse(checkOutParts[1]);

      final checkInTotalMinutes = checkInHour * 60 + checkInMinute;
      final checkOutTotalMinutes = checkOutHour * 60 + checkOutMinute;

      final durationMinutes = checkOutTotalMinutes - checkInTotalMinutes;
      final hours = durationMinutes / 60.0;

      return hours > 0 ? hours : 0.0;
    } catch (e) {
      print('計算工作時數失敗: $e');
      return 0.0;
    }
  }
}