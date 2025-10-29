package com.zijin.tj_tms_mobile.plugin

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import java.util.concurrent.ConcurrentHashMap

/**
 * 插件管理器
 * 负责统一管理所有插件的注册、初始化、释放等生命周期
 */
class PluginManager(private val context: Context, private val engine: FlutterEngine) {
    private val TAG = "PluginManager"
    private val plugins = ConcurrentHashMap<String, Plugin>()
    private val eventChannels = ConcurrentHashMap<String, EventChannel>()
    private var isInitialized = false

    /**
     * 注册插件
     * @param pluginId 插件唯一标识
     * @param plugin 插件实例
     */
    fun registerPlugin(pluginId: String, plugin: Plugin) {
        if (plugins.containsKey(pluginId)) {
            Log.w(TAG, "Plugin $pluginId already registered, replacing...")
        }
        plugins[pluginId] = plugin
        Log.d(TAG, "Registered plugin: $pluginId")
    }

    /**
     * 注册事件通道
     * @param channelName 通道名称
     * @param eventChannel 事件通道实例
     */
    fun registerEventChannel(channelName: String, eventChannel: EventChannel) {
        eventChannels[channelName] = eventChannel
        Log.d(TAG, "Registered event channel: $channelName")
    }

    /**
     * 初始化所有插件
     */
    fun initializePlugins() {
        if (isInitialized) {
            Log.w(TAG, "Plugins already initialized")
            return
        }

        Log.d(TAG, "Initializing ${plugins.size} plugins...")
        
        plugins.values.forEach { plugin ->
            try {
                plugin.initialize()
                Log.d(TAG, "✓ Initialized plugin: ${plugin.getName()}")
            } catch (e: Exception) {
                Log.e(TAG, "✗ Failed to initialize plugin: ${plugin.getName()}", e)
            }
        }
        
        isInitialized = true
        Log.d(TAG, "Plugin initialization completed")
    }

    /**
     * 释放所有插件
     */
    fun releasePlugins() {
        if (!isInitialized) {
            Log.w(TAG, "Plugins not initialized")
            return
        }

        Log.d(TAG, "Releasing ${plugins.size} plugins...")
        
        plugins.values.forEach { plugin ->
            try {
                plugin.release()
                Log.d(TAG, "✓ Released plugin: ${plugin.getName()}")
            } catch (e: Exception) {
                Log.e(TAG, "✗ Failed to release plugin: ${plugin.getName()}", e)
            }
        }
        
        // 清理事件通道
        eventChannels.values.forEach { channel ->
            try {
                channel.setStreamHandler(null)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to release event channel", e)
            }
        }
        
        plugins.clear()
        eventChannels.clear()
        isInitialized = false
        Log.d(TAG, "Plugin release completed")
    }

    /**
     * 获取插件实例
     * @param pluginId 插件ID
     * @return 插件实例，如果不存在则返回null
     */
    fun getPlugin(pluginId: String): Plugin? {
        return plugins[pluginId]
    }

    /**
     * 检查插件是否已注册
     * @param pluginId 插件ID
     * @return 是否已注册
     */
    fun isPluginRegistered(pluginId: String): Boolean {
        return plugins.containsKey(pluginId)
    }

    /**
     * 获取所有已注册的插件ID
     * @return 插件ID列表
     */
    fun getRegisteredPluginIds(): List<String> {
        return plugins.keys.toList()
    }

    /**
     * 获取插件数量
     * @return 插件数量
     */
    fun getPluginCount(): Int {
        return plugins.size
    }
} 