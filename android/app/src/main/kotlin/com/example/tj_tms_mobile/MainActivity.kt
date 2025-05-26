package com.example.tj_tms_mobile

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.example.tj_tms_mobile.plugin.PluginManager
import com.example.uhf_plugin.UHFPlugin

class MainActivity : FlutterActivity() {
    private val TAG = "MainActivity"
    private lateinit var pluginManager: PluginManager
    private lateinit var barcodeScannerPlugin: BarcodeScannerPlugin
    private lateinit var uhfPlugin: UHFPlugin

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "MainActivity onCreate")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "配置Flutter引擎")
        
        try {
            // 初始化插件管理器
            pluginManager = PluginManager(context = this, engine = flutterEngine)
            
            // 创建并注册条形码扫描插件
            barcodeScannerPlugin = BarcodeScannerPlugin(context = this, engine = flutterEngine)
            pluginManager.registerPlugin("barcode_scanner", barcodeScannerPlugin)

            // 创建并注册UHF插件
            uhfPlugin = UHFPlugin(applicationContext, flutterEngine)
            pluginManager.registerPlugin(uhfPlugin.pluginId, uhfPlugin)

            // 设置条形码扫描插件的事件通道
            val barcodeEventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.tj_tms_mobile/barcode_events")
            barcodeScannerPlugin.setEventChannel(barcodeEventChannel)
            barcodeEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "条形码事件通道已监听")
                    events?.let { eventSink ->
                        barcodeScannerPlugin.setEventSink(eventSink)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "条形码事件通道已取消")
                    barcodeScannerPlugin.setEventSink(null)
                }
            })

            // 设置UHF插件的事件通道
            val uhfEventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.uhf_plugin/uhf_events")
            uhfPlugin.setEventChannel(uhfEventChannel)
            uhfEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "UHF事件通道已监听")
                    events?.let { eventSink ->
                        uhfPlugin.setEventSink(eventSink)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "UHF事件通道已取消")
                    uhfPlugin.setEventSink(null)
                }
            })

            // 初始化所有插件
            pluginManager.initializePlugins()
            
            Log.d(TAG, "Flutter引擎配置完成")
        } catch (e: Exception) {
            Log.e(TAG, "配置Flutter引擎失败", e)
        }
    }

    override fun onDestroy() {
        try {
            pluginManager.releasePlugins()
        } catch (e: Exception) {
            Log.e(TAG, "释放插件资源失败", e)
        }
        super.onDestroy()
    }
}