import 'package:intl/intl.dart';

class Schedule {
  final String? scheduleId;
  final String title;
  final String scheduleDate;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String category;
  final bool isAllDay;
  final bool isAiGenerated;
  final bool isImportant; // 新增重要标志

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
    this.isImportant = false, // 默认不重要
  });

  Map<String, dynamic> toJson() {
    return {
      'scheduleId': scheduleId,
      'title': title,
      'scheduleDate': scheduleDate,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'category': category,
      'isAllDay': isAllDay,
      'isAiGenerated': isAiGenerated,
      'isImportant': isImportant,
    };
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      scheduleId: json['scheduleId']?.toString(),
      title: json['title'] ?? '',
      scheduleDate: json['scheduleDate'] ?? '',
      startTime: json['startTime'],
      endTime: json['endTime'],
      location: json['location'],
      category: json['category'] ?? '其他',
      isAllDay: json['isAllDay'] ?? false,
      isAiGenerated: json['isAiGenerated'] ?? false,
      isImportant: json['isImportant'] ?? false,
    );
  }
}
