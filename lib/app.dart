import 'package:flutter/material.dart';
import 'package:otti_calendar/features/calendar/calendar_page.dart';
import 'package:otti_calendar/features/profile/login_page.dart';
import 'package:otti_calendar/services/auth_service.dart';

class OttiApp extends StatelessWidget {
  const OttiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OttiCalendar',
      theme: ThemeData(
        // Disable the ripple effect globally
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      home: const AuthCheckScreen(),
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _authService.getToken(),
      builder: (context, snapshot) {
        // 当连接状态为等待时，显示加载中（这里可以放闪屏页 UI）
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 如果 snapshot 中有 Token，说明已登录，进入日历主页
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          return const CalendarPage();
        }

        // 否则进入登录页面
        return const LoginPage();
      },
    );
  }
}
