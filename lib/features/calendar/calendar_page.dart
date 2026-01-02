import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:otti_calendar/models/holiday.dart';
import 'package:otti_calendar/services/holiday_service.dart';
import 'package:otti_calendar/features/calendar/widgets/calendar_card.dart';
import 'package:otti_calendar/features/schedule/widgets/schedule_list_view.dart';
import 'package:otti_calendar/features/schedule/widgets/add_schedule_bottom_sheet.dart';
import 'package:otti_calendar/features/schedule/widgets/bottom_input_bar.dart';
import 'package:lunar/lunar.dart' hide Holiday;
import 'package:otti_calendar/features/profile/main_drawer.dart';
import 'package:otti_calendar/features/common/widgets/custom_date_picker.dart'; // Import the new picker
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, Holiday> _holidayData = {};
  final HolidayService _holidayService = HolidayService();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  final List<Map<String, dynamic>> _allSchedules = [
    // ... mock data ...
  ];

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _fetchHolidays();
  }

  Future<void> _fetchHolidays() async {
    final holidays = await _holidayService.fetchHolidays();
    if (mounted) {
      setState(() {
        _holidayData = holidays;
      });
    }
  }

  List<Map<String, dynamic>> _getSchedulesForDay(DateTime day) {
    return _allSchedules.where((schedule) => DateUtils.isSameDay(schedule['date'] as DateTime?, day)).toList();
  }

  String _formatSelectedDay(DateTime? day) {
    if (day == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(day.year, day.month, day.day);
    final difference = selectedDate.difference(today).inDays;

    String dayPrefix;
    if (difference == 0) {
      dayPrefix = '今天';
    } else if (difference == 1) {
      dayPrefix = '明天';
    } else if (difference == 2) {
      dayPrefix = '后天';
    } else if (difference == -1) {
      dayPrefix = '昨天';
    } else if (difference == -2) {
      dayPrefix = '前天';
    } else if (difference > 2) {
      dayPrefix = '$difference天后';
    } else { // difference < -2
      dayPrefix = '${-difference}天前';
    }
    
    final lunar = Lunar.fromDate(day);
    const traditionalMonthNames = {1: '正月', 11: '冬月', 12: '腊月'};
    const lunarNumericMonth = {1: '一', 2: '二', 3: '三', 4: '四', 5: '五', 6: '六', 7: '七', 8: '八', 9: '九', 10: '十', 11: '十一', 12: '十二'};

    final int lunarMonth = lunar.getMonth();
    String lunarDateString;

    if (traditionalMonthNames.containsKey(lunarMonth)) {
      final String numericMonth = lunarNumericMonth[lunarMonth]!;
      final String traditionalName = traditionalMonthNames[lunarMonth]!;
      lunarDateString = '农历$numericMonth月($traditionalName)${lunar.getDayInChinese()}';
    } else {
      lunarDateString = '农历${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
    }

    return '$dayPrefix $lunarDateString';
  }

  void _showAddScheduleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddScheduleBottomSheet(),
    );
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _focusedDay = now;
      _selectedDay = DateTime(now.year, now.month, now.day);
    });
  }

  void _showDatePicker() {
    DateTime tempDate = _selectedDay ?? DateTime.now();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height / 3,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消', style: TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _focusedDay = tempDate;
                        _selectedDay = tempDate;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('完成', style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CustomDatePicker(
                initialDate: _selectedDay ?? DateTime.now(),
                onDateChanged: (newDate) {
                  tempDate = newDate;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedSchedules = _getSchedulesForDay(_selectedDay ?? DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      drawer: const MainDrawer(),
      appBar: AppBar(
        title: Text('${_focusedDay.year}年${_focusedDay.month}月', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is UserScrollNotification) {
                      final direction = notification.direction;
                      if (direction == ScrollDirection.reverse && _calendarFormat == CalendarFormat.month) {
                        setState(() {
                          _calendarFormat = CalendarFormat.week;
                        });
                      } else if (direction == ScrollDirection.forward && notification.metrics.pixels == 0 && _calendarFormat == CalendarFormat.week) {
                        setState(() {
                          _calendarFormat = CalendarFormat.month;
                        });
                      }
                    }
                    return false;
                  },
                  child: ListView(
                    children: [
                      CalendarCard(
                        focusedDay: _focusedDay,
                        selectedDay: _selectedDay,
                        holidayData: _holidayData,
                        calendarFormat: _calendarFormat,
                        onFormatChanged: (format) {
                          if (_calendarFormat != format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          }
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          if (selectedDay.month != focusedDay.month) {
                            return;
                          }
                          if (!DateUtils.isSameDay(_selectedDay, selectedDay)) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          }
                        },
                        onPageChanged: (focusedDay) {
                          final now = DateTime.now();
                          DateTime newSelectedDay;
                          if (focusedDay.month == now.month && focusedDay.year == now.year) {
                            newSelectedDay = DateTime(now.year, now.month, now.day);
                          } else {
                            newSelectedDay = DateTime(focusedDay.year, focusedDay.month, 1);
                          }
                          setState(() {
                            _focusedDay = focusedDay;
                            _selectedDay = newSelectedDay;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(_formatSelectedDay(_selectedDay), style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      if (selectedSchedules.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              const Text('没有日程', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        )
                      else
                        ScheduleListView(schedules: selectedSchedules),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: _showAddScheduleSheet,
                child: const BottomInputBar(),
              ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'datePicker',
                  onPressed: _showDatePicker,
                  backgroundColor: Colors.white,
                  elevation: 4.0,
                  child: const Icon(Icons.calendar_today_outlined, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'jumpToToday',
                  onPressed: _jumpToToday,
                  backgroundColor: Colors.white,
                  elevation: 4.0,
                  child: Text(
                    '今',
                    style: TextStyle(
                      fontSize: 22,
                      color: const Color.fromRGBO(33, 150, 243, 1),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  DateTime get now => DateTime.now();
}
