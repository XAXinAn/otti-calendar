import 'package:flutter/material.dart';
import 'package:otti_calendar/features/calendar/calendar_page.dart';

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
      home: const CalendarPage(),
    );
  }
}
