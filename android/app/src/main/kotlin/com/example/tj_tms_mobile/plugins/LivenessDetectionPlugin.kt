package com.example.tj_tms_mobile.plugins

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import com.example.tj_tms_mobile.plugin.Plugin

class LivenessDetectionPlugin(
    private val context: Context,
    private val engine: FlutterEngine
) : Plugin, MethodCallHandler {
    
    private val TAG = "LivenessDetectionPlugin"
    private var isInitialized = false
    private lateinit var methodChannel: MethodChannel
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    
    override val pluginId: String = "liveness_detection"
    
    override fun getName(): String = "liveness_detection"
    
    // 配置参数
    private val config: MutableMap<String, Any?> = mutableMapOf()
    
    override fun initialize() {
        if (isInitialized) {
            Log.w(TAG, "Liveness detection plugin already initialized")
            return
        }
        
        try {
            // 初始化方法通道
            methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.example.tj_tms_mobile/liveness_detection")
            methodChannel.setMethodCallHandler(this)
            // 初始化事件通道
            eventChannel = EventChannel(engine.dartExecutor.binaryMessenger, "com.example.tj_tms_mobile/liveness_detection_events")
            eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    Log.d(TAG, "Liveness event channel listening")
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    Log.d(TAG, "Liveness event channel canceled")
                }
            })
            
            isInitialized = true
            Log.d(TAG, "Liveness detection plugin initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize liveness detection plugin", e)
            throw e
        }
    }
    
    override fun release() {
        if (!isInitialized) {
            Log.w(TAG, "Liveness detection plugin not initialized")
            return
        }
        
        try {
            methodChannel.setMethodCallHandler(null)
            isInitialized = false
            Log.d(TAG, "Liveness detection plugin released successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to release liveness detection plugin", e)
        }
    }
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isAvailable" -> {
                result.success(isSdkAvailable())
            }
            "configure" -> {
                val cfg = call.argument<Map<String, Any?>>("config")
                if (cfg == null) {
                    result.error("INVALID_PARAMETERS", "config is required", null)
                    return
                }
                config.clear()
                config.putAll(cfg)
                result.success(true)
            }
            "initialize" -> {
                val license = call.argument<String>("license")
                val packageLicense = call.argument<String>("packageLicense")
                if (license.isNullOrEmpty() || packageLicense.isNullOrEmpty()) {
                    result.error("INVALID_PARAMETERS", "License and packageLicense are required", null)
                    return
                }
                config["license"] = license
                config["packageLicense"] = packageLicense
                result.success(true)
            }
            "startLivenessDetection" -> {
                if (!isInitialized) {
                    result.error("NOT_INITIALIZED", "Plugin not initialized", null)
                    return
                }
                if (!config.containsKey("license") || !config.containsKey("packageLicense")) {
                    result.error("NOT_CONFIGURED", "License not configured", null)
                    return
                }
                startLivenessDetection(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun isSdkAvailable(): Boolean {
        return try {
            Class.forName("cn.cloudwalk.libproject.config.CwLiveConfig")
            true
        } catch (e: ClassNotFoundException) {
            false
        } catch (e: Exception) {
            false
        }
    }

    private fun startLivenessDetection(result: Result) {
        try {
            // 调用活体检测辅助类，传递配置与事件分发
            LivenessDetectionHelper.startLive(context, config)
            eventSink?.success(mapOf(
                "event" to "started"
            ))
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start liveness detection", e)
            result.error("START_FAILED", "Failed to start liveness detection: ${e.message}", null)
        }
    }
} 