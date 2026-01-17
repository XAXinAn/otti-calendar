import 'package:flutter/services.dart';

class OcrService {
  const OcrService();

  // 与 MainActivity 中定义的 Channel 名称保持一致
  static const MethodChannel _channel = MethodChannel('paddle_ocr');
  static const MethodChannel _floatingChannel = MethodChannel('floating_ocr');
  static const EventChannel _floatingEvents = EventChannel('floating_ocr_events');

  /// 调用原生代码识别图片中的文字。
  /// [imagePath] 是图片在设备上的绝对路径。
  Future<String> recognize(String imagePath) async {
    try {
      final String? text = await _channel.invokeMethod<String>(
        'recognize',
        {'imagePath': imagePath},
      );
      return text ?? '';
    } on PlatformException catch (e) {
      // 可以根据需要将错误信息暴露给上层 UI
      throw Exception('OCR 识别失败: ${e.message}');
    }
  }

  /// 启动悬浮窗 OCR 服务
  /// 会显示一个悬浮球，点击后自动截屏、OCR识别，并调用 AI 接口创建日程
  Future<bool> startFloatingOcr() async {
    try {
      final result = await _floatingChannel.invokeMethod<bool>('startFloatingOcr');
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('启动悬浮窗失败: ${e.message}');
    }
  }

  /// 停止悬浮窗 OCR 服务
  Future<bool> stopFloatingOcr() async {
    try {
      final result = await _floatingChannel.invokeMethod<bool>('stopFloatingOcr');
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('停止悬浮窗失败: ${e.message}');
    }
  }

  /// 监听悬浮窗 OCR 服务的事件
  /// 事件格式: { 'status': 'ready'|'capturing'|'success'|'error', 'message': String?, 'text': String? }
  Stream<Map<String, dynamic>> floatingEvents() {
    return _floatingEvents.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return Map<String, dynamic>.from(event);
      }
      return <String, dynamic>{'status': 'error', 'message': 'Unknown event format'};
    });
  }
}
