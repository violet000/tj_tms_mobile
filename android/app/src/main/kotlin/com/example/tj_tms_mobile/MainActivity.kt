package com.example.tj_tms_mobile

import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.example.tj_tms_mobile.plugin.PluginManager
import com.example.uhf_plugin.UHFPlugin
import com.example.tj_tms_mobile.LocationServicePlugin
import com.example.tj_tms_mobile.plugins.LivenessDetectionPlugin

class MainActivity : FlutterActivity() {
    private val TAG = "MainActivity"
    private lateinit var pluginManager: PluginManager
    private lateinit var barcodeScannerPlugin: BarcodeScannerPlugin
    private lateinit var uhfPlugin: UHFPlugin
    private lateinit var locationServicePlugin: LocationServicePlugin
    private lateinit var livenessDetectionPlugin: LivenessDetectionPlugin
    private var isApplyingSystemUi = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "MainActivity onCreate")
        
        // 隐藏虚拟按键
        hideSystemUI()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        try {
            // 初始化插件管理器
            pluginManager = PluginManager(context = this, engine = flutterEngine)
            
            // 创建并注册条形码扫描插件
            barcodeScannerPlugin = BarcodeScannerPlugin(context = this, engine = flutterEngine)
            pluginManager.registerPlugin("barcode_scanner", barcodeScannerPlugin)

            // 创建并注册UHF插件
            uhfPlugin = UHFPlugin(applicationContext, flutterEngine)
            pluginManager.registerPlugin(uhfPlugin.pluginId, uhfPlugin)

            // 创建并注册活体检测插件
            livenessDetectionPlugin = LivenessDetectionPlugin(context = this, engine = flutterEngine)
            pluginManager.registerPlugin("liveness_detection", livenessDetectionPlugin)

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
            
            // 注册位置服务插件
            locationServicePlugin = LocationServicePlugin()
            flutterEngine.plugins.add(locationServicePlugin)
            
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
    
    private fun hideSystemUI() {
        if (isApplyingSystemUi) return
        isApplyingSystemUi = true
        try {
            // 设置透明状态栏和导航栏
            window.statusBarColor = android.graphics.Color.TRANSPARENT
            window.navigationBarColor = android.graphics.Color.TRANSPARENT

            // 设置系统UI为透明模式，隐藏导航栏
            window.decorView.systemUiVisibility = (View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_FULLSCREEN)

            // 强制设置导航栏为透明
            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
            window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION)
            window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS)

            // 简化监听器，避免递归调用和频繁重入
            window.decorView.setOnSystemUiVisibilityChangeListener { _ ->
                window.navigationBarColor = android.graphics.Color.TRANSPARENT
                window.statusBarColor = android.graphics.Color.TRANSPARENT
            }
        } catch (e: Exception) {
            Log.e(TAG, "设置沉浸式UI失败", e)
        } finally {
            isApplyingSystemUi = false
        }
    }
    
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            // 仅执行一次轻量设置，避免在焦点抖动时多次重入
            hideSystemUI()
        }
    }
    
    private fun setNavigationBarTransparent() {
        try {
            // 使用反射强制设置导航栏透明
            val windowClass = window.javaClass
            val setNavigationBarColorMethod = windowClass.getMethod("setNavigationBarColor", Int::class.java)
            setNavigationBarColorMethod.invoke(window, android.graphics.Color.TRANSPARENT)
            
            // 延迟再次设置
            window.decorView.postDelayed({
                try {
                    setNavigationBarColorMethod.invoke(window, android.graphics.Color.TRANSPARENT)
                } catch (e: Exception) {
                    Log.e(TAG, "延迟设置导航栏透明失败", e)
                }
            }, 500)
        } catch (e: Exception) {
            Log.e(TAG, "设置导航栏透明失败", e)
        }
    }
    
    private fun disableNavigationBar() {
        try {
            // 设置全屏模式
            window.setFlags(
                WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN
            )
            
            // 保持与 hideSystemUI 同步，不再重复设置，避免 ANR 风险
            window.decorView.systemUiVisibility = (View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_FULLSCREEN)
            
        } catch (e: Exception) {
            Log.e(TAG, "禁用导航栏失败", e)
        }
    }
}