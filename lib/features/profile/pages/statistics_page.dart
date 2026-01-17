import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:otti_calendar/models/schedule.dart';
import 'package:otti_calendar/services/schedule_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final ScheduleService _scheduleService = ScheduleService();
  bool _isLoading = true;
  List<Schedule> _displaySchedules = [];
  List<Schedule> _monthSchedules = [];
  List<Schedule> _rangeSchedules = [];
  List<int> _weeklyCounts = const [];

  static const Map<String, Color> _categoryColors = {
    '工作': Color(0xFF2196F3),
    '学习': Color(0xFF4CAF50),
    '个人': Color(0xFFFF9800),
    '生活': Color(0xFF9C27B0),
    '健康': Color(0xFFF44336),
    '运动': Color(0xFF009688),
    '社交': Color(0xFFE91E63),
    '家庭': Color(0xFF3F51B5),
    '差旅': Color(0xFFFFC107),
    '其他': Color(0xFF9E9E9E),
  };

  static const List<String> _categoryOrder = [
    '工作',
    '学习',
    '个人',
    '生活',
    '健康',
    '运动',
    '社交',
    '家庭',
    '差旅',
    '其他',
  ];
  
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

    _monthSchedules = await _getMonthSchedules(now);
    _rangeSchedules = await _getRangeSchedules(now);
    _weeklyCounts = _buildWeeklyCounts(now, _rangeSchedules);

    if (mounted) setState(() => _isLoading = false);
  }

  Future<List<Schedule>> _getMonthSchedules(DateTime now) async {
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final futures = List.generate(
      daysInMonth,
      (index) => _scheduleService.getSchedulesByDate(DateTime(now.year, now.month, index + 1)),
    );

    final results = await Future.wait(futures);
    return results.expand((list) => list).toList();
  }

  Future<List<Schedule>> _getRangeSchedules(DateTime now) async {
    final startOfWeek = _startOfWeek(now);
    final rangeStart = startOfWeek.subtract(const Duration(days: 7 * 4));
    final rangeEnd = startOfWeek.add(const Duration(days: 7 * 4 - 1));

    final days = rangeEnd.difference(rangeStart).inDays + 1;
    final futures = List.generate(
      days,
      (index) => _scheduleService.getSchedulesByDate(rangeStart.add(Duration(days: index))),
    );

    final results = await Future.wait(futures);
    return results.expand((list) => list).toList();
  }

  DateTime _startOfWeek(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: weekday - 1));
  }

  List<int> _buildWeeklyCounts(DateTime now, List<Schedule> schedules) {
    final startOfWeek = _startOfWeek(now);
    final rangeStart = startOfWeek.subtract(const Duration(days: 7 * 4));
    final counts = List<int>.filled(8, 0);

    for (final schedule in schedules) {
      if (schedule.scheduleDate.isEmpty) continue;
      final date = DateTime.parse(schedule.scheduleDate);
      final diffDays = date.difference(rangeStart).inDays;
      if (diffDays < 0 || diffDays >= 56) continue;
      final weekIndex = diffDays ~/ 7;
      if (weekIndex >= 0 && weekIndex < counts.length) {
        counts[weekIndex] += 1;
      }
    }

    return counts;
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
              _buildPieChartCard(),
              const SizedBox(height: 24),
              _buildWeeklyTrendCard(),
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

  Widget _buildWeeklyTrendCard() {
    final counts = _weeklyCounts.isEmpty ? List<int>.filled(8, 0) : _weeklyCounts;
    final maxValue = counts.isEmpty ? 0 : counts.reduce((a, b) => a > b ? a : b);
    final chartMax = (maxValue <= 5) ? 6.0 : (maxValue + 2).toDouble();

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
            '每周日程趋势（前四周到后三周）',
            style: TextStyle(fontSize: 18, height: 1.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (counts.every((value) => value == 0))
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '近几周暂无日程',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  BarChart(
                    BarChartData(
                      maxY: chartMax,
                      minY: 0,
                      barTouchData: BarTouchData(enabled: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (chartMax / 3).ceilToDouble(),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: const Color(0xFFEDEFF3),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: (chartMax / 3).ceilToDouble(),
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10, color: Colors.black45),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) => _buildWeekLabel(value.toInt()),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(counts.length, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: counts[index].toDouble(),
                              color: const Color(0xFF8EC5FF),
                              width: 14,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 28, right: 8, bottom: 24, top: 6),
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: chartMax,
                        titlesData: const FlTitlesData(show: false),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        lineTouchData: LineTouchData(enabled: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(counts.length, (index) {
                              return FlSpot(index.toDouble(), counts[index].toDouble());
                            }),
                            isCurved: true,
                            color: const Color(0xFF4F46E5),
                            barWidth: 2.5,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                                radius: 3,
                                color: const Color(0xFF4F46E5),
                                strokeWidth: 1,
                                strokeColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeekLabel(int index) {
    const labels = ['-4', '-3', '-2', '-1', '本周', '+1', '+2', '+3'];
    final text = index >= 0 && index < labels.length ? labels[index] : '';
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: Colors.black45),
      ),
    );
  }

  Widget _buildPieChartCard() {
    final counts = {for (final category in _categoryOrder) category: 0};
    for (final schedule in _monthSchedules) {
      final category = counts.containsKey(schedule.category) ? schedule.category : '其他';
      counts[category] = (counts[category] ?? 0) + 1;
    }

    final total = counts.values.fold<int>(0, (sum, value) => sum + value);

    final sections = counts.entries
        .where((e) => e.value > 0)
        .map((entry) {
          final percent = total == 0 ? 0.0 : entry.value / total * 100;
          return PieChartSectionData(
            color: _categoryColors[entry.key] ?? Colors.grey,
            value: entry.value.toDouble(),
            title: percent >= 8 ? '${percent.toStringAsFixed(0)}%' : '',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        })
        .toList();

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
            '本月日程分类分布',
            style: TextStyle(fontSize: 18, height: 1.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '本月暂无日程',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                final chartWidget = SizedBox(
                  width: 160,
                  height: 160,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 24,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                );

                final legendWidget = _buildLegend(counts, total);

                return isNarrow
                    ? Column(
                        children: [
                          chartWidget,
                          const SizedBox(height: 16),
                          legendWidget,
                        ],
                      )
                    : Row(
                        children: [
                          chartWidget,
                          const SizedBox(width: 16),
                          Expanded(child: legendWidget),
                        ],
                      );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLegend(Map<String, int> counts, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: counts.entries
              .where((e) => e.value > 0)
              .map((entry) => _buildLegendItem(entry.key, entry.value))
              .toList(),
        ),
        const SizedBox(height: 12),
        Text(
          '总计：$total',
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String category, int count) {
    final color = _categoryColors[category] ?? Colors.grey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$category $count',
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }
}
