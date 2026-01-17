import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class FloatingWindowService {
  static const String captureEvent = 'capture';

  Future<bool> ensurePermission() async {
    final granted = await FlutterOverlayWindow.isPermissionGranted();
    if (granted) return true;
    final result = await FlutterOverlayWindow.requestPermission();
    return result ?? false;
  }

  Future<void> showOverlay() async {
    final isActive = await FlutterOverlayWindow.isActive();
    if (isActive) return;
    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: 'Otti',
      overlayContent: 'Otti',
      height: 180,
      width: 280,
      alignment: OverlayAlignment.centerRight,
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.none,
    );
  }

  Future<void> closeOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
  }

  Stream<dynamic> get overlayEvents => FlutterOverlayWindow.overlayListener;

  Future<void> sendMessage(dynamic data) async {
    await FlutterOverlayWindow.shareData(data);
  }
}
