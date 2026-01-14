import 'package:intl/intl.dart';

class Schedule {
  final String? scheduleId; // 改为后端要求的 scheduleId
  final String title;
  final String scheduleDate;
  final String? startTime;    // 后端说可能为 null
  final String? endTime;
  final String? location;
  final String category;
  final bool isAllDay;
  final bool isAiGenerated;

  Schedule({
    this.scheduleId,
    required this.title,
    required this.scheduleDate,
    this.startTime,
    this.endTime,
    this.location,
    required this.category,
    this.isAllDay = false,
    this.isAiGenerated = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'scheduleId': scheduleId, // 适配后端
      'title': title,
      'scheduleDate': scheduleDate,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'category': category,
      'isAllDay': isAllDay,
      'isAiGenerated': isAiGenerated,
    };
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      scheduleId: json['scheduleId']?.toString(), // 适配后端
      title: json['title'] ?? '',
      scheduleDate: json['scheduleDate'] ?? '',
      startTime: json['startTime'],
      endTime: json['endTime'],
      location: json['location'],
      category: json['category'] ?? '其他',
      isAllDay: json['isAllDay'] ?? false,
      isAiGenerated: json['isAiGenerated'] ?? false,
    );
  }
}
