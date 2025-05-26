package com.example.tj_tms_mobile.plugin

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import java.util.concurrent.ConcurrentHashMap

class PluginManager(private val context: Context, private val engine: FlutterEngine) {
    private val TAG = "PluginManager"
    private val plugins = ConcurrentHashMap<String, Plugin>()

    fun registerPlugin(pluginId: String, plugin: Plugin) {
        plugins[pluginId] = plugin
        Log.d(TAG, "Registered plugin: $pluginId")
    }

    fun initializePlugins() {
        plugins.values.forEach { plugin ->
            try {
                plugin.initialize()
                Log.d(TAG, "Initialized plugin: ${plugin.getName()}")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize plugin: ${plugin.getName()}", e)
            }
        }
    }

    fun releasePlugins() {
        plugins.values.forEach { plugin ->
            try {
                plugin.release()
                Log.d(TAG, "Released plugin: ${plugin.getName()}")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to release plugin: ${plugin.getName()}", e)
            }
        }
        plugins.clear()
    }
} 