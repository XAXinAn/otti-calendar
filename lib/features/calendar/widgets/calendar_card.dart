import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:otti_calendar/models/holiday.dart';
import 'package:lunar/lunar.dart' hide Holiday;

// Top-level function, accessible from other files that import this file.
String getLunarString(DateTime day, Map<DateTime, Holiday> holidayData) {
  final holiday = holidayData[DateTime(day.year, day.month, day.day)];
  if (holiday != null && holiday.isFirstDay && holiday.type == '休') {
    return holiday.name;
  }

  Lunar lunar = Lunar.fromDate(day);
  List<String> festivals = lunar.getFestivals();
  if (festivals.isNotEmpty) return festivals[0];

  String solarTerm = lunar.getJieQi();
  if (solarTerm.isNotEmpty) return solarTerm;

  return lunar.getDay() == 1 ? lunar.getMonthInChinese() + '月' : lunar.getDayInChinese();
}

class CalendarCard extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<DateTime, Holiday> holidayData;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final CalendarFormat calendarFormat; // Add this
  final Function(CalendarFormat) onFormatChanged; // Add this

  const CalendarCard({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.holidayData,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.calendarFormat, // Add this
    required this.onFormatChanged, // Add this
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          locale: 'zh_CN',
          rowHeight: 60,
          firstDay: DateTime.utc(2010, 10, 16),
          lastDay: DateTime.utc(2030, 3, 14),
          focusedDay: focusedDay,
          calendarFormat: calendarFormat, // Use the passed format
          onFormatChanged: onFormatChanged, // Use the passed callback
          availableGestures: AvailableGestures.all, // Corrected from horizontalAndVertical to all
          headerVisible: false,
          startingDayOfWeek: StartingDayOfWeek.sunday,
          calendarStyle: const CalendarStyle(cellPadding: EdgeInsets.zero),
          enabledDayPredicate: (day) => day.month == focusedDay.month && day.year == focusedDay.year,
          calendarBuilders: CalendarBuilders(
            dowBuilder: (context, day) {
              const dowText = {1: '一', 2: '二', 3: '三', 4: '四', 5: '五', 6: '六', 7: '日'};
              return Center(child: Text(dowText[day.weekday]!, style: const TextStyle(color: Colors.black87, fontSize: 13)));
            },
            prioritizedBuilder: (context, day, focusedDay) {
              final isToday = DateUtils.isSameDay(day, DateTime.now());
              final isSelected = DateUtils.isSameDay(day, selectedDay);
              final isOutside = day.month != focusedDay.month || day.year != focusedDay.year;
              final holiday = holidayData[DateTime(day.year, day.month, day.day)];
              final lunarText = getLunarString(day, holidayData);

              BoxDecoration? decoration;
              TextStyle dayTextStyle;
              TextStyle lunarTextStyle;
              Color? holidayColor;

              if (isSelected && isToday) {
                decoration = const BoxDecoration(color: Colors.blue, shape: BoxShape.circle);
                dayTextStyle = const TextStyle(color: Colors.white, fontSize: 18, height: 1.1);
                lunarTextStyle = const TextStyle(color: Colors.white, fontSize: 11, height: 1.0);
                holidayColor = Colors.white;
              } else if (isSelected) {
                decoration = BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blue, width: 1.5));
                dayTextStyle = const TextStyle(color: Colors.black, fontSize: 18, height: 1.1);
                lunarTextStyle = const TextStyle(color: Colors.grey, fontSize: 11, height: 1.0);
                holidayColor = holiday?.type == '休' ? Colors.blue : Colors.red;
              } else if (isToday) {
                decoration = null;
                dayTextStyle = const TextStyle(color: Colors.blue, fontSize: 18, height: 1.1);
                lunarTextStyle = const TextStyle(color: Colors.blue, fontSize: 11, height: 1.0);
                holidayColor = holiday?.type == '休' ? Colors.blue : Colors.red;
              } else {
                decoration = null;
                dayTextStyle = const TextStyle(color: Colors.black, fontSize: 18, height: 1.1);
                lunarTextStyle = const TextStyle(color: Colors.grey, fontSize: 11, height: 1.0);
                holidayColor = holiday?.type == '休' ? Colors.blue : Colors.red;
              }

              if (isOutside) {
                dayTextStyle = TextStyle(color: Colors.grey.shade400, fontSize: 18, height: 1.1);
                lunarTextStyle = TextStyle(color: Colors.grey.shade400, fontSize: 11, height: 1.0);
                holidayColor = null;
              }

              Widget dayCell = AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: decoration,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${day.day}', style: dayTextStyle),
                      Text(lunarText, style: lunarTextStyle, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );

              if (holiday != null && holidayColor != null && !isOutside) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    dayCell,
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Text(
                        holiday.type,
                        style: TextStyle(color: holidayColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              }
              return dayCell;
            },
          ),
          selectedDayPredicate: (day) => DateUtils.isSameDay(day, selectedDay),
          onDaySelected: onDaySelected,
          onPageChanged: onPageChanged,
        ),
      ),
    );
  }
}
