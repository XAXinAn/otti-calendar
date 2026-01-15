import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otti_calendar/models/auth_response.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.43.227:8080',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_info';

  // 1. 登录
  Future<AuthResponse> login(String phone, String password) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'phone': phone,
        'password': password,
      });
      final authResponse = AuthResponse.fromJson(response.data);
      if (authResponse.code == 200 && authResponse.data != null) {
        await _saveToken(authResponse.data!.token);
        if (authResponse.data!.userInfo != null) {
          await saveUserInfo(authResponse.data!.userInfo!);
        }
      }
      return authResponse;
    } on DioException catch (e) {
      return AuthResponse(code: 500, message: '登录失败');
    }
  }

  // 2. 更新个人信息 (New)
  Future<bool> updateProfile(UserInfo userInfo) async {
    try {
      final token = await getToken();
      final response = await _dio.put(
        '/api/auth/profile',
        data: userInfo.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['code'] == 200) {
        await saveUserInfo(userInfo); // 成功后同步更新本地缓存
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // 注册
  Future<AuthResponse> register(String phone, String password) async {
    try {
      final response = await _dio.post('/api/auth/register', data: {
        'phone': phone,
        'password': password,
      });
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      return AuthResponse(code: 500, message: '注册失败');
    }
  }

  // 存储管理
  Future<void> saveUserInfo(UserInfo userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userInfo.toJson()));
  }

  Future<UserInfo?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    return userJson != null ? UserInfo.fromJson(jsonDecode(userJson)) : null;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
