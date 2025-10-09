package com.example.tj_tms_mobile

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.content.Context

class LocationServicePlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    @Volatile private var serviceStarted: Boolean = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "location_service")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startForegroundService" -> {
                try {
                    if (!serviceStarted) {
                        LocationForegroundService.startService(context)
                        serviceStarted = true
                    }
                    result.success(true)
                } catch (e: Exception) {
                    result.error("START_SERVICE_ERROR", e.message, null)
                }
            }
            "stopForegroundService" -> {
                try {
                    LocationForegroundService.stopService(context)
                    serviceStarted = false
                    result.success(true)
                } catch (e: Exception) {
                    result.error("STOP_SERVICE_ERROR", e.message, null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
} 