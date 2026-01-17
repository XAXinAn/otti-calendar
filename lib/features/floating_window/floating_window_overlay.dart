import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class FloatingWindowOverlayApp extends StatefulWidget {
  const FloatingWindowOverlayApp({super.key});

  @override
  State<FloatingWindowOverlayApp> createState() => _FloatingWindowOverlayAppState();
}

class _FloatingWindowOverlayAppState extends State<FloatingWindowOverlayApp> {
  String? _message;
  Timer? _timer;
  bool _isProcessing = false;

  static const MethodChannel _captureChannel = MethodChannel('screen_capture');
  static const MethodChannel _ocrChannel = MethodChannel('paddle_ocr');

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen(_handleMessage);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleMessage(dynamic data) {
    if (data is Map && data['message'] != null) {
      _showMessage(data['message']?.toString() ?? '');
    }
  }

  void _showMessage(String msg) {
    setState(() => _message = msg);
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _message = null);
    });
  }

  Future<void> _handleTap() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    _showMessage('正在截屏…');

    try {
      final imagePath = await _captureChannel.invokeMethod<String>('requestAndCapture');
      if (imagePath == null || imagePath.trim().isEmpty) {
        _showMessage('截屏失败');
        setState(() => _isProcessing = false);
        return;
      }

      _showMessage('正在识别…');
      final text = await _ocrChannel.invokeMethod<String>('recognize', {'imagePath': imagePath});
      if (text == null || text.trim().isEmpty) {
        _showMessage('未识别到文字');
        setState(() => _isProcessing = false);
        return;
      }

      _showMessage('识别成功，请返回应用查看');
      // 发送识别结果给主应用
      await FlutterOverlayWindow.shareData({'type': 'ocr_result', 'text': text.trim()});
    } catch (e) {
      _showMessage('出错: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // 状态消息气泡
            if (_message != null)
              Positioned(
                left: 8,
                top: 8,
                right: 72,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _message!,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            // 悬浮按钮
            Positioned(
              right: 8,
              top: 56,
              child: GestureDetector(
                onTap: _handleTap,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _isProcessing ? Colors.grey.shade300 : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Center(
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF007AFF)),
                          )
                        : const Icon(Icons.auto_awesome, color: Color(0xFF007AFF), size: 28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
