import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:otti_calendar/models/holiday.dart';
import 'package:otti_calendar/models/schedule.dart';
import 'package:otti_calendar/services/holiday_service.dart';
import 'package:otti_calendar/services/schedule_service.dart';
import 'package:otti_calendar/services/ai_quick_schedule_service.dart';
import 'package:otti_calendar/features/calendar/widgets/calendar_card.dart';
import 'package:otti_calendar/features/schedule/widgets/schedule_list_view.dart';
import 'package:otti_calendar/features/schedule/widgets/add_schedule_bottom_sheet.dart';
import 'package:otti_calendar/features/schedule/widgets/bottom_input_bar.dart';
import 'package:lunar/lunar.dart' hide Holiday;
import 'package:otti_calendar/features/profile/main_drawer.dart';
import 'package:otti_calendar/features/common/widgets/custom_date_picker.dart';
import 'package:otti_calendar/services/floating_window_coordinator.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _pendingJumpDay;
  Map<DateTime, Holiday> _holidayData = {};
  final HolidayService _holidayService = HolidayService();
  final ScheduleService _scheduleService = ScheduleService();
  final AiQuickScheduleService _aiQuickScheduleService = AiQuickScheduleService();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  late PageController _pageController;
  final DateTime _firstDay = DateTime.utc(2010, 10, 16);
  final DateTime _lastDay = DateTime.utc(2030, 3, 14);

  List<Schedule> _currentSchedules = [];
  bool _isListLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = DateTime(now.year, now.month, now.day);
    _pageController = PageController(initialPage: _getPageIndex(_focusedDay));
    FloatingWindowCoordinator.instance.initialize(
      onScheduleCreated: (schedule) async {
        if (!mounted) return;
        final targetDate = DateTime.tryParse(schedule.scheduleDate) ?? DateTime.now();
        _jumpToDate(targetDate);
        _showMiddleTip('日程添加成功');
        await Future.delayed(const Duration(milliseconds: 120));
        _fetchSchedules();
      },
    );
    _fetchHolidays();
    _fetchSchedules(); 
  }

  @override
  void dispose() {
    FloatingWindowCoordinator.instance.dispose();
    _pageController.dispose();
    super.dispose();
  }

  int _getPageIndex(DateTime day) {
    return (day.year - _firstDay.year) * 12 + (day.month - _firstDay.month);
  }

  DateTime _getDateFromIndex(int index) {
    return DateTime(_firstDay.year, _firstDay.month + index, 1);
  }

  Future<void> _fetchHolidays() async {
    final holidays = await _holidayService.fetchHolidays();
    if (mounted) {
      setState(() {
        _holidayData = holidays;
      });
    }
  }

  Future<void> _fetchSchedules() async {
    if (_selectedDay == null) return;
    final String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    
    debugPrint('[Network] 正在请求日期: $dateStr 的日程...');
    setState(() => _isListLoading = true);
    
    try {
      final schedules = await _scheduleService.getSchedulesByDate(_selectedDay!);
      if (mounted) {
        debugPrint('[Network] 成功返回 ${schedules.length} 条日程。');
        setState(() {
          _currentSchedules = schedules;
          _isListLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Network] 请求异常: $e');
      if (mounted) setState(() => _isListLoading = false);
    }
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
    } else {
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

  void _showMiddleTip(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15, decoration: TextDecoration.none),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddScheduleSheet() async {
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddScheduleBottomSheet(),
    );

    if (result == true) {
      _showMiddleTip('日程添加成功');
      _fetchSchedules();
    } else if (result is Map && result['action'] == 'aiQuickCreate') {
      final text = result['text']?.toString() ?? '';
      await _handleAiQuickCreate(text);
    }
  }

  Future<void> _handleAiQuickCreate(String text) async {
    if (text.trim().isEmpty) return;
    try {
      final schedule = await _aiQuickScheduleService.createQuickSchedule(text.trim());
      if (!mounted) return;
      final targetDate = DateTime.tryParse(schedule.scheduleDate) ?? DateTime.now();
      _jumpToDate(targetDate);
      _showMiddleTip('日程添加成功');
      Future.delayed(const Duration(milliseconds: 120), _fetchSchedules);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('日程添加失败: $e')),
      );
    }
  }

  void _jumpToDate(DateTime target) {
    final normalized = DateTime(target.year, target.month, target.day);
    final targetPage = _getPageIndex(normalized);

    setState(() {
      _focusedDay = normalized;
      _selectedDay = normalized;
      _pendingJumpDay = normalized;
    });

    if (_pageController.hasClients) {
      final currentPage = _pageController.page?.round();
      if (currentPage == targetPage) {
        _pendingJumpDay = null;
      }
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _jumpToToday() {
    final now = DateTime.now();
    final targetPage = _getPageIndex(now);
    
    setState(() {
      _focusedDay = now;
      _selectedDay = DateTime(now.year, now.month, now.day);
      _pendingJumpDay = null;
    });

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    Future.delayed(const Duration(milliseconds: 100), _fetchSchedules);
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
                      final targetPage = _getPageIndex(tempDate);
                      setState(() {
                        _focusedDay = tempDate;
                        _selectedDay = tempDate;
                      });
                      if (_pageController.hasClients) {
                        _pageController.jumpToPage(targetPage);
                      }
                      Navigator.pop(context);
                      _fetchSchedules();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      drawer: const MainDrawer(),
      appBar: AppBar(
        title: Text('${_focusedDay.year}年${_focusedDay.month}月', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
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
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    final newDate = _getDateFromIndex(index);
                    final pending = _pendingJumpDay;
                    final usePending = pending != null &&
                        pending.year == newDate.year &&
                        pending.month == newDate.month;
                    setState(() {
                      if (usePending) {
                        _focusedDay = pending!;
                        _selectedDay = pending;
                        _pendingJumpDay = null;
                      } else {
                        _focusedDay = newDate;
                        _selectedDay = DateTime(newDate.year, newDate.month, 1);
                      }
                    });
                    _fetchSchedules();
                  },
                  itemBuilder: (context, index) {
                    final dateForPage = _getDateFromIndex(index);

                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is UserScrollNotification) {
                          final direction = notification.direction;
                          if (direction == ScrollDirection.reverse && _calendarFormat == CalendarFormat.month) {
                            setState(() {
                              _calendarFormat = CalendarFormat.week;
                            });
                          } else if (direction == ScrollDirection.forward && notification.metrics.pixels <= 0 && _calendarFormat == CalendarFormat.week) {
                            setState(() {
                              _calendarFormat = CalendarFormat.month;
                            });
                          }
                        }
                        return false;
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          CalendarCard(
                            focusedDay: _focusedDay.month == dateForPage.month && _focusedDay.year == dateForPage.year 
                                ? _focusedDay 
                                : dateForPage,
                            selectedDay: _selectedDay,
                            holidayData: _holidayData,
                            calendarFormat: _calendarFormat,
                            availableGestures: AvailableGestures.none,
                            onFormatChanged: (format) {
                              if (_calendarFormat != format) {
                                setState(() {
                                  _calendarFormat = format;
                                });
                              }
                            },
                            onDaySelected: (selectedDay, focusedDay) {
                              if (selectedDay.month != dateForPage.month) return;
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                              _fetchSchedules();
                            },
                            onPageChanged: (focusedDay) {},
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(_formatSelectedDay(_selectedDay), style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 16),
                          
                          if (_isListLoading)
                            const Center(child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ))
                          else if (_currentSchedules.isEmpty)
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
                            ScheduleListView(
                              schedules: _currentSchedules.map((s) => s.toJson()).toList(),
                              onActionComplete: (action) {
                                String? actionType;
                                String? actionDate;

                                if (action is Map) {
                                  actionType = action['action']?.toString();
                                  actionDate = action['date']?.toString();
                                } else if (action is String) {
                                  actionType = action;
                                }

                                if (actionType == 'updated') {
                                  _showMiddleTip('修改成功');
                                } else if (actionType == 'deleted') {
                                  _showMiddleTip('删除成功');
                                }

                                if (actionDate != null && actionDate.isNotEmpty) {
                                  final target = DateTime.tryParse(actionDate);
                                  if (target != null) {
                                    _jumpToDate(target);
                                  }
                                }

                                _fetchSchedules(); // 刷新列表
                              },
                            ),
                        ],
                      ),
                    );
                  },
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
                  child: const Text(
                    '今',
                    style: TextStyle(
                      fontSize: 22,
                      color: Color.fromRGBO(33, 150, 243, 1),
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
}
