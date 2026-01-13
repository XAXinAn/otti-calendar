class AuthResponse {
  final int code;
  final String message;
  final AuthData? data;

  AuthResponse({required this.code, required this.message, this.data});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      code: json['code'] ?? 500,
      message: json['message'] ?? '未知错误',
      data: json['data'] != null ? AuthData.fromJson(json['data']) : null,
    );
  }
}

class AuthData {
  final String userId;
  final String token;
  final String refreshToken;
  final int expiresIn;
  final UserInfo? userInfo; // 改为可选

  AuthData({
    required this.userId,
    required this.token,
    required this.refreshToken,
    required this.expiresIn,
    this.userInfo,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      userId: json['userId']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      expiresIn: json['expiresIn'] ?? 0,
      userInfo: json['userInfo'] != null ? UserInfo.fromJson(json['userInfo']) : null,
    );
  }
}

class UserInfo {
  final String userId;
  final String username;
  final String phone;
  final String? avatar;
  final String role;

  UserInfo({
    required this.userId,
    required this.username,
    required this.phone,
    this.avatar,
    required this.role,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? '未命名',
      phone: json['phone']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      role: json['role']?.toString() ?? 'user',
    );
  }
}
