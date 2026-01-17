import 'package:flutter/services.dart';

class ScreenCaptureService {
  static const MethodChannel _channel = MethodChannel('screen_capture');

  Future<bool> requestPermission() async {
    final result = await _channel.invokeMethod<bool>('requestPermission');
    return result ?? false;
  }

  Future<String> requestAndCapture() async {
    final path = await _channel.invokeMethod<String>('requestAndCapture');
    return path ?? '';
  }
}
