package com.example.tj_tms_mobile

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import com.rscja.barcode.BarcodeDecoder
import com.rscja.barcode.BarcodeFactory
import com.rscja.barcode.BarcodeUtility
import com.rscja.barcode.BarcodeSymbolUtility
import com.rscja.deviceapi.entity.BarcodeEntity
import com.example.tj_tms_mobile.plugin.Plugin

class BarcodeScannerPlugin(private val context: Context, private val engine: FlutterEngine) : Plugin {
    private val TAG = "BarcodeScannerPlugin"
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var isScanning = false
    private val barcodeFactory: BarcodeFactory by lazy { BarcodeFactory.getInstance() }
    private val barcodeDecoder: BarcodeDecoder by lazy { 
        Log.d(TAG, "初始化 BarcodeDecoder")
        barcodeFactory.getBarcodeDecoder().apply {
            // 打开扫描器
            val openResult = open(context)
            if (!openResult) {
                Log.e(TAG, "打开扫描器失败")
            }
        }
    }

    override val pluginId: String
        get() = "barcode_scanner"

    override fun getName(): String {
        return "BarcodeScannerPlugin"
    }

    override fun initialize() {
        try {
            // 配置BarcodeUtility
            configureBarcodeUtility()
            
            // 设置解码回调
            setupDecodeCallback()
            
            // 设置方法通道
            setupMethodChannel()
        } catch (e: Exception) {
            Log.e(TAG, "初始化条形码扫描插件失败", e)
            throw e
        }
    }

    private fun configureBarcodeUtility() {
        val utility = BarcodeUtility.getInstance()
        
        try {
            // 1. 基本配置
            // 清除前后缀，避免干扰
            utility.setPrefix(context, "")
            utility.setSuffix(context, "")
            Log.d(TAG, "基本配置完成")
            
            // 2. 反馈配置
            // 启用声音和震动反馈
            utility.enablePlaySuccessSound(context, true)
            utility.enablePlayFailureSound(context, true)
            utility.enableVibrate(context, true)
            Log.d(TAG, "反馈配置完成")
            
            // 3. 扫描模式配置
            // 启用连续扫描
            utility.enableContinuousScan(context, true)
            // 设置连续扫描间隔时间（毫秒）
            utility.setContinuousScanIntervalTime(context, 100)
            // 设置连续扫描超时时间（秒）
            utility.setContinuousScanTimeOut(context, 3)
            // 设置单次扫描超时时间（秒）
            utility.setScanOutTime(context, 2)
            Log.d(TAG, "扫描模式配置完成")
            
            // 4. 条码格式配置
            // 设置条码编码格式为UTF-8
            utility.setBarcodeEncodingFormat(context, 3)
            
            // 启用所有支持的条码格式
            // 使用自动适应模式，自动选择最佳扫描模式
            utility.open(context, BarcodeUtility.ModuleType.AUTOMATIC_ADAPTATION)
            Log.d(TAG, "条码格式配置完成")
            
            // 5. 输出模式配置
            // 设置为广播模式
            utility.setOutputMode(context, 2)
            // 设置扫描结果广播
            utility.setScanResultBroadcast(context, "com.example.tj_tms_mobile.SCAN_RESULT", "barcode")
            // 启用扫描失败广播
            utility.setScanFailureBroadcast(context, true)
            Log.d(TAG, "输出模式配置完成")
            
            // 6. 按键配置
            // 启用回车键
            utility.enableEnter(context, true)
            // 启用TAB键
            utility.enableTAB(context, true)
            // 设置松开按键停止扫描
            utility.setReleaseScan(context, true)
            Log.d(TAG, "按键配置完成")
            
            // 7. 数据过滤配置
            // 不重复显示相同条码
            utility.filterCharacter(context, "")
            Log.d(TAG, "数据过滤配置完成")
            
            // 8. 设置扫描头参数
            try {
                // 设置扫描头亮度等级（如果支持）
                utility.setParam_zebra(context, 4710, 3) // 中等亮度
                Log.d(TAG, "扫描头参数设置完成")
            } catch (e: Exception) {
                Log.w(TAG, "设置扫描头参数失败", e)
            }
        } catch (e: Exception) {
            Log.e(TAG, "配置扫描器失败", e)
            throw e
        }
    }
    
    private fun setupDecodeCallback() {
        try {
            // 设置扫描超时时间（秒）
            barcodeDecoder.setTimeOut(2)
            
            barcodeDecoder.setDecodeCallback(object : BarcodeDecoder.DecodeCallback {
                override fun onDecodeComplete(barcodeEntity: BarcodeEntity) {
                    when (barcodeEntity.resultCode) {
                        BarcodeDecoder.DECODE_SUCCESS -> {
                            try {
                                val barcodeData = barcodeEntity.barcodeData
                                // 先发送结果，再停止扫描
                                sendBarcodeResult(barcodeData)
                                // 停止扫描
                                barcodeDecoder.stopScan()
                            } catch (e: Exception) {
                                Log.e(TAG, "处理扫描结果失败", e)
                            }
                        }
                        BarcodeDecoder.DECODE_FAILURE -> {
                            Log.w(TAG, "扫描失败: 解码失败")
                            // 尝试重新开始扫描
                            restartScan()
                        }
                        BarcodeDecoder.DECODE_TIMEOUT -> {
                            Log.w(TAG, "扫描超时")
                            // 尝试重新开始扫描
                            restartScan()
                        }
                        BarcodeDecoder.DECODE_CANCEL -> {
                            Log.w(TAG, "扫描取消")
                        }
                        BarcodeDecoder.DECODE_ENGINE_ERROR -> {
                            Log.e(TAG, "扫描头错误")
                            // 尝试重新初始化扫描器
                            reinitializeScanner()
                        }
                        else -> {
                            Log.w(TAG, "扫描失败: 未知错误 ${barcodeEntity.resultCode}")
                            // 尝试重新开始扫描
                            restartScan()
                        }
                    }
                }
            })
        } catch (e: Exception) {
            Log.e(TAG, "设置解码回调失败", e)
            throw e
        }
    }

    private fun setupMethodChannel() {
        methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.example.tj_tms_mobile/barcode_scanner")
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startScan" -> {
                    try {
                        startScan()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SCAN_ERROR", "Failed to start scan: ${e.message}", null)
                    }
                }
                "stopScan" -> {
                    try {
                        stopScan()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SCAN_ERROR", "Failed to stop scan: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    fun setEventChannel(channel: EventChannel) {
        eventChannel = channel
        channel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    fun startScan() {
        if (isScanning) {
            Log.w(TAG, "扫描器已经在运行")
            return
        }

        try {
            isScanning = true
            // 检查扫描器状态
            if (!barcodeDecoder.isOpen()) {
                val openResult = barcodeDecoder.open(context)
                if (!openResult) {
                    throw Exception("Failed to open scanner")
                }
            }
            
            // 获取扫描器版本信息
            val versionInfo = barcodeDecoder.getDecoderSVersionInfo()
            
            // 开始扫描
            val startResult = barcodeDecoder.startScan()
            if (!startResult) {
                throw Exception("Failed to start scan")
            }
        } catch (e: Exception) {
            isScanning = false
            Log.e(TAG, "开始扫描失败", e)
            throw e
        }
    }

    // 停止扫描
    fun stopScan() {
        if (!isScanning) {
            Log.w(TAG, "扫描器未在运行")
            return
        }

        try {
            isScanning = false
            barcodeDecoder.stopScan()
        } catch (e: Exception) {
            Log.e(TAG, "停止扫描失败", e)
            throw e
        }
    }

    private fun restartScan() {
        try {
            stopScan()
            Thread.sleep(100) // 短暂延迟
            startScan()
        } catch (e: Exception) {
            Log.e(TAG, "重新开始扫描失败", e)
        }
    }

    // 尝试重新初始化扫描器
    private fun reinitializeScanner() {
        try {
            release()
            Thread.sleep(500) // 等待资源释放
            initialize()
        } catch (e: Exception) {
            Log.e(TAG, "重新初始化扫描器失败", e)
        }
    }

    private fun sendBarcodeResult(barcode: String) {
        try {
            eventSink?.success(barcode)
        } catch (e: Exception) {
            Log.e(TAG, "扫描失败", e)
        }
    }

    // 释放条形码扫描插件资源
    override fun release() {
        try {
            if (barcodeDecoder.isOpen()) {
                barcodeDecoder.close()
                Log.d(TAG, "扫描器已关闭")
            }
            methodChannel?.setMethodCallHandler(null)
            methodChannel = null
            eventChannel?.setStreamHandler(null)
            eventChannel = null
            eventSink = null
        } catch (e: Exception) {
            Log.e(TAG, "释放条形码扫描插件资源失败", e)
            throw e
        }
    }
} 