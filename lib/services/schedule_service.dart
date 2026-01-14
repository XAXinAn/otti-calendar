import 'package:dio/dio.dart';
import 'package:otti_calendar/models/schedule.dart';
import 'package:otti_calendar/services/auth_service.dart';

class ScheduleService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.43.227:8080',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  final AuthService _authService = AuthService();

  // 获取请求头（包含 Token）
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // 创建日程
  Future<bool> createSchedule(Schedule schedule) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.post(
        '/api/schedules',
        data: schedule.toJson(),
        options: Options(headers: headers),
      );
      return response.statusCode == 200 && response.data['code'] == 200;
    } catch (e) {
      return false;
    }
  }

  // 获取某天的日程
  Future<List<Schedule>> getSchedulesByDate(DateTime date) async {
    try {
      final headers = await _getHeaders();
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      final response = await _dio.get(
        '/api/schedules',
        queryParameters: {'date': dateStr},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> dataList = response.data['data'];
        return dataList.map((json) => Schedule.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 更新日程 (New)
  Future<bool> updateSchedule(Schedule schedule) async {
    if (schedule.scheduleId == null) return false;
    try {
      final headers = await _getHeaders();
      final response = await _dio.put(
        '/api/schedules/${schedule.scheduleId}',
        data: schedule.toJson(),
        options: Options(headers: headers),
      );
      return response.statusCode == 200 && response.data['code'] == 200;
    } catch (e) {
      return false;
    }
  }

  // 删除日程 (New)
  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.delete(
        '/api/schedules/$scheduleId',
        options: Options(headers: headers),
      );
      return response.statusCode == 200 && response.data['code'] == 200;
    } catch (e) {
      return false;
    }
  }
}
