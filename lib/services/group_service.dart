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

  // 1. 创建群组
  Future<Map<String, dynamic>> createGroup(String name, String? description) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.post('/api/groups', data: {'name': name, 'description': description}, options: Options(headers: headers));
      return response.data;
    } catch (e) {
      return {'code': 500, 'message': '创建失败'};
    }
  }

  // 2. 加入群组
  Future<Map<String, dynamic>> joinGroup(String inviteCode) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.post('/api/groups/join', data: {'inviteCode': inviteCode}, options: Options(headers: headers));
      return response.data;
    } catch (e) {
      return {'code': 500, 'message': '加入失败'};
    }
  }

  // 3. 获取列表
  Future<List<Group>> _getGroups(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.get(endpoint, options: Options(headers: headers));
      if (response.data['code'] == 200) {
        final List<dynamic> list = response.data['data'];
        return list.map((json) => Group.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Group>> getCreatedGroups() => _getGroups('/api/groups/created');
  Future<List<Group>> getJoinedGroups() => _getGroups('/api/groups/joined');

  // 4. 获取成员
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

  // 5. 成员管理
  Future<bool> removeMembers(String groupId, List<String> userIds) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.delete('/api/groups/$groupId/members', data: {'userIds': userIds}, options: Options(headers: headers));
      return response.data['code'] == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateMemberRole(String groupId, String userId, String newRole) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.put('/api/groups/$groupId/members/$userId/role', data: {'role': newRole}, options: Options(headers: headers));
      return response.data['code'] == 200;
    } catch (e) {
      return false;
    }
  }

  // 6. 解散群组 (New)
  Future<bool> disbandGroup(String groupId) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.delete('/api/groups/$groupId', options: Options(headers: headers));
      return response.data['code'] == 200;
    } catch (e) {
      return false;
    }
  }

  // 7. 退出群组 (New)
  Future<bool> quitGroup(String groupId) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.post('/api/groups/$groupId/quit', options: Options(headers: headers));
      return response.data['code'] == 200;
    } catch (e) {
      return false;
    }
  }
}
