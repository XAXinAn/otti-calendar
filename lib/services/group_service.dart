import 'package:dio/dio.dart';
import 'package:otti_calendar/models/group.dart';
import 'package:otti_calendar/models/group_member.dart';
import 'package:otti_calendar/services/auth_service.dart';

class GroupService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.43.227:8080',
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

  // 创建群组
  Future<Map<String, dynamic>> createGroup(String name, String? description) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.post(
        '/api/groups',
        data: {
          'name': name,
          'description': description,
        },
        options: Options(headers: headers),
      );
      return response.data;
    } catch (e) {
      return {'code': 500, 'message': '创建失败'};
    }
  }

  // 加入群组
  Future<Map<String, dynamic>> joinGroup(String inviteCode) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.post(
        '/api/groups/join',
        data: {'inviteCode': inviteCode},
        options: Options(headers: headers),
      );
      return response.data;
    } catch (e) {
      return {'code': 500, 'message': '加入失败'};
    }
  }

  // 获取我创建的群组
  Future<List<Group>> getCreatedGroups() async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.get('/api/groups/created', options: Options(headers: headers));
      if (response.data['code'] == 200) {
        final List<dynamic> list = response.data['data'];
        return list.map((json) => Group.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 获取我加入的群组
  Future<List<Group>> getJoinedGroups() async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.get('/api/groups/joined', options: Options(headers: headers));
      if (response.data['code'] == 200) {
        final List<dynamic> list = response.data['data'];
        return list.map((json) => Group.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 获取群组成员列表 (New)
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.get('/api/groups/$groupId/members', options: Options(headers: headers));
      if (response.data['code'] == 200) {
        final List<dynamic> list = response.data['data'];
        return list.map((json) => GroupMember.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
