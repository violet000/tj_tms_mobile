# 插件管理系统

## 概述

本插件管理系统提供了一个统一、规范的方式来管理Flutter应用中的原生插件。通过分层架构和清晰的职责划分，使得插件的开发、注册和维护更加简单高效。

## 目录结构

```
com/example/tj_tms_mobile/
├── plugin/                          # 插件核心框架
│   ├── Plugin.kt                    # 插件接口定义
│   ├── PluginManager.kt             # 插件管理器
│   ├── PluginFactory.kt             # 插件工厂
│   ├── PluginConfig.kt              # 插件配置管理
│   └── README.md                    # 本文档
├── plugins/                         # 具体插件实现
│   ├── BarcodeScannerPlugin.kt      # 条形码扫描插件
│   └── (其他插件...)
└── MainActivity.kt                  # 主Activity
```

## 核心组件

### 1. Plugin 接口

所有插件必须实现的基础接口，定义了插件的生命周期方法。

```kotlin
interface Plugin {
    val pluginId: String            // 插件唯一标识
    fun getName(): String           // 获取插件名称
    fun initialize()                // 初始化插件
    fun release()                   // 释放插件资源
}
```

### 2. PluginManager 插件管理器

负责插件的注册、初始化和生命周期管理。

**主要功能：**
- 注册和管理插件实例
- 注册和管理事件通道
- 统一初始化所有插件
- 统一释放所有插件资源
- 提供插件查询功能

**关键方法：**
```kotlin
// 注册插件
fun registerPlugin(pluginId: String, plugin: Plugin)

// 注册事件通道
fun registerEventChannel(channelName: String, eventChannel: EventChannel)

// 初始化所有插件
fun initializePlugins()

// 释放所有插件
fun releasePlugins()

// 获取插件实例
fun getPlugin(pluginId: String): Plugin?
```

### 3. PluginFactory 插件工厂

负责创建和配置各种插件实例，封装插件的创建逻辑。

**主要功能：**
- 创建各类插件实例
- 配置插件的事件通道
- 统一管理插件的创建流程

**关键方法：**
```kotlin
// 创建条形码扫描插件
fun createBarcodeScannerPlugin(): BarcodeScannerPlugin

// 创建UHF插件
fun createUHFPlugin(): UHFPlugin

// 设置条形码扫描插件的事件通道
fun setupBarcodeScannerEventChannel(plugin: BarcodeScannerPlugin): EventChannel
```

### 4. PluginConfig 插件配置

管理插件的配置信息，支持插件的启用/禁用、优先级设置等。

**配置项：**
```kotlin
data class PluginConfig(
    val pluginId: String,           // 插件ID
    val className: String,          // 插件类名
    val enabled: Boolean = true,    // 是否启用
    val priority: Int = 0,          // 优先级（数字越小优先级越高）
    val dependencies: List<String> = emptyList() // 依赖的其他插件
)
```

## 使用指南

### 添加新插件

#### 1. 实现插件接口

在 `plugins/` 目录下创建新的插件类，实现 `Plugin` 接口：

```kotlin
package com.zijin.tj_tms_mobile.plugins

import com.zijin.tj_tms_mobile.plugin.Plugin

class MyPlugin(private val context: Context, private val engine: FlutterEngine) : Plugin {
    override val pluginId: String = "my_plugin"
    
    override fun getName(): String = "MyPlugin"
    
    override fun initialize() {
        // 初始化插件逻辑
    }
    
    override fun release() {
        // 释放资源逻辑
    }
}
```

#### 2. 在PluginFactory中添加创建方法

```kotlin
fun createMyPlugin(): MyPlugin {
    Log.d(TAG, "Creating MyPlugin...")
    return MyPlugin(context, engine)
}
```

#### 3. 在PluginConfig中注册配置

```kotlin
fun getAllPluginConfigs(): List<PluginConfig> {
    return listOf(
        // ...现有插件配置
        PluginConfig(
            pluginId = "my_plugin",
            className = "com.zijin.tj_tms_mobile.plugins.MyPlugin",
            enabled = true,
            priority = 3
        )
    )
}
```

#### 4. 在MainActivity中注册插件

```kotlin
private fun initializePlugins(flutterEngine: FlutterEngine) {
    // ...现有代码
    
    // 创建并注册新插件
    val myPlugin = pluginFactory.createMyPlugin()
    pluginManager.registerPlugin("my_plugin", myPlugin)
}
```

### 管理插件生命周期

插件的生命周期由 `PluginManager` 统一管理：

1. **注册阶段**：在 `MainActivity.initializePlugins()` 中注册插件
2. **初始化阶段**：调用 `pluginManager.initializePlugins()` 初始化所有插件
3. **运行阶段**：插件正常工作
4. **释放阶段**：在 `MainActivity.onDestroy()` 中自动释放所有插件资源

## 最佳实践

### 1. 插件设计原则

- **单一职责**：每个插件只负责一个特定功能
- **低耦合**：插件之间应该相互独立，避免直接依赖
- **高内聚**：插件内部逻辑应该紧密相关

### 2. 资源管理

- 在 `initialize()` 中初始化资源
- 在 `release()` 中释放所有资源
- 使用 try-catch 确保异常不会影响其他插件

### 3. 日志规范

```kotlin
private val TAG = "PluginName"

Log.d(TAG, "正常日志信息")
Log.w(TAG, "警告信息")
Log.e(TAG, "错误信息", exception)
```

### 4. 事件通道管理

- 通过 `PluginFactory` 统一创建和配置事件通道
- 在插件的 `release()` 方法中清理事件监听器
- 使用 `EventSink` 向Flutter端发送事件

## 优势

1. **统一管理**：所有插件通过统一的接口和管理器进行管理
2. **易于扩展**：添加新插件只需实现接口并注册即可
3. **职责清晰**：各组件职责明确，代码结构清晰
4. **便于维护**：插件独立开发和测试，互不影响
5. **资源安全**：统一的生命周期管理确保资源正确释放

## 已注册插件

| 插件ID | 插件名称 | 功能描述 | 优先级 |
|--------|---------|---------|--------|
| barcode_scanner | BarcodeScannerPlugin | 条形码扫描 | 1 |
| uhf_scanner | UHFPlugin | UHF RFID扫描 | 2 |

## 注意事项

1. 插件ID必须全局唯一
2. 不要在插件的构造函数中执行耗时操作
3. 确保在 `release()` 方法中正确释放所有资源
4. 插件初始化失败不应导致应用崩溃
5. 使用线程池处理耗时操作，避免阻塞主线程
