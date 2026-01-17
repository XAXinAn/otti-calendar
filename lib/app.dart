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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      // 配置路由表以便退出登录跳转
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const CalendarPage(),
      },
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          return const CalendarPage();
        }
        return const LoginPage();
      },
    );
  }
}
