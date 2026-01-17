package com.example.otti_calendar

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Handler
import android.os.HandlerThread
import android.provider.Settings
import android.util.DisplayMetrics
import android.util.Log
import androidx.core.content.ContextCompat
import com.example.otti_calendar.floating.FloatingOcrService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    companion object {
        private const val OCR_CHANNEL = "paddle_ocr"
        private const val SCREEN_CAPTURE_CHANNEL = "screen_capture"
        private const val FLOATING_CHANNEL = "floating_ocr"
        private const val FLOATING_EVENTS = "floating_ocr_events"
        private const val SCREEN_CAPTURE_REQUEST_CODE = 1001
        private const val REQ_MEDIA_PROJECTION = 1002
        private const val TAG = "MainActivity"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val ACCESS_TOKEN_KEY = "flutter.auth_token"
    }

    // **优化点**: 使用独立线程池处理耗时的 OCR 任务
    private val ocrExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val ocrHandler by lazy { PaddleOcrHandler(this) }

    private val mediaProjectionManager by lazy {
        getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
    }
    private var mediaProjection: MediaProjection? = null
    private var pendingResult: MethodChannel.Result? = null
    private var pendingAction: CaptureAction? = null
    private var captureThread: HandlerThread? = null
    private var captureHandler: Handler? = null
    private var serviceConnection: ServiceConnection? = null
    private var pendingProjectionResultCode: Int = 0
    private var pendingProjectionData: Intent? = null
    private var pendingFloatingProjectionResult: MethodChannel.Result? = null

    private enum class CaptureAction { REQUEST_ONLY, REQUEST_AND_CAPTURE }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ocrExecutor.execute { ocrHandler.warmUp() }

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // 设置 MethodChannel 用于直接识别
        MethodChannel(messenger, OCR_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "recognize") {
                val imagePath: String? = call.argument("imagePath")
                if (imagePath == null) {
                    result.error("INVALID_ARGS", "imagePath argument is missing", null)
                    return@setMethodCallHandler
                }
                
                ocrExecutor.execute {
                    try {
                        val text = ocrHandler.recognize(imagePath)
                        // 将结果切回主线程返回给 Flutter
                        runOnUiThread { result.success(text) }
                    } catch (e: Exception) {
                        runOnUiThread {
                            result.error("OCR_FAILED", e.message, e.stackTraceToString())
                        }
                    }
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(messenger, SCREEN_CAPTURE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> handleRequestPermission(result)
                "requestAndCapture" -> handleRequestAndCapture(result)
                else -> result.notImplemented()
            }
        }

        // 悬浮窗 OCR MethodChannel
        MethodChannel(messenger, FLOATING_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startFloatingOcr" -> {
                    Log.d(TAG, "startFloatingOcr invoked")
                    handleStartFloating(result)
                }
                "stopFloatingOcr" -> {
                    Log.d(TAG, "stopFloatingOcr invoked")
                    stopService(Intent(this, FloatingOcrService::class.java))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 悬浮窗 OCR EventChannel
        EventChannel(messenger, FLOATING_EVENTS).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                FloatingOcrBridge.eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                FloatingOcrBridge.eventSink = null
            }
        })
    }

    override fun onDestroy() {
        super.onDestroy()
        // 释放资源
        ocrExecutor.shutdown()
        ocrHandler.release()
        captureThread?.quitSafely()
        mediaProjection?.stop()
        serviceConnection?.let { unbindService(it) }
        FloatingOcrBridge.eventSink = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        // 处理悬浮窗录屏权限请求
        if (requestCode == REQ_MEDIA_PROJECTION) {
            val pending = pendingFloatingProjectionResult
            pendingFloatingProjectionResult = null

            if (resultCode == Activity.RESULT_OK && data != null) {
                Log.d(TAG, "projection granted, starting floating service")
                
                // 从 SharedPreferences 获取 accessToken
                val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val accessToken = prefs.getString(ACCESS_TOKEN_KEY, null)
                Log.d(TAG, "accessToken from prefs: ${if (accessToken.isNullOrEmpty()) "null" else "***"}")
                
                val intent = Intent(this, FloatingOcrService::class.java).apply {
                    putExtra(FloatingOcrService.EXTRA_RESULT_CODE, resultCode)
                    putExtra(FloatingOcrService.EXTRA_RESULT_DATA, data)
                    putExtra(FloatingOcrService.EXTRA_ACCESS_TOKEN, accessToken)
                }
                ContextCompat.startForegroundService(this, intent)
                pending?.success(true)
            } else {
                Log.w(TAG, "projection denied")
                pending?.error("PROJECTION_DENIED", "用户拒绝录屏权限", null)
            }
            return
        }

        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != SCREEN_CAPTURE_REQUEST_CODE) return

        val result = pendingResult
        val action = pendingAction
        pendingResult = null
        pendingAction = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            result?.error("CAPTURE_DENIED", "用户未授予截屏权限", null)
            return
        }

        // 保存投影参数，等服务启动后再获取 MediaProjection
        pendingProjectionResultCode = resultCode
        pendingProjectionData = data

        serviceConnection = MediaProjectionForegroundService.bindAndStart(this) {
            // 服务已启动，现在可以安全获取 MediaProjection
            mediaProjection = mediaProjectionManager.getMediaProjection(
                pendingProjectionResultCode, 
                pendingProjectionData!!
            )
            if (action == CaptureAction.REQUEST_ONLY) {
                result?.success(true)
                return@bindAndStart
            }
            if (action == CaptureAction.REQUEST_AND_CAPTURE) {
                if (result != null) {
                    captureScreen(result)
                }
            }
        }
    }

    private fun handleRequestPermission(result: MethodChannel.Result) {
        if (mediaProjection != null) {
            result.success(true)
            return
        }
        pendingResult = result
        pendingAction = CaptureAction.REQUEST_ONLY
        val intent = mediaProjectionManager.createScreenCaptureIntent()
        startActivityForResult(intent, SCREEN_CAPTURE_REQUEST_CODE)
    }

    private fun handleStartFloating(result: MethodChannel.Result) {
        if (pendingFloatingProjectionResult != null) {
            Log.w(TAG, "startFloating: pending projection request in flight")
            result.error("BUSY", "正在申请录屏权限，请稍后重试", null)
            return
        }

        if (!Settings.canDrawOverlays(this)) {
            Log.w(TAG, "startFloating: overlay permission missing")
            result.error("OVERLAY_PERMISSION_REQUIRED", "需要悬浮窗权限，请先授予", null)
            return
        }

        val mgr = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as? MediaProjectionManager
        if (mgr == null) {
            Log.e(TAG, "startFloating: MediaProjectionManager unavailable")
            result.error("UNAVAILABLE", "媒体投影服务不可用", null)
            return
        }

        pendingFloatingProjectionResult = result
        Log.d(TAG, "startFloating: request projection permission")
        startActivityForResult(mgr.createScreenCaptureIntent(), REQ_MEDIA_PROJECTION)
    }

    private fun handleRequestAndCapture(result: MethodChannel.Result) {
        if (mediaProjection == null) {
            pendingResult = result
            pendingAction = CaptureAction.REQUEST_AND_CAPTURE
            val intent = mediaProjectionManager.createScreenCaptureIntent()
            startActivityForResult(intent, SCREEN_CAPTURE_REQUEST_CODE)
            return
        }
        captureScreen(result)
    }

    private fun captureScreen(result: MethodChannel.Result) {
        val projection = mediaProjection
        if (projection == null) {
            result.error("CAPTURE_FAILED", "MediaProjection 未就绪", null)
            return
        }

        if (captureThread == null) {
            captureThread = HandlerThread("screen_capture")
            captureThread?.start()
            captureHandler = Handler(captureThread!!.looper)
        }

        val metrics = DisplayMetrics()
        windowManager.defaultDisplay.getRealMetrics(metrics)
        val width = metrics.widthPixels
        val height = metrics.heightPixels
        val density = metrics.densityDpi

        val imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
        val virtualDisplay: VirtualDisplay? = projection.createVirtualDisplay(
            "OttiScreenCapture",
            width,
            height,
            density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader.surface,
            null,
            captureHandler
        )

        imageReader.setOnImageAvailableListener({ reader ->
            var image = reader.acquireLatestImage()
            if (image == null) return@setOnImageAvailableListener
            try {
                val planes = image.planes
                val buffer = planes[0].buffer
                val pixelStride = planes[0].pixelStride
                val rowStride = planes[0].rowStride
                val rowPadding = rowStride - pixelStride * width

                val bitmap = Bitmap.createBitmap(
                    width + rowPadding / pixelStride,
                    height,
                    Bitmap.Config.ARGB_8888
                )
                bitmap.copyPixelsFromBuffer(buffer)

                val cropped = Bitmap.createBitmap(bitmap, 0, 0, width, height)
                val file = File(cacheDir, "screen_${System.currentTimeMillis()}.png")
                FileOutputStream(file).use { out ->
                    cropped.compress(Bitmap.CompressFormat.PNG, 100, out)
                }

                runOnUiThread { result.success(file.absolutePath) }
            } catch (e: Exception) {
                runOnUiThread { result.error("CAPTURE_FAILED", e.message, e.stackTraceToString()) }
            } finally {
                image.close()
                reader.close()
                virtualDisplay?.release()
            }
        }, captureHandler)
    }
}
