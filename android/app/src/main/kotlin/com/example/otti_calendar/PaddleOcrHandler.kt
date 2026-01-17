
package com.example.otti_calendar

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import com.equationl.paddleocr4android.OCR
import com.equationl.paddleocr4android.OcrConfig
import com.equationl.paddleocr4android.bean.OcrResult
import java.io.File

/**
 * 封装 PaddleOCR 引擎，提供初始化、识别、预热和释放资源的功能。
 */
class PaddleOcrHandler(private val context: Context) {
    @Volatile
    private var ocr: OCR? = null

    /**
     * 同步初始化 OCR 引擎，确保模型只加载一次。
     * 应用了性能优化指南中的推荐配置。
     */
    @Synchronized
    @Throws(Exception::class)
    private fun ensureInited() {
        if (ocr != null) return

        // 根据 OCR 性能优化指南配置引擎
        val config = OcrConfig().apply {
            modelPath = "models"
            clsModelFilename = "cls.nb"
            detModelFilename = "det.nb"
            recModelFilename = "rec.nb"
            labelPath = "models/ppocr_keys_v1.txt"
            isRunDet = true
            isRunCls = false // **优化点**: 如果不处理旋转文字，关闭可提速
            isRunRec = true
            cpuThreadNum = 4 // **优化点**: 推荐线程数
        }

        val paddleOcr = OCR(context)
        // 使用同步方法加载模型
        val initOk = when (val r = paddleOcr.initModelSync(config)) {
            is Result<*> -> {
                if (r.isFailure) throw (r.exceptionOrNull() ?: IllegalStateException("initModelSync failed"))
                (r.getOrNull() as? Boolean) == true
            }
            is Boolean -> r
            else -> false
        }
        if (!initOk) throw IllegalStateException("PaddleOCR 模型初始化失败")

        ocr = paddleOcr
    }

    /**
     * 从文件路径识别文本。
     * @param imagePath 图片的绝对路径。
     * @return 识别出的字符串。
     */
    @Throws(Exception::class)
    fun recognize(imagePath: String): String {
        ensureInited()
        val bitmap = decodeScaledBitmap(File(imagePath)) ?: throw IllegalStateException("无法读取或解码图片")
        return runOcr(bitmap)
    }

    /**
     * 从 Bitmap 对象识别文本。
     * @param bitmap 内存中的位图对象。
     * @return 识别出的字符串。
     */
    @Throws(Exception::class)
    fun recognize(bitmap: Bitmap): String {
        ensureInited()
        // **优化点**：悬浮窗场景传入的 Bitmap 可能需要先缩放
        return runOcr(bitmap)
    }

    private fun runOcr(bitmap: Bitmap): String {
        val tOcrStart = android.os.SystemClock.uptimeMillis()
        android.util.Log.i("PaddleOcrHandler", "⏱️ [OCR] runOcr START, bitmap=${bitmap.width}x${bitmap.height}")
        
        val result: OcrResult = when (val r = ocr?.runSync(bitmap)) {
            is Result<*> -> (r.getOrNull() as? OcrResult) ?: throw (r.exceptionOrNull() ?: IllegalStateException("OCR 识别失败"))
            is OcrResult -> r
            else -> throw IllegalStateException("OCR 引擎未初始化")
        }
        
        val tOcrEnd = android.os.SystemClock.uptimeMillis()
        android.util.Log.i("PaddleOcrHandler", "⏱️ [OCR] runOcr DONE, ocr_engine_time=${tOcrEnd - tOcrStart}ms, text_len=${result.simpleText.length}")
        return result.simpleText
    }

    /**
     * **优化点**: 对图片进行缩放，避免将高分辨率大图送入引擎。
     * 长边建议缩放至 960px 或 1280px。
     */
    private fun decodeScaledBitmap(imageFile: File, maxDim: Int = 1280): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(imageFile.absolutePath, bounds)
        var sample = 1
        while (bounds.outWidth / sample > maxDim || bounds.outHeight / sample > maxDim) {
            sample *= 2
        }
        val opts = BitmapFactory.Options().apply { inSampleSize = sample }
        return BitmapFactory.decodeFile(imageFile.absolutePath, opts)
    }

    /**
     * **优化点**: 预热模型，在后台线程调用以避免首次识别卡顿。
     */
    fun warmUp() {
        try {
            ensureInited()
        } catch (_: Exception) {
            // 预热失败是可接受的，不应崩溃
        }
    }
    
    /**
     * 释放 OCR 引擎占用的资源。
     */
    fun release() {
        ocr?.releaseModel()
        ocr = null
    }
}
