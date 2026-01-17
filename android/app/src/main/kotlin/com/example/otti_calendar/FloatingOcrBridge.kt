package com.example.otti_calendar

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

object FloatingOcrBridge {
    @Volatile
    var eventSink: EventChannel.EventSink? = null
    
    private val mainHandler = Handler(Looper.getMainLooper())

    fun emit(status: String, message: String? = null, text: String? = null) {
        val payload = mutableMapOf<String, Any?>("status" to status)
        if (message != null) payload["message"] = message
        if (text != null) payload["text"] = text
        
        // EventChannel 必须在主线程发送消息
        mainHandler.post {
            eventSink?.success(payload)
        }
    }
}
