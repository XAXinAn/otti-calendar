import 'package:flutter/services.dart';

class OcrService {
  const OcrService();

  // 与 MainActivity 中定义的 Channel 名称保持一致
  static const MethodChannel _channel = MethodChannel('paddle_ocr');

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
}
