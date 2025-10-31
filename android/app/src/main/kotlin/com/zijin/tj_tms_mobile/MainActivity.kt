package com.zijin.tj_tms_mobile

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import android.view.View
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.zijin.tj_tms_mobile.plugin.PluginFactory
import com.zijin.tj_tms_mobile.plugin.PluginManager
import com.zijin.tj_tms_mobile.LocationServicePlugin

/**
 * 主Activity
 * 负责Flutter引擎配置、插件管理、系统服务配置等
 */
class MainActivity : FlutterActivity() {
    private val TAG = "MainActivity"
    
    // 插件管理
    private lateinit var pluginFactory: PluginFactory
    private lateinit var pluginManager: PluginManager
    
    // 系统UI标志
    private var isApplyingSystemUi = false
    
    // 系统服务通道
    private lateinit var batteryOptimizationChannel: MethodChannel
    private lateinit var appKeepAliveChannel: MethodChannel
    private lateinit var foregroundLocationChannel: MethodChannel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "MainActivity onCreate")
        hideSystemUI()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        try {
            // 初始化插件系统
            initializePlugins(flutterEngine)
            
            // 注册位置服务插件
            val locationServicePlugin = LocationServicePlugin()
            flutterEngine.plugins.add(locationServicePlugin)
            
            // 设置系统服务通道
            setupSystemServiceChannels(flutterEngine)
            
            Log.d(TAG, "Flutter引擎配置完成")
        } catch (e: Exception) {
            Log.e(TAG, "配置Flutter引擎失败", e)
        }
    }

    /**
     * 初始化所有插件
     */
    private fun initializePlugins(flutterEngine: FlutterEngine) {
        Log.d(TAG, "开始初始化插件系统...")
        
        // 创建插件工厂和管理器
        pluginFactory = PluginFactory(context = this, engine = flutterEngine)
        pluginManager = PluginManager(context = this, engine = flutterEngine)
        
        // 创建并注册条形码扫描插件
        val barcodeScannerPlugin = pluginFactory.createBarcodeScannerPlugin()
        pluginManager.registerPlugin("barcode_scanner", barcodeScannerPlugin)
        
        // 设置条形码扫描插件的事件通道
        val barcodeEventChannel = pluginFactory.setupBarcodeScannerEventChannel(barcodeScannerPlugin)
        pluginManager.registerEventChannel("barcode_events", barcodeEventChannel)
        
        // 创建并注册UHF插件
        val uhfPlugin = pluginFactory.createUHFPlugin()
        pluginManager.registerPlugin(uhfPlugin.pluginId, uhfPlugin)
        
        // 设置UHF插件的事件通道
        val uhfEventChannel = pluginFactory.setupUHFEventChannel(uhfPlugin)
        pluginManager.registerEventChannel("uhf_events", uhfEventChannel)
        
        // 初始化所有已注册的插件
        pluginManager.initializePlugins()
        
        Log.d(TAG, "插件系统初始化完成，共注册 ${pluginManager.getPluginCount()} 个插件")
    }

    /**
     * 设置系统服务相关的MethodChannel
     */
    private fun setupSystemServiceChannels(flutterEngine: FlutterEngine) {
        // 设置电池优化MethodChannel
        batteryOptimizationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.zijin.tj_tms_mobile/battery_optimization"
        )
        batteryOptimizationChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" -> result.success(isIgnoringBatteryOptimizations())
                "requestIgnoreBatteryOptimizations" -> {
                    requestIgnoreBatteryOptimizations()
                    result.success(null)
                }
                "openBatteryOptimizationSettings" -> {
                    openBatteryOptimizationSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        
        // 设置应用保活MethodChannel
        appKeepAliveChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.zijin.tj_tms_mobile/app_keep_alive"
        )
        appKeepAliveChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAutoStartEnabled" -> result.success(isAutoStartEnabled())
                "openAutoStartSettings" -> {
                    openAutoStartSettings()
                    result.success(null)
                }
                "isBackgroundRunEnabled" -> result.success(isBackgroundRunEnabled())
                "openBackgroundRunSettings" -> {
                    openBackgroundRunSettings()
                    result.success(null)
                }
                "isNotificationEnabled" -> result.success(isNotificationEnabled())
                "openNotificationSettings" -> {
                    openNotificationSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // 前台定位服务MethodChannel
        foregroundLocationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.zijin.tj_tms_mobile/foreground_location"
        )
        foregroundLocationChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    // title/content 当前版本前台服务内部固定文案，如需定制可在服务内扩展
                    LocationForegroundService.startService(this)
                    result.success(null)
                }
                "stopForegroundService" -> {
                    LocationForegroundService.stopService(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        try {
            pluginManager.releasePlugins()
            Log.d(TAG, "插件资源已释放")
        } catch (e: Exception) {
            Log.e(TAG, "释放插件资源失败", e)
        }
        super.onDestroy()
    }
    
    // ==================== UI相关方法 ====================
    
    private fun hideSystemUI() {
        if (isApplyingSystemUi) return
        isApplyingSystemUi = true
        try {
            window.statusBarColor = android.graphics.Color.TRANSPARENT
            window.navigationBarColor = android.graphics.Color.TRANSPARENT

            window.decorView.systemUiVisibility = (View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_FULLSCREEN)

            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
            window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION)
            window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS)

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
            hideSystemUI()
        }
    }
    
    // ==================== 电池优化相关方法 ====================
    
    private fun isIgnoringBatteryOptimizations(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val powerManager = getSystemService(POWER_SERVICE) as PowerManager
                powerManager.isIgnoringBatteryOptimizations(packageName)
            } else {
                true
            }
        } catch (e: Exception) {
            Log.e(TAG, "检查电池优化状态失败", e)
            false
        }
    }
    
    private fun requestIgnoreBatteryOptimizations() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val powerManager = getSystemService(POWER_SERVICE) as PowerManager
                if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                    intent.data = Uri.parse("package:$packageName")
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    Log.d(TAG, "已请求忽略电池优化")
                } else {
                    Log.d(TAG, "已忽略电池优化")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "请求忽略电池优化失败", e)
            openBatteryOptimizationSettings()
        }
    }
    
    private fun openBatteryOptimizationSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            intent.data = Uri.parse("package:$packageName")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            Log.d(TAG, "已打开应用设置页面")
        } catch (e: Exception) {
            Log.e(TAG, "打开应用设置页面失败", e)
        }
    }
    
    // ==================== 应用保活相关方法 ====================
    
    private fun isAutoStartEnabled(): Boolean {
        return try {
            val intent = Intent()
            when {
                Build.MANUFACTURER.equals("xiaomi", ignoreCase = true) -> {
                    intent.setClassName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")
                }
                Build.MANUFACTURER.equals("huawei", ignoreCase = true) -> {
                    intent.setClassName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity")
                }
                Build.MANUFACTURER.equals("oppo", ignoreCase = true) -> {
                    intent.setClassName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")
                }
                Build.MANUFACTURER.equals("vivo", ignoreCase = true) -> {
                    intent.setClassName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")
                }
                else -> return true
            }
            
            try {
                startActivity(intent)
                true
            } catch (e: Exception) {
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "检查自启动权限失败", e)
            false
        }
    }
    
    private fun openAutoStartSettings() {
        try {
            val intent = Intent()
            when {
                Build.MANUFACTURER.equals("xiaomi", ignoreCase = true) -> {
                    intent.setClassName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")
                }
                Build.MANUFACTURER.equals("huawei", ignoreCase = true) -> {
                    intent.setClassName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity")
                }
                Build.MANUFACTURER.equals("oppo", ignoreCase = true) -> {
                    intent.setClassName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")
                }
                Build.MANUFACTURER.equals("vivo", ignoreCase = true) -> {
                    intent.setClassName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")
                }
                else -> {
                    openBatteryOptimizationSettings()
                    return
                }
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            Log.d(TAG, "已打开自启动设置页面")
        } catch (e: Exception) {
            Log.e(TAG, "打开自启动设置页面失败", e)
            openBatteryOptimizationSettings()
        }
    }
    
    private fun isBackgroundRunEnabled(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val powerManager = getSystemService(POWER_SERVICE) as PowerManager
                powerManager.isIgnoringBatteryOptimizations(packageName)
            } else {
                true
            }
        } catch (e: Exception) {
            Log.e(TAG, "检查后台运行权限失败", e)
            false
        }
    }
    
    private fun openBackgroundRunSettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val powerManager = getSystemService(POWER_SERVICE) as PowerManager
                if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                    intent.data = Uri.parse("package:$packageName")
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                } else {
                    openBatteryOptimizationSettings()
                }
            } else {
                openBatteryOptimizationSettings()
            }
            Log.d(TAG, "已打开后台运行设置页面")
        } catch (e: Exception) {
            Log.e(TAG, "打开后台运行设置页面失败", e)
            openBatteryOptimizationSettings()
        }
    }
    
    private fun isNotificationEnabled(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                val notificationManager = getSystemService(android.content.Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                notificationManager.areNotificationsEnabled()
            } else {
                true
            }
        } catch (e: Exception) {
            Log.e(TAG, "检查通知权限失败", e)
            false
        }
    }
    
    private fun openNotificationSettings() {
        try {
            val intent = Intent()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                intent.action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
                intent.putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            } else {
                intent.action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                intent.data = Uri.parse("package:$packageName")
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            Log.d(TAG, "已打开通知设置页面")
        } catch (e: Exception) {
            Log.e(TAG, "打开通知设置页面失败", e)
            openBatteryOptimizationSettings()
        }
    }
}
