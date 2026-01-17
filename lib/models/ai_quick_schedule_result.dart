import 'package:otti_calendar/models/schedule.dart';

class AiQuickScheduleResult {
  final Schedule schedule;
  final String message;

  const AiQuickScheduleResult({
    required this.schedule,
    required this.message,
  });
}
