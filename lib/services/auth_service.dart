import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otti_calendar/models/auth_response.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    // 方案 A: 修改为根地址，去掉末尾的 /api，由请求路径来补全
    baseUrl: 'http://192.168.43.227:8080',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  static const String _tokenKey = 'auth_token';

  // 登录
  Future<AuthResponse> login(String phone, String password) async {
    try {
      // 拼接结果: http://192.168.43.227:8080/api/auth/login
      final response = await _dio.post('/api/auth/login', data: {
        'phone': phone,
        'password': password,
      });

      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.code == 200 && authResponse.data != null) {
        await _saveToken(authResponse.data!.token);
      }

      return authResponse;
    } on DioException catch (e) {
      String message = '连接服务器失败';
      if (e.response != null && e.response!.data != null) {
        message = e.response!.data['message'] ?? '登录失败';
      }
      return AuthResponse(code: 500, message: message);
    }
  }

  // 注册
  Future<AuthResponse> register(String phone, String password) async {
    try {
      // 拼接结果: http://192.168.43.227:8080/api/auth/register
      final response = await _dio.post('/api/auth/register', data: {
        'phone': phone,
        'password': password,
      });

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      String message = '连接服务器失败';
      if (e.response != null && e.response!.data != null) {
        message = e.response!.data['message'] ?? '注册失败';
      }
      return AuthResponse(code: 500, message: message);
    }
  }

  // 保存 Token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // 获取 Token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // 登出
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
