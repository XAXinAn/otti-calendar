import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:otti_calendar/models/holiday.dart';

class HolidayService {
  Future<Map<DateTime, Holiday>> fetchHolidays() async {
    final url = 'https://cdn.jsdelivr.net/npm/chinese-days/dist/holidays.ics';
    final Map<DateTime, Holiday> tempHolidayData = {};
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final icp = ICalendar.fromString(response.body);

        for (var event in icp.data) {
          if (event['type'] == 'VEVENT') {
            DateTime? dtStart = (event['dtstart'] as IcsDateTime?)?.toDateTime();
            String summary = event['summary'] ?? '';

            if (dtStart != null && summary.isNotEmpty) {
              String holidayType = '';
              String holidayName = summary;

              if (summary.contains('(班)')) {
                holidayType = '班';
                holidayName = summary.replaceAll('(班)', '');
              } else if (summary.contains('(休)')) {
                holidayType = '休';
                holidayName = summary.replaceAll('(休)', '');
              }

              if (holidayType.isNotEmpty) {
                DateTime start = DateTime(dtStart.year, dtStart.month, dtStart.day);
                DateTime? dtEnd = (event['dtend'] as IcsDateTime?)?.toDateTime();
                if (dtEnd != null) {
                  DateTime end = DateTime(dtEnd.year, dtEnd.month, dtEnd.day);
                  for (var d = start; d.isBefore(end); d = d.add(const Duration(days: 1))) {
                    final isFirst = d.year == start.year && d.month == start.month && d.day == start.day;
                    tempHolidayData[d] = Holiday(name: holidayName, type: holidayType, isFirstDay: isFirst);
                  }
                } else {
                  tempHolidayData[start] = Holiday(name: holidayName, type: holidayType, isFirstDay: true);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('获取节假日失败: $e');
    }
    return tempHolidayData;
  }
}
