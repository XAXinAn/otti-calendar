import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:otti_calendar/app.dart';

void main() async {
  // Ensure that Flutter is initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the locale data for Chinese.
  await initializeDateFormatting('zh_CN');

  runApp(const OttiApp());
}
