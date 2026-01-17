package com.example.otti_calendar.floating

import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageButton
import android.widget.Toast
import androidx.core.app.NotificationCompat
import com.example.otti_calendar.FloatingOcrBridge
import com.example.otti_calendar.MainActivity
import com.example.otti_calendar.PaddleOcrHandler
import android.util.Log

/**
 * 前台悬浮窗服务：点击悬浮球 -> 申请 MediaProjection 截屏 -> OCR -> 在悬浮弹窗中显示AI结果。
 */
class FloatingOcrService : Service() {

    companion object {
        const val EXTRA_RESULT_CODE = "extra_result_code"
        const val EXTRA_RESULT_DATA = "extra_result_data"
        const val EXTRA_ACCESS_TOKEN = "extra_access_token"
        const val EXTRA_SESSION_ID = "extra_session_id"
        private const val NOTIFICATION_CHANNEL_ID = "floating_ocr_channel"
        private const val NOTIFICATION_ID = 1001
        private const val TAG = "FloatingOcrService"
    }

    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var overlayParams: WindowManager.LayoutParams? = null
    private var handlerThread: HandlerThread? = null
    private var handler: Handler? = null
    private lateinit var ocrHandler: PaddleOcrHandler
    private var resultDialog: FloatingResultDialog? = null
    private var accessToken: String? = null
    private var sessionId: String? = null
    @Volatile
    private var isCapturing: Boolean = false
    private val captureScale = 0.5f
    @Volatile
    private var warmUpDone = false
    @Volatile
    private var lastCaptureStart = 0L

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "⏱️ [INIT] FloatingOcrService onCreate START")
        val tStart = android.os.SystemClock.uptimeMillis()
        
        ocrHandler = PaddleOcrHandler(this)
        handlerThread = HandlerThread("FloatingOcrCapture").apply { start() }
        handler = handlerThread?.looper?.let { Handler(it) }
        windowManager = getSystemService(WINDOW_SERVICE) as? WindowManager
        windowManager?.let { resultDialog = FloatingResultDialog(this, it) }

        // 预热OCR引擎，触发模型和 OpenCL 等加载，降低首帧时延
        Thread {
            try {
                val tOcrStart = android.os.SystemClock.uptimeMillis()
                Log.i(TAG, "⏱️ [WARMUP] OCR warmup START")
                val dummy = Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888)
                ocrHandler.recognize(dummy)
                dummy.recycle()
                warmUpDone = true
                Log.i(TAG, "⏱️ [WARMUP] OCR warmup DONE, elapsed=${android.os.SystemClock.uptimeMillis() - tOcrStart}ms")
            } catch (e: Exception) {
                Log.w(TAG, "⏱️ [WARMUP] OCR warmup failed: ${e.message}")
            }
        }.start()
        
        Log.i(TAG, "⏱️ [INIT] FloatingOcrService onCreate DONE, elapsed=${android.os.SystemClock.uptimeMillis() - tStart}ms")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.i(TAG, "⏱️ [INIT] onStartCommand START")
        val tStart = android.os.SystemClock.uptimeMillis()
        
        val resultCode = intent?.getIntExtra(EXTRA_RESULT_CODE, Activity.RESULT_CANCELED)
        val resultData: Intent? = intent?.getParcelableExtra(EXTRA_RESULT_DATA)
        val mgr = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as? MediaProjectionManager

        // 保存访问令牌和会话ID
        accessToken = intent?.getStringExtra(EXTRA_ACCESS_TOKEN)
        sessionId = intent?.getStringExtra(EXTRA_SESSION_ID)
        
        // 预热AI HTTP连接
        resultDialog?.warmUpConnection(accessToken)
        Log.i(TAG, "⏱️ [INIT] AI connection warmup triggered")

        if (resultCode != Activity.RESULT_OK || resultData == null || mgr == null) {
            FloatingOcrBridge.emit("error", message = "录屏权限无效，无法启动悬浮截屏")
            stopSelf()
            return START_NOT_STICKY
        }

        // 必须先进入前台并声明 mediaProjection 类型，避免 SecurityException。
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                buildNotification(),
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )
        } else {
            startForeground(NOTIFICATION_ID, buildNotification())
        }

        mediaProjection?.stop()
        mediaProjection = mgr.getMediaProjection(resultCode, resultData)
        attachOverlayIfNeeded()
        Toast.makeText(applicationContext, "悬浮截屏已就绪", Toast.LENGTH_SHORT).show()
        FloatingOcrBridge.emit("ready")
        return START_STICKY
    }

    override fun onBind(intent: Intent?) = null

    override fun onDestroy() {
        super.onDestroy()
        tearDownCapture()
        removeOverlay()
        resultDialog?.destroy()
        handlerThread?.quitSafely()
    }

    private fun buildNotification(): Notification {
        val channelName = "悬浮截屏"
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                channelName,
                NotificationManager.IMPORTANCE_LOW
            )
            manager.createNotificationChannel(channel)
        }

        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pending = PendingIntent.getActivity(
            this,
            1001,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val iconRes = if (applicationInfo.icon != 0) applicationInfo.icon else android.R.drawable.ic_menu_camera

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(iconRes)
            .setContentTitle("截屏待命")
            .setContentText("点击悬浮球以截屏并添加日程")
            .setContentIntent(pending)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun attachOverlayIfNeeded() {
        if (overlayView != null || windowManager == null) return

        val density = resources.displayMetrics.density
        val sizePx = (56 * density).toInt() // 稍微小一点更精致
        val edgePadding = (8 * density).toInt()
        
        val bubble = ImageButton(applicationContext).apply {
            setImageResource(android.R.drawable.ic_menu_camera)
            val bg = GradientDrawable().apply {
                cornerRadius = sizePx / 2f // 完美圆形
                setColor(0xCC000000.toInt()) // 稍微不透明一点
            }
            background = bg
            setPadding((14 * density).toInt(), (14 * density).toInt(), (14 * density).toInt(), (14 * density).toInt())
            isClickable = true
            isFocusable = false
            alpha = 0.85f // 轻微透明
            setOnClickListener {
                captureScreenOnce()
            }
        }

        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }

        // 初始位置放在右边缘中间偏上
        val screenHeight = resources.displayMetrics.heightPixels
        val screenWidth = resources.displayMetrics.widthPixels
        
        val params = WindowManager.LayoutParams(
            sizePx,
            sizePx,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = screenWidth - sizePx - edgePadding // 右边缘
            y = screenHeight / 3 // 屏幕上三分之一处
        }

        windowManager?.addView(bubble, params)
        overlayView = bubble
        overlayParams = params
        enableDrag(bubble, params)
    }

    private fun removeOverlay() {
        try {
            overlayView?.let { windowManager?.removeView(it) }
        } catch (_: Exception) {
        } finally {
            overlayView = null
        }
    }

    private fun captureScreenOnce() {
        val t0 = android.os.SystemClock.uptimeMillis()
        Log.i(TAG, "⏱️ [T0] captureScreenOnce START at $t0")
        
        if (isCapturing) {
            Log.w(TAG, "captureScreenOnce: already capturing, skip")
            return
        }
        val mp = mediaProjection
        val h = this.handler
        if (mp == null || h == null) {
            FloatingOcrBridge.emit("error", message = "录屏服务不可用，请重启悬浮窗")
            Toast.makeText(applicationContext, "悬浮窗未准备好，请重新开启", Toast.LENGTH_SHORT).show()
            Log.e(TAG, "captureScreenOnce: mediaProjection=$mp, handler=$h")
            return
        }

        isCapturing = true
        lastCaptureStart = t0
        Log.i(TAG, "⏱️ [T1] captureScreenOnce: init check done, elapsed=${android.os.SystemClock.uptimeMillis() - t0}ms")
        
        // 先隐藏悬浮球，避免截到自己
        overlayView?.visibility = View.INVISIBLE
        Log.i(TAG, "⏱️ [T2] bubble hidden, elapsed=${android.os.SystemClock.uptimeMillis() - lastCaptureStart}ms")
        
        // 延迟一点再截屏，确保悬浮球已隐藏
        h.postDelayed({
            // 静默处理，不显示任何弹窗
            FloatingOcrBridge.emit("capturing")
            
            // 防止异常情况下 isCapturing 一直为 true，10 秒后兜底重置
            handler?.postDelayed({
                if (isCapturing) {
                    Log.w(TAG, "captureScreenOnce: timeout, resetting")
                    isCapturing = false
                    tearDownCapture()
                    // 必须在主线程修改View
                    android.os.Handler(android.os.Looper.getMainLooper()).post {
                        overlayView?.visibility = View.VISIBLE
                    }
                }
            }, 10000)

            Log.i(TAG, "⏱️ [T3] postDelayed callback, elapsed=${android.os.SystemClock.uptimeMillis() - lastCaptureStart}ms")
            
            val metrics = resources.displayMetrics
            val width = (metrics.widthPixels * captureScale).toInt().coerceAtLeast(1)
            val height = (metrics.heightPixels * captureScale).toInt().coerceAtLeast(1)
            val density = metrics.densityDpi
            Log.d(TAG, "captureScreenOnce: creating virtualDisplay ${width}x${height}")

            tearDownCapture()
            val tBeforeVD = android.os.SystemClock.uptimeMillis()
            imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
            Log.i(TAG, "⏱️ [T4] ImageReader created, elapsed=${android.os.SystemClock.uptimeMillis() - lastCaptureStart}ms")
            
            virtualDisplay = mp.createVirtualDisplay(
                "floating_ocr",
                width,
                height,
                density,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader?.surface,
                null,
                h
            )
            Log.i(TAG, "⏱️ [T5] VirtualDisplay created, elapsed=${android.os.SystemClock.uptimeMillis() - lastCaptureStart}ms, VD_time=${android.os.SystemClock.uptimeMillis() - tBeforeVD}ms")

            var frameCount = 0
            val maxSkipFrames = 2
            imageReader?.setOnImageAvailableListener({ reader ->
                val tFrameReceived = android.os.SystemClock.uptimeMillis()
                val image = reader.acquireLatestImage() ?: return@setOnImageAvailableListener
                frameCount++
                Log.i(TAG, "⏱️ [T6] Frame #$frameCount received, elapsed=${tFrameReceived - lastCaptureStart}ms")
                
                val plane = image.planes[0]
                val buffer = plane.buffer.duplicate()
                if (buffer.remaining() >= 4) {
                    val firstPixel = buffer.getInt(0)
                    val alpha = (firstPixel shr 24) and 0xFF
                    
                    if (alpha == 0 && frameCount < maxSkipFrames) {
                        Log.d(TAG, "captureScreenOnce: skipping transparent frame")
                        image.close()
                        return@setOnImageAvailableListener
                    }
                }
                
                // 恢复悬浮球显示
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                    overlayView?.visibility = View.VISIBLE
                }
                
                handleImage(image, width, height)
            }, h)
        }, 100) // 延迟100ms确保悬浮球隐藏
    }

    private fun enableDrag(view: View, params: WindowManager.LayoutParams) {
        var downX = 0f
        var downY = 0f
        var startRawX = 0f
        var startRawY = 0f
        val touchSlop = 12
        
        val metrics = resources.displayMetrics
        val screenWidth = metrics.widthPixels
        val screenHeight = metrics.heightPixels
        val bubbleSize = (64 * metrics.density).toInt()
        val edgePadding = (8 * metrics.density).toInt() // 边缘间距
        val statusBarHeight = getStatusBarHeight()
        
        view.setOnTouchListener { v, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    downX = event.x
                    downY = event.y
                    startRawX = event.rawX
                    startRawY = event.rawY
                    // 取消可能正在进行的吸附动画
                    v.animate().cancel()
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val wm = windowManager ?: return@setOnTouchListener false
                    val newX = (event.rawX - downX).toInt()
                    val newY = (event.rawY - downY).toInt()
                    params.x = newX
                    params.y = newY
                    wm.updateViewLayout(view, params)
                    true
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    val dx = (event.rawX - startRawX).toInt()
                    val dy = (event.rawY - startRawY).toInt()
                    
                    // 判断是点击还是拖拽
                    if (kotlin.math.abs(dx) < touchSlop && kotlin.math.abs(dy) < touchSlop) {
                        captureScreenOnce()
                        v.performClick()
                    } else {
                        // 拖拽结束，执行边缘吸附动画
                        snapToEdge(view, params, screenWidth, screenHeight, bubbleSize, edgePadding, statusBarHeight)
                    }
                    true
                }
                else -> false
            }
        }
    }
    
    /**
     * 边缘吸附动画 - 将悬浮球吸附到最近的屏幕边缘
     */
    private fun snapToEdge(
        view: View,
        params: WindowManager.LayoutParams,
        screenWidth: Int,
        screenHeight: Int,
        bubbleSize: Int,
        edgePadding: Int,
        statusBarHeight: Int
    ) {
        val wm = windowManager ?: return
        val currentX = params.x
        val currentY = params.y
        val centerX = currentX + bubbleSize / 2
        
        // 计算目标X位置：吸附到左边或右边
        val targetX = if (centerX < screenWidth / 2) {
            edgePadding // 吸附到左边
        } else {
            screenWidth - bubbleSize - edgePadding // 吸附到右边
        }
        
        // 计算目标Y位置：限制在屏幕范围内
        val minY = statusBarHeight + edgePadding
        val maxY = screenHeight - bubbleSize - edgePadding - getNavigationBarHeight()
        val targetY = currentY.coerceIn(minY, maxY)
        
        // 使用 ValueAnimator 实现平滑的弹性动画
        val startX = currentX
        val startY = currentY
        
        android.animation.ValueAnimator.ofFloat(0f, 1f).apply {
            duration = 250
            interpolator = android.view.animation.OvershootInterpolator(0.8f) // 弹性效果
            addUpdateListener { animator ->
                val progress = animator.animatedValue as Float
                params.x = (startX + (targetX - startX) * progress).toInt()
                params.y = (startY + (targetY - startY) * progress).toInt()
                try {
                    wm.updateViewLayout(view, params)
                } catch (e: Exception) {
                    // View 可能已被移除
                    cancel()
                }
            }
            start()
        }
    }
    
    private fun getStatusBarHeight(): Int {
        val resourceId = resources.getIdentifier("status_bar_height", "dimen", "android")
        return if (resourceId > 0) resources.getDimensionPixelSize(resourceId) else 0
    }
    
    private fun getNavigationBarHeight(): Int {
        val resourceId = resources.getIdentifier("navigation_bar_height", "dimen", "android")
        return if (resourceId > 0) resources.getDimensionPixelSize(resourceId) else 0
    }

    private fun handleImage(image: Image, width: Int, height: Int) {
        val tHandleStart = android.os.SystemClock.uptimeMillis()
        Log.i(TAG, "⏱️ [T7] handleImage START, elapsed=${tHandleStart - lastCaptureStart}ms")
        
        // 先转换bitmap（这个很快），然后关闭image释放资源
        val bitmap: android.graphics.Bitmap
        val tCaptureEnd: Long
        try {
            val tBitmapStart = android.os.SystemClock.uptimeMillis()
            bitmap = imageToBitmap(image, width, height)
            tCaptureEnd = android.os.SystemClock.uptimeMillis()
            Log.i(TAG, "⏱️ [T8] imageToBitmap done, bitmap_time=${tCaptureEnd - tBitmapStart}ms, elapsed=${tCaptureEnd - lastCaptureStart}ms")
        } catch (e: Exception) {
            Log.e(TAG, "handleImage bitmap conversion error", e)
            image.close()
            tearDownCapture()
            isCapturing = false
            return
        } finally {
            image.close()
            tearDownCapture()
        }
        
        // 静默处理，不显示中间状态弹窗
        val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())
        
        // OCR 在后台线程执行，避免阻塞UI
        Thread {
            try {
                val tThreadStart = android.os.SystemClock.uptimeMillis()
                Log.i(TAG, "⏱️ [T9] OCR thread START, elapsed=${tThreadStart - lastCaptureStart}ms")
                
                val tPrepStart = android.os.SystemClock.uptimeMillis()
                val roi = cropRoi(bitmap)
                val tCropEnd = android.os.SystemClock.uptimeMillis()
                Log.i(TAG, "⏱️ [T10] cropRoi done, crop_time=${tCropEnd - tPrepStart}ms, elapsed=${tCropEnd - lastCaptureStart}ms")
                
                if (roi !== bitmap) {
                    bitmap.recycle()
                }
                val scaled = scaleBitmapIfNeeded(roi)
                val tScaleEnd = android.os.SystemClock.uptimeMillis()
                Log.i(TAG, "⏱️ [T11] scaleBitmap done, scale_time=${tScaleEnd - tCropEnd}ms, elapsed=${tScaleEnd - lastCaptureStart}ms")
                
                if (scaled !== roi) {
                    roi.recycle()
                }
                val tPrepEnd = android.os.SystemClock.uptimeMillis()
                
                Log.i(TAG, "⏱️ [T12] OCR recognize START, elapsed=${tPrepEnd - lastCaptureStart}ms")
                val text = ocrHandler.recognize(scaled)
                val tOcrEnd = android.os.SystemClock.uptimeMillis()
                Log.i(TAG, "⏱️ [T13] OCR recognize DONE, ocr_time=${tOcrEnd - tPrepEnd}ms, elapsed=${tOcrEnd - lastCaptureStart}ms")
                
                Log.i(
                    TAG,
                    "📊 perf summary: capture=${tCaptureEnd - lastCaptureStart}ms, prep=${tPrepEnd - tPrepStart}ms, ocr=${tOcrEnd - tPrepEnd}ms, total=${tOcrEnd - lastCaptureStart}ms"
                )
                scaled.recycle()
                
                // 静默调用 AI，只在成功后显示结果
                val tBeforePost = android.os.SystemClock.uptimeMillis()
                Log.i(TAG, "⏱️ [T14] before mainHandler.post, elapsed=${tBeforePost - lastCaptureStart}ms")
                mainHandler.post {
                    val tPostExecute = android.os.SystemClock.uptimeMillis()
                    Log.i(TAG, "⏱️ [T15] mainHandler.post executed, elapsed=${tPostExecute - lastCaptureStart}ms")
                    // 直接调用 AI，不显示中间状态
                    resultDialog?.showSilent(text, accessToken, lastCaptureStart)
                    Log.i(TAG, "⏱️ [T16] AI trigger done, elapsed=${android.os.SystemClock.uptimeMillis() - lastCaptureStart}ms")
                    FloatingOcrBridge.emit("success", text = text)
                    isCapturing = false
                }
            } catch (e: Exception) {
                Log.e(TAG, "handleImage OCR error", e)
                bitmap.recycle()
                mainHandler.post {
                    // OCR 失败时简单 Toast 提示
                    Toast.makeText(applicationContext, "识别失败，请重试", Toast.LENGTH_SHORT).show()
                    FloatingOcrBridge.emit("error", message = e.message ?: "截屏识别失败")
                    isCapturing = false
                }
            }
        }.start()
    }

    private fun scaleBitmapIfNeeded(src: Bitmap): Bitmap {
        val maxSide = maxOf(src.width, src.height)
        val targetMaxSide = 900
        if (maxSide <= targetMaxSide) return src
        val scale = targetMaxSide.toFloat() / maxSide
        val targetWidth = (src.width * scale).toInt().coerceAtLeast(1)
        val targetHeight = (src.height * scale).toInt().coerceAtLeast(1)
        Log.d(TAG, "scaleBitmapIfNeeded: ${src.width}x${src.height} -> ${targetWidth}x${targetHeight}")
        return Bitmap.createScaledBitmap(src, targetWidth, targetHeight, true)
    }

    private fun cropRoi(src: Bitmap): Bitmap {
        // 粗裁掉状态栏/导航栏/底部输入区，保留中部区域
        val cutTop = (src.height * 0.15f).toInt()
        val cutBottom = (src.height * 0.18f).toInt()
        val top = cutTop.coerceAtLeast(0)
        val height = (src.height - top - cutBottom).coerceAtLeast(src.height / 2)
        return if (height <= 0 || top + height > src.height) src
        else Bitmap.createBitmap(src, 0, top, src.width, height)
    }

    private fun tearDownCapture() {
        try {
            virtualDisplay?.release()
        } catch (_: Exception) {
        } finally {
            virtualDisplay = null
        }

        try {
            imageReader?.close()
        } catch (_: Exception) {
        } finally {
            imageReader = null
        }
    }

    private fun imageToBitmap(image: Image, width: Int, height: Int): Bitmap {
        val plane = image.planes[0]
        val buffer = plane.buffer
        val pixelStride = plane.pixelStride
        val rowStride = plane.rowStride
        val rowPadding = rowStride - pixelStride * width
        val temp = Bitmap.createBitmap(
            width + rowPadding / pixelStride,
            height,
            Bitmap.Config.ARGB_8888
        )
        temp.copyPixelsFromBuffer(buffer)
        val cropped = Bitmap.createBitmap(temp, 0, 0, width, height)
        temp.recycle()
        return cropped
    }

}
