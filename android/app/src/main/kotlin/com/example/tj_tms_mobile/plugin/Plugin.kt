package com.example.tj_tms_mobile.plugin

interface Plugin {
    val pluginId: String
    fun getName(): String
    fun initialize()
    fun release()
} 