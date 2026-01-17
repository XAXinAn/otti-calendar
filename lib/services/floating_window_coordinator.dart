import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:otti_calendar/models/schedule.dart';
import 'package:otti_calendar/services/ocr_service.dart';

/// 悬浮窗协调器 - 使用原生 Android 悬浮窗服务
class FloatingWindowCoordinator {
  FloatingWindowCoordinator._();

  static final FloatingWindowCoordinator instance = FloatingWindowCoordinator._();

  final OcrService _ocrService = const OcrService();

  bool _isListening = false;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  Future<void> Function(Schedule schedule)? _onScheduleCreated;

  void initialize({Future<void> Function(Schedule schedule)? onScheduleCreated}) {
    _onScheduleCreated = onScheduleCreated;
    if (_isListening) return;
    _isListening = true;
    
    // 监听原生悬浮窗事件
    _subscription = _ocrService.floatingEvents().listen((event) async {
      debugPrint('收到悬浮窗事件: $event');
      final status = event['status'] as String?;
      final message = event['message'] as String?;
      final text = event['text'] as String?;
      
      switch (status) {
        case 'ready':
          debugPrint('悬浮窗已就绪');
          break;
        case 'capturing':
          debugPrint('正在截屏...');
          break;
        case 'success':
          debugPrint('OCR 成功: $text');
          // 原生层已经完成 AI 调用，这里不需要额外处理
          break;
        case 'error':
          debugPrint('悬浮窗错误: $message');
          break;
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
  }

  /// 启用悬浮窗功能
  /// 会检查并请求悬浮窗权限，然后启动原生悬浮窗服务
  Future<bool> enableFloatingWindow(BuildContext context) async {
    // 检查悬浮窗权限
    final overlayStatus = await Permission.systemAlertWindow.status;
    if (!overlayStatus.isGranted) {
      final result = await Permission.systemAlertWindow.request();
      if (!result.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('需要悬浮窗权限才能使用此功能')),
          );
        }
        return false;
      }
    }

    try {
      // 启动原生悬浮窗服务（会同时请求录屏权限）
      final success = await _ocrService.startFloatingOcr();
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('启动悬浮窗失败')),
        );
      }
      return success;
    } catch (e) {
      debugPrint('启动悬浮窗失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('启动悬浮窗失败: $e')),
        );
      }
      return false;
    }
  }

  /// 停止悬浮窗服务
  Future<void> disableFloatingWindow() async {
    try {
      await _ocrService.stopFloatingOcr();
    } catch (e) {
      debugPrint('停止悬浮窗失败: $e');
    }
  }
}
