import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:otti_calendar/models/ai_quick_schedule_result.dart';
import 'package:otti_calendar/models/schedule.dart';
import 'package:otti_calendar/services/auth_service.dart';

class AiQuickScheduleService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<Schedule> createQuickSchedule(String text) async {
    if (text.trim().isEmpty) {
      throw Exception('请输入内容');
    }
    final headers = await _getHeaders();
    final response = await _dio.post(
      '/api/ai/quick-schedule/create',
      data: {'text': text},
      options: Options(headers: headers),
    );

    if (response.statusCode == 200 && response.data['code'] == 200 && response.data['data'] != null) {
      final rawData = response.data['data'];
      if (rawData is Map<String, dynamic>) {
        final data = Map<String, dynamic>.from(rawData);
        final scheduleDate = data['scheduleDate']?.toString() ?? '';
        if (scheduleDate.isEmpty) {
          final startDateTime = data['startDateTime']?.toString() ?? '';
          final parsed = startDateTime.isNotEmpty ? DateTime.tryParse(startDateTime) : null;
          if (parsed != null) {
            data['scheduleDate'] = DateFormat('yyyy-MM-dd').format(parsed);
          }
        }
        return Schedule.fromJson(data);
      }
      return Schedule.fromJson(rawData);
    }

    final message = response.data is Map<String, dynamic> ? (response.data['message']?.toString() ?? '创建失败') : '创建失败';
    throw Exception(message);
  }

  Future<AiQuickScheduleResult> createQuickScheduleWithMessage(String text) async {
    if (text.trim().isEmpty) {
      throw Exception('请输入内容');
    }
    final headers = await _getHeaders();
    final response = await _dio.post(
      '/api/ai/quick-schedule/create',
      data: {'text': text},
      options: Options(headers: headers),
    );

    if (response.statusCode == 200 && response.data['code'] == 200 && response.data['data'] != null) {
      final rawData = response.data['data'];
      final String message = response.data is Map<String, dynamic>
          ? (response.data['message']?.toString() ?? '日程已添加')
          : '日程已添加';
      if (rawData is Map<String, dynamic>) {
        final data = Map<String, dynamic>.from(rawData);
        final scheduleDate = data['scheduleDate']?.toString() ?? '';
        if (scheduleDate.isEmpty) {
          final startDateTime = data['startDateTime']?.toString() ?? '';
          final parsed = startDateTime.isNotEmpty ? DateTime.tryParse(startDateTime) : null;
          if (parsed != null) {
            data['scheduleDate'] = DateFormat('yyyy-MM-dd').format(parsed);
          }
        }
        return AiQuickScheduleResult(schedule: Schedule.fromJson(data), message: message);
      }
      return AiQuickScheduleResult(schedule: Schedule.fromJson(rawData), message: message);
    }

    final message = response.data is Map<String, dynamic> ? (response.data['message']?.toString() ?? '创建失败') : '创建失败';
    throw Exception(message);
  }
}
