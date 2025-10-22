package com.example.tj_tms_mobile.plugin

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import com.example.tj_tms_mobile.plugins.BarcodeScannerPlugin
import com.example.tj_tms_mobile.plugins.UHFPlugin

/**
 * 插件工厂
 * 负责创建和配置各种插件实例
 */
class PluginFactory(private val context: Context, private val engine: FlutterEngine) {
    private val TAG = "PluginFactory"

    /**
     * 创建条形码扫描插件
     */
    fun createBarcodeScannerPlugin(): BarcodeScannerPlugin {
        Log.d(TAG, "Creating BarcodeScannerPlugin...")
        return BarcodeScannerPlugin(context, engine)
    }

    /**
     * 创建UHF插件
     */
    fun createUHFPlugin(): UHFPlugin {
        Log.d(TAG, "Creating UHFPlugin...")
        return UHFPlugin(context.applicationContext, engine)
    }

    /**
     * 创建事件通道
     * @param channelName 通道名称
     * @return 事件通道实例
     */
    fun createEventChannel(channelName: String): EventChannel {
        Log.d(TAG, "Creating EventChannel: $channelName")
        return EventChannel(engine.dartExecutor.binaryMessenger, channelName)
    }

    /**
     * 设置条形码扫描插件的事件通道
     */
    fun setupBarcodeScannerEventChannel(plugin: BarcodeScannerPlugin): EventChannel {
        val eventChannel = createEventChannel("com.example.tj_tms_mobile/barcode_events")
        plugin.setEventChannel(eventChannel)
        
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                Log.d(TAG, "Barcode event channel listening")
                events?.let { eventSink ->
                    plugin.setEventSink(eventSink)
                }
            }

            override fun onCancel(arguments: Any?) {
                Log.d(TAG, "Barcode event channel canceled")
                plugin.setEventSink(null)
            }
        })
        
        return eventChannel
    }

    /**
     * 设置UHF插件的事件通道
     */
    fun setupUHFEventChannel(plugin: UHFPlugin): EventChannel {
        val eventChannel = createEventChannel("com.example.tj_tms_mobile/uhf_scanner_events")
        plugin.setEventChannel(eventChannel)
        
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                Log.d(TAG, "UHF event channel listening")
                events?.let { eventSink ->
                    plugin.setEventSink(eventSink)
                }
            }

            override fun onCancel(arguments: Any?) {
                Log.d(TAG, "UHF event channel canceled")
                plugin.setEventSink(null)
            }
        })
        
        return eventChannel
    }
}