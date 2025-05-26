package com.example.tj_tms_mobile

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 插件管理器，用于统一管理所有插件
 */
class PluginManager(private val context: Context, private val flutterEngine: FlutterEngine) {
    private val TAG = "PluginManager"
    
    // 存储所有已注册的插件
    private val plugins = mutableMapOf<String, Plugin>()
    
    // 注册插件
    fun registerPlugin(name: String, plugin: Plugin) {
        plugins[name] = plugin
        Log.d(TAG, "Plugin registered: ${plugin.javaClass.simpleName}")
    }
    
    // 初始化所有插件
    fun initializePlugins() {
        Log.d(TAG, "初始化所有插件")
        plugins.values.forEach { plugin ->
            try {
                plugin.initialize()
                Log.d(TAG, "Plugin initialized: ${plugin.javaClass.simpleName}")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize plugin: ${plugin.javaClass.simpleName}", e)
            }
        }
    }
    
    // 释放所有插件资源
    fun releasePlugins() {
        Log.d(TAG, "释放所有插件资源")
        plugins.values.forEach { plugin ->
            try {
                plugin.release()
                Log.d(TAG, "Plugin released: ${plugin.javaClass.simpleName}")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to release plugin: ${plugin.javaClass.simpleName}", e)
            }
        }
        plugins.clear()
    }
    
    // 获取指定插件
    @Suppress("UNCHECKED_CAST")
    fun <T : Plugin> getPlugin(name: String): T? {
        return plugins[name] as? T
    }
}

/**
 * 插件接口，所有插件都需要实现此接口
 */
interface Plugin {
    // 插件唯一标识
    val pluginId: String
    
    // 初始化插件
    fun initialize()
    
    // 释放插件资源
    fun release()

    fun getName(): String
} 