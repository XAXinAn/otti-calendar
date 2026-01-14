import 'package:flutter/material.dart';
import 'package:otti_calendar/features/schedule/pages/schedule_detail_page.dart';
import 'package:otti_calendar/models/schedule.dart';

class ScheduleListView extends StatelessWidget {
  final List<Map<String, dynamic>> schedules;
  // 新增回调，用于通知父组件发生了什么操作
  final Function(String)? onActionComplete;

  const ScheduleListView({super.key, required this.schedules, this.onActionComplete});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final scheduleMap = schedules[index];
        final schedule = Schedule.fromJson(scheduleMap);
        
        const categoryStyles = {
          '工作': {'color': Colors.blue, 'icon': Icons.work_outline},
          '学习': {'color': Colors.green, 'icon': Icons.school_outlined},
          '个人': {'color': Colors.orange, 'icon': Icons.person_outline},
          '生活': {'color': Colors.purple, 'icon': Icons.home_outlined},
          '健康': {'color': Colors.red, 'icon': Icons.favorite_border},
          '运动': {'color': Colors.teal, 'icon': Icons.directions_run},
          '社交': {'color': Colors.pink, 'icon': Icons.chat_bubble_outline},
          '家庭': {'color': Colors.indigo, 'icon': Icons.family_restroom},
          '差旅': {'color': Colors.amber, 'icon': Icons.flight_takeoff},
          '其他': {'color': Colors.grey, 'icon': Icons.more_horiz},
        };

        final style = categoryStyles[schedule.category] ?? categoryStyles['其他']!;
        final String displayTime = schedule.isAllDay ? '全天' : (schedule.startTime ?? '--:--');

        return InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScheduleDetailPage(schedule: schedule),
              ),
            );
            
            // 如果有返回值，通过回调通知主页
            if (result != null && onActionComplete != null) {
              onActionComplete!(result as String);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    displayTime, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: (style['color'] as Color).withOpacity(0.3), width: 3))
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (style['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                schedule.category, 
                                style: TextStyle(color: style['color'] as Color, fontWeight: FontWeight.bold, fontSize: 12)
                              ),
                              const SizedBox(width: 4),
                              Icon(style['icon'] as IconData, size: 14, color: style['color'] as Color),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          schedule.title, 
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Colors.black)
                        ),
                        if (schedule.location != null && schedule.location!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                schedule.location!, 
                                style: const TextStyle(color: Colors.grey, fontSize: 13)
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
