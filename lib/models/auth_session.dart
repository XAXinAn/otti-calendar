import 'package:otti_calendar/models/auth_response.dart';

class AuthSession {
  final String userId;
  final String token;
  final String refreshToken;
  final int expiresIn;
  final UserInfo? userInfo;

  const AuthSession({
    required this.userId,
    required this.token,
    required this.refreshToken,
    required this.expiresIn,
    this.userInfo,
  });

  factory AuthSession.fromAuthData(AuthData data) {
    return AuthSession(
      userId: data.userId,
      token: data.token,
      refreshToken: data.refreshToken,
      expiresIn: data.expiresIn,
      userInfo: data.userInfo,
    );
  }
}
