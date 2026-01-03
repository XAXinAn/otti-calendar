// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:otti_calendar/app.dart';

void main() async {
  // TEST SETUP: Initialize localization data, just like in main.dart
  await initializeDateFormatting('zh_CN');

  testWidgets('CalendarPage smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OttiApp());

    // The app can take a moment to fetch holidays and build the UI.
    // We might need to pump and settle to wait for all animations and async work to finish.
    await tester.pumpAndSettle();

    // Verify that the 'Today' button is present on the screen.
    expect(find.text('今'), findsOneWidget);

    // Verify that the Add Schedule button is present.
    expect(find.text('点击添加日程'), findsOneWidget);
  });
}
