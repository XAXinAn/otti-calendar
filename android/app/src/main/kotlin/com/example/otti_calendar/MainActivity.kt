package com.example.otti_calendar

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    companion object {
        private const val OCR_CHANNEL = "paddle_ocr"
    }

    // **优化点**: 使用独立线程池处理耗时的 OCR 任务
    private val ocrExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val ocrHandler by lazy { PaddleOcrHandler(this) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // **优化点**: 在引擎配置时异步预热 OCR
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
    }

    override fun onDestroy() {
        super.onDestroy()
        // 释放资源
        ocrExecutor.shutdown()
        ocrHandler.release()
    }
}
