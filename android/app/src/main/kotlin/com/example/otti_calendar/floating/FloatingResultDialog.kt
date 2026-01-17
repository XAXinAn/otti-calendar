package com.example.otti_calendar.floating

import android.content.Context
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.TextView
import kotlinx.coroutines.*
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.IOException

/**
 * 悬浮结果弹窗 - 在任何应用上方显示OCR和AI处理结果
 */
class FloatingResultDialog(
    private val context: Context,
    private val windowManager: WindowManager,
    // 真机调试需要配置 adb reverse tcp:8080 tcp:8080
    // 或者直接使用电脑的局域网IP，如 http://192.168.x.x:8080/api
    private val baseUrl: String = "http://localhost:8080/api"
) {
    companion object {
        private const val TAG = "FloatingResultDialog"
    }

    private var dialogView: View? = null
    private var dialogParams: WindowManager.LayoutParams? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val coroutineScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    // 优化：配置连接池以复用HTTP连接
    private val client = OkHttpClient.Builder()
        .connectTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
        .readTimeout(120, java.util.concurrent.TimeUnit.SECONDS)
        .connectionPool(ConnectionPool(5, 5, java.util.concurrent.TimeUnit.MINUTES))
        .build()
    
    @Volatile
    private var isConnectionWarmedUp = false

    private var contentTextView: TextView? = null
    private var progressBar: ProgressBar? = null
    private var closeButton: Button? = null
    private var titleTextView: TextView? = null
    private var lastCaptureStartMs: Long = 0L
    @Volatile
    private var isSending = false
    private var lastContentHash: String = ""
    private var lastSentAtMs: Long = 0L

    /**
     * 显示弹窗并开始处理OCR文本（带中间状态显示）
     */
    fun show(ocrText: String, accessToken: String?, sessionId: String?, captureStartMs: Long = 0L) {
        mainHandler.post {
            lastCaptureStartMs = captureStartMs
            // 如果弹窗不存在，先创建（可能已被 showLoading 创建过）
            if (dialogView == null) {
                createDialog()
            }
            
            if (ocrText.isEmpty()) {
                showResult("未识别到文字内容")
                return@post
            }

            // 简单防重：短时间内同样的内容不重复发送，避免双击或多入口触发
            val now = SystemClock.uptimeMillis()
            val contentHash = ocrText.hashCode().toString()
            if (contentHash == lastContentHash && now - lastSentAtMs < 5000) {
                showResult("已发送处理中，请稍候…")
                return@post
            }

            showLoading("正在调用AI分析...")
            
            if (accessToken.isNullOrEmpty()) {
                showResult("未登录，请先登录后使用")
                return@post
            }

            // 调用AI接口
            callAiApi(ocrText, accessToken)
        }
    }
    
    /**
     * 静默模式：不显示任何中间状态，只在AI返回结果后显示成功弹窗
     */
    fun showSilent(ocrText: String, accessToken: String?, captureStartMs: Long = 0L) {
        lastCaptureStartMs = captureStartMs
        
        if (ocrText.isEmpty()) {
            // 静默模式下，空文本不显示任何提示
            return
        }
        
        // 简单防重
        val now = SystemClock.uptimeMillis()
        val contentHash = ocrText.hashCode().toString()
        if (contentHash == lastContentHash && now - lastSentAtMs < 5000) {
            return
        }
        
        if (accessToken.isNullOrEmpty()) {
            mainHandler.post {
                android.widget.Toast.makeText(context, "未登录，请先登录后使用", android.widget.Toast.LENGTH_SHORT).show()
            }
            return
        }
        
        // 静默调用 AI
        callAiApiSilent(ocrText, accessToken)
    }

    private fun createDialog() {
        val density = context.resources.displayMetrics.density
        val screenWidth = context.resources.displayMetrics.widthPixels
        val screenHeight = context.resources.displayMetrics.heightPixels

        val dialogWidth = (screenWidth * 0.85).toInt()
        val dialogMaxHeight = (screenHeight * 0.6).toInt()

        // 创建主容器
        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding((16 * density).toInt(), (16 * density).toInt(), (16 * density).toInt(), (16 * density).toInt())
            
            val bg = GradientDrawable().apply {
                cornerRadius = 16 * density
                setColor(0xFFFFFFFF.toInt())
            }
            background = bg
            elevation = 8 * density
        }

        // 标题
        titleTextView = TextView(context).apply {
            text = "📋 日程识别"
            textSize = 18f
            setTextColor(0xFF333333.toInt())
            setPadding(0, 0, 0, (12 * density).toInt())
        }
        container.addView(titleTextView)

        // 加载指示器
        progressBar = ProgressBar(context).apply {
            visibility = View.GONE
        }
        container.addView(progressBar, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.CENTER_HORIZONTAL
            bottomMargin = (12 * density).toInt()
        })

        // 滚动内容区
        val scrollView = ScrollView(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1f
            )
        }

        contentTextView = TextView(context).apply {
            text = ""
            textSize = 15f
            setTextColor(0xFF555555.toInt())
            setLineSpacing(4 * density, 1f)
        }
        scrollView.addView(contentTextView)
        container.addView(scrollView)

        // 关闭按钮
        closeButton = Button(context).apply {
            text = "关闭"
            setOnClickListener { dismiss() }
            val btnBg = GradientDrawable().apply {
                cornerRadius = 8 * density
                setColor(0xFF4CAF50.toInt())
            }
            background = btnBg
            setTextColor(0xFFFFFFFF.toInt())
        }
        container.addView(closeButton, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            (48 * density).toInt()
        ).apply {
            topMargin = (16 * density).toInt()
        })

        // 创建窗口参数
        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        dialogParams = WindowManager.LayoutParams(
            dialogWidth,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
        }

        dialogView = container
        windowManager.addView(container, dialogParams)
    }

    /**
     * 显示加载状态（可从外部调用）
     */
    fun showLoading(message: String) {
        mainHandler.post {
            // 如果弹窗还没创建，先创建
            if (dialogView == null) {
                createDialog()
            }
            progressBar?.visibility = View.VISIBLE
            contentTextView?.text = message
        }
    }

    private fun showResult(result: String) {
        mainHandler.post {
            progressBar?.visibility = View.GONE
            contentTextView?.text = result
        }
    }

    private fun appendResult(text: String) {
        mainHandler.post {
            progressBar?.visibility = View.GONE
            val current = contentTextView?.text?.toString() ?: ""
            contentTextView?.text = if (current == "正在分析文字..." || current.isEmpty()) {
                text
            } else {
                current + text
            }
        }
    }

    private fun callAiApi(ocrText: String, accessToken: String) {
        coroutineScope.launch {
            try {
                if (isSending) return@launch
                isSending = true
                lastContentHash = ocrText.hashCode().toString()
                lastSentAtMs = SystemClock.uptimeMillis()

                if (lastCaptureStartMs > 0) {
                    Log.i(TAG, "perf: ai_request_start=${SystemClock.uptimeMillis() - lastCaptureStartMs}ms")
                }

                // 直接调用快速日程接口，无需创建会话
                callQuickSchedule(ocrText, accessToken, showProgress = true)
                
            } catch (e: Exception) {
                Log.e(TAG, "AI API error", e)
                showResult("AI处理失败：${e.message}")
            }
        }
    }
    
    /**
     * 静默调用 AI - 不显示中间状态，只在成功后显示结果弹窗
     */
    private fun callAiApiSilent(ocrText: String, accessToken: String) {
        coroutineScope.launch {
            try {
                val tStart = SystemClock.uptimeMillis()
                Log.i(TAG, "⏱️ [AI-1] callAiApiSilent START, elapsed=${tStart - lastCaptureStartMs}ms")
                
                if (isSending) {
                    Log.w(TAG, "callAiApiSilent: already sending, skip")
                    return@launch
                }
                isSending = true
                lastContentHash = ocrText.hashCode().toString()
                lastSentAtMs = SystemClock.uptimeMillis()

                if (lastCaptureStartMs > 0) {
                    Log.i(TAG, "⏱️ [AI-2] ai_request_start=${SystemClock.uptimeMillis() - lastCaptureStartMs}ms")
                }

                // 静默调用快速日程接口
                callQuickSchedule(ocrText, accessToken, showProgress = false)
                
            } catch (e: Exception) {
                Log.e(TAG, "AI API error (silent)", e)
                // 静默模式下失败只显示 Toast
                mainHandler.post {
                    android.widget.Toast.makeText(context, "添加日程失败", android.widget.Toast.LENGTH_SHORT).show()
                }
            } finally {
                isSending = false
            }
        }
    }

    private suspend fun callQuickSchedule(ocrText: String, accessToken: String, showProgress: Boolean = true) {
        withContext(Dispatchers.IO) {
            try {
                val tPrepare = SystemClock.uptimeMillis()
                Log.i(TAG, "⏱️ [AI-3] callQuickSchedule START, elapsed=${tPrepare - lastCaptureStartMs}ms")
                
                val jsonBody = JSONObject().apply {
                    put("text", ocrText)
                }
                val tJsonDone = SystemClock.uptimeMillis()
                Log.i(TAG, "⏱️ [AI-4] JSON body created, json_time=${tJsonDone - tPrepare}ms, elapsed=${tJsonDone - lastCaptureStartMs}ms")

                val tSendStart = SystemClock.uptimeMillis()
                if (lastCaptureStartMs > 0) {
                    Log.i(TAG, "⏱️ [AI-5] before HTTP request, elapsed=${tSendStart - lastCaptureStartMs}ms")
                }

                val request = Request.Builder()
                    .url("$baseUrl/ai/quick-schedule")
                    .addHeader("Authorization", "Bearer $accessToken")
                    .addHeader("Accept", "text/event-stream")
                    .post(jsonBody.toString().toRequestBody("application/json".toMediaType()))
                    .build()
                
                val tRequestBuilt = SystemClock.uptimeMillis()
                Log.i(TAG, "⏱️ [AI-6] Request built, elapsed=${tRequestBuilt - lastCaptureStartMs}ms")

                client.newCall(request).execute().use { response ->
                    val tConnected = SystemClock.uptimeMillis()
                    if (lastCaptureStartMs > 0) {
                        Log.i(TAG, "⏱️ [AI-7] HTTP response received, http_time=${tConnected - tRequestBuilt}ms, elapsed=${tConnected - lastCaptureStartMs}ms, code=${response.code}")
                    }
                    if (!response.isSuccessful) {
                        Log.e(TAG, "⏱️ [AI-ERROR] HTTP failed: ${response.code}")
                        if (showProgress) {
                            showResult("AI请求失败: ${response.code}")
                        } else {
                            mainHandler.post {
                                android.widget.Toast.makeText(context, "请求失败", android.widget.Toast.LENGTH_SHORT).show()
                            }
                        }
                        return@withContext
                    }

                    val source = response.body?.source() ?: run {
                        Log.e(TAG, "⏱️ [AI-ERROR] Response body is null")
                        if (showProgress) {
                            showResult("响应为空")
                        }
                        return@withContext
                    }
                    
                    Log.i(TAG, "⏱️ [AI-8] Start reading SSE stream, elapsed=${SystemClock.uptimeMillis() - lastCaptureStartMs}ms")

                    var firstTokenLogged = false
                    var tokenCount = 0
                    // 解析SSE流
                    val buffer = StringBuilder()
                    while (!source.exhausted()) {
                        val line = source.readUtf8Line() ?: break
                        if (line.startsWith("data:")) {
                            val data = line.removePrefix("data:").trim()
                            if (data.isEmpty() || data == "[DONE]") continue
                            
                            try {
                                val json = JSONObject(data)
                                val content = json.optString("content", "")
                                if (content.isNotEmpty()) {
                                    tokenCount++
                                    if (!firstTokenLogged && lastCaptureStartMs > 0) {
                                        firstTokenLogged = true
                                        Log.i(TAG, "⏱️ [AI-9] ✨ FIRST TOKEN received, elapsed=${SystemClock.uptimeMillis() - lastCaptureStartMs}ms")
                                    }
                                    buffer.append(content)
                                    // 只有在 showProgress 模式下才实时显示
                                    if (showProgress) {
                                        appendResult(content)
                                    }
                                }
                            } catch (e: Exception) {
                            }
                        }
                    }

                    if (lastCaptureStartMs > 0) {
                        Log.i(TAG, "⏱️ [AI-10] SSE stream DONE, token_count=$tokenCount, elapsed=${SystemClock.uptimeMillis() - lastCaptureStartMs}ms")
                        Log.i(TAG, "🎉 总耗时: ${SystemClock.uptimeMillis() - lastCaptureStartMs}ms (目标<3000ms)")
                    }

                    // 静默模式：只在成功后显示结果弹窗
                    if (!showProgress && buffer.isNotEmpty()) {
                        mainHandler.post {
                            // 创建并显示成功弹窗
                            if (dialogView == null) {
                                createDialog()
                            }
                            titleTextView?.text = "✅ 日程已添加"
                            progressBar?.visibility = View.GONE
                            contentTextView?.text = buffer.toString()
                        }
                    } else if (showProgress && buffer.isEmpty()) {
                        showResult("AI未返回有效内容")
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Quick schedule error", e)
                if (showProgress) {
                    showResult("发送消息失败: ${e.message}")
                } else {
                    mainHandler.post {
                        android.widget.Toast.makeText(context, "添加日程失败", android.widget.Toast.LENGTH_SHORT).show()
                    }
                }
            } finally {
                isSending = false
            }
        }
    }

    fun dismiss() {
        mainHandler.post {
            try {
                dialogView?.let { windowManager.removeView(it) }
            } catch (e: Exception) {
                Log.w(TAG, "Dismiss error: $e")
            } finally {
                dialogView = null
                dialogParams = null
            }
        }
    }
    
    /**
     * 预热HTTP连接 - 在服务启动时调用，提前建立TCP连接
     */
    fun warmUpConnection(accessToken: String?) {
        if (isConnectionWarmedUp || accessToken.isNullOrEmpty()) return
        
        coroutineScope.launch {
            try {
                val tStart = SystemClock.uptimeMillis()
                Log.i(TAG, "⏱️ [WARMUP] HTTP connection warmup START")
                
                // 发送一个轻量级的HEAD请求来建立TCP连接
                val request = Request.Builder()
                    .url("$baseUrl/ai/quick-schedule")
                    .addHeader("Authorization", "Bearer $accessToken")
                    .head()
                    .build()
                
                client.newCall(request).execute().use { response ->
                    val elapsed = SystemClock.uptimeMillis() - tStart
                    Log.i(TAG, "⏱️ [WARMUP] HTTP connection warmup DONE, elapsed=${elapsed}ms, code=${response.code}")
                    isConnectionWarmedUp = true
                }
            } catch (e: Exception) {
                Log.w(TAG, "⏱️ [WARMUP] HTTP connection warmup failed: ${e.message}")
                // 预热失败不影响正常流程
            }
        }
    }

    fun destroy() {
        dismiss()
        coroutineScope.cancel()
        client.dispatcher.executorService.shutdown()
    }
}
