package com.zijin.tj_tms_mobile.plugin

/**
 * 插件配置信息
 */
data class PluginConfig(
    val pluginId: String,
    val className: String,
    val enabled: Boolean = true,
    val priority: Int = 0, // 优先级，数字越小优先级越高
    val dependencies: List<String> = emptyList() // 依赖的其他插件
)

/**
 * 插件配置管理器
 * 管理所有插件的配置信息
 */
object PluginConfigManager {
    
    /**
     * 获取所有插件配置
     */
    fun getAllPluginConfigs(): List<PluginConfig> {
        return listOf(
            PluginConfig(
                pluginId = "barcode_scanner",
                className = "com.zijin.tj_tms_mobile.plugins.BarcodeScannerPlugin",
                enabled = true,
                priority = 1
            ),
            PluginConfig(
                pluginId = "uhf_scanner",
                className = "com.zijin.tj_tms_mobile.plugins.UHFPlugin",
                enabled = true,
                priority = 2
            )
        )
    }

    /**
     * 获取启用的插件配置
     */
    fun getEnabledPluginConfigs(): List<PluginConfig> {
        return getAllPluginConfigs().filter { it.enabled }
    }

    /**
     * 根据插件ID获取配置
     */
    fun getPluginConfig(pluginId: String): PluginConfig? {
        return getAllPluginConfigs().find { it.pluginId == pluginId }
    }

    /**
     * 检查插件是否启用
     */
    fun isPluginEnabled(pluginId: String): Boolean {
        return getPluginConfig(pluginId)?.enabled ?: false
    }
}