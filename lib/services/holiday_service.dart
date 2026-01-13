import 'dart:convert';
import 'package:http/http.dart' as http;

class HolidayService {
  /// 取得台灣某年份的國定假日（行政院公開資料）
  Future<List<Holiday>> fetchTaiwanHolidays(int year) async {
    final url =
        'https://cdn.jsdelivr.net/gh/ruyut/TaiwanCalendar/data/$year.json';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<Holiday> holidays = [];
        
        // 新版格式直接是 List，舊版是 {"days": List}
        final List<dynamic> daysList = data is List
            ? data
            : (data['days'] as List<dynamic>? ?? []);

        for (final item in daysList) {
          if (item is Map) {
            final isHoliday = item['isHoliday'] == true;
            final dateStr = item['date']?.toString();
            final description = item['description']?.toString();

            // 檢查是否為假日
            if (isHoliday) {
              String? holidayName = description;

              if (dateStr != null && dateStr.length == 8) {
                // 格式化日期從 "20260101" 到 "2026-01-01"
                final year = dateStr.substring(0, 4);
                final month = dateStr.substring(4, 6);
                final day = dateStr.substring(6, 8);
                final formattedDate = '$year-$month-$day';

                // 如果沒有 description 或為空字符串，則根據日期判斷是否為週末
                if (holidayName == null || holidayName.isEmpty) {
                  try {
                    final date = DateTime.parse(formattedDate);
                    if (date.weekday == DateTime.saturday ||
                        date.weekday == DateTime.sunday) {
                      holidayName = '週末';
                    } else {
                      holidayName = '國定假日'; // 國定假日但沒有特定名稱
                    }
                  } catch (e) {
                    holidayName = '假日';
                  }
                }

                holidays.add(Holiday(
                  date: formattedDate, name: holidayName));
              }
            }
          }
        }

        return holidays;
      } else {
        throw Exception('HTTP ${response.statusCode}: 無法取得國定假日資料');
      }
    } catch (e) {
      // 如果 API 失敗，返回基本的台灣國定假日
      return _getFallbackHolidays(year);
    }
  }

  /// 備用假日清單（當 API 失敗時使用）
  List<Holiday> _getFallbackHolidays(int year) {
    return [
      Holiday(date: '$year-01-01', name: '中華民國開國紀念日'),
      Holiday(date: '$year-02-28', name: '和平紀念日'),
      Holiday(date: '$year-10-10', name: '國慶日'),
    ];
  }
}

class Holiday {
  final String date; // yyyy-MM-dd
  final String name;
  Holiday({required this.date, required this.name});
}
