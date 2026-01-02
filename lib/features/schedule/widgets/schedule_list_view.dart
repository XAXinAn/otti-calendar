import 'package:flutter/material.dart';

class ScheduleListView extends StatelessWidget {
  final List<Map<String, dynamic>> schedules;

  const ScheduleListView({super.key, required this.schedules});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        const categoryStyles = {
          '购物': {'color': Colors.orange, 'icon': Icons.shopping_basket},
          '工作': {'color': Colors.blue, 'icon': Icons.work},
          '学习': {'color': Colors.green, 'icon': Icons.school},
          '生活': {'color': Colors.purple, 'icon': Icons.home},
        };
        final style = categoryStyles[schedule['category']] ?? {'color': Colors.grey, 'icon': Icons.event};

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(schedule['time'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(left: 16),
                  decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey.shade300, width: 2))),
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
                            Text(schedule['category'] as String, style: TextStyle(color: style['color'] as Color, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            Icon(style['icon'] as IconData, size: 16, color: style['color'] as Color),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(schedule['title'] as String, style: const TextStyle(fontSize: 16)),
                      if (schedule['location'] != null && (schedule['location'] as String).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(schedule['location'] as String, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
