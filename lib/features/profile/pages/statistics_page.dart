import 'package:flutter/material.dart';
import 'package:otti_calendar/models/schedule.dart';
import 'package:otti_calendar/services/schedule_service.dart';
import 'package:intl/intl.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final ScheduleService _scheduleService = ScheduleService();
  bool _isLoading = true;
  List<Schedule> _displaySchedules = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    
    // 为了覆盖未来24h和过去3h，我们需要获取今天和明天的日程
    final todaySchedules = await _scheduleService.getSchedulesByDate(now);
    final tomorrowSchedules = await _scheduleService.getSchedulesByDate(now.add(const Duration(days: 1)));
    final yesterdaySchedules = await _scheduleService.getSchedulesByDate(now.subtract(const Duration(days: 1)));

    final allSchedules = [...yesterdaySchedules, ...todaySchedules, ...tomorrowSchedules];
    
    final threeHoursAgo = now.subtract(const Duration(hours: 3));
    final twentyFourHoursLater = now.add(const Duration(hours: 24));

    // 筛选逻辑
    _displaySchedules = allSchedules.where((s) {
      if (s.scheduleDate.isEmpty) return false;
      
      // 解析日期和时间
      DateTime scheduleTime;
      if (s.startTime != null && s.startTime!.isNotEmpty) {
        scheduleTime = DateTime.parse("${s.scheduleDate} ${s.startTime}");
      } else {
        // 如果没有具体时间，视为当天 00:00
        scheduleTime = DateTime.parse(s.scheduleDate);
      }

      return scheduleTime.isAfter(threeHoursAgo) && scheduleTime.isBefore(twentyFourHoursLater);
    }).toList();

    // 按时间排序
    _displaySchedules.sort((a, b) {
      final timeA = DateTime.parse("${a.scheduleDate} ${a.startTime ?? '00:00'}");
      final timeB = DateTime.parse("${b.scheduleDate} ${b.startTime ?? '00:00'}");
      return timeA.compareTo(timeB);
    });

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('数据统计', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 10),
              _buildTimelineCard(),
              const SizedBox(height: 24),
              _buildChartCard('饼状图：统计本月内各分类的日程的数量分布情况'),
              const SizedBox(height: 24),
              _buildChartCard('条形图与折线图结合：统计前四周到后三周每周的日程数量'),
              const SizedBox(height: 40),
            ],
          ),
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '这里放置的是未来24小时内的日程和已经截止的过去3小时内的日程',
            style: TextStyle(fontSize: 18, height: 1.5, fontWeight: FontWeight.w500),
          ),
          if (_displaySchedules.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            ..._displaySchedules.map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Text(s.startTime ?? '全天', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(s.title, style: const TextStyle(fontSize: 15, color: Colors.black87))),
                ],
              ),
            )),
          ]
        ],
      ),
    );
  }

  Widget _buildChartCard(String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Center(
        child: Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, height: 1.5, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
