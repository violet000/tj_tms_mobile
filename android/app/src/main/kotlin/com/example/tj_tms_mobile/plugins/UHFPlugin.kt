package com.example.tj_tms_mobile.plugins

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import com.rscja.deviceapi.RFIDWithUHFUART
import com.rscja.deviceapi.entity.UHFTAGInfo
import com.rscja.deviceapi.interfaces.IUHFInventoryCallback
import com.example.tj_tms_mobile.plugin.Plugin
import com.rscja.deviceapi.interfaces.IUHF
import java.util.Collections

/**
 * UHF RFID扫描插件
 * 负责UHF RFID标签的扫描、写入、锁定、销毁等功能
 */
class UHFPlugin(private val context: Context, private val engine: FlutterEngine) : Plugin {
    private val TAG = "UHFPlugin"
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var isScanning = false
    private var mReader: RFIDWithUHFUART? = null
    private val tagList = mutableListOf<String>()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val scannedTags = mutableListOf<UHFTAGInfo>()
    private val pendingTags = mutableListOf<UHFTAGInfo>()

    override val pluginId: String
        get() = "uhf_scanner"

    override fun getName(): String {
        return "UHFPlugin"
    }

    override fun initialize() {
        try {
            Log.d(TAG, "Starting UHF reader initialization")
            mReader = RFIDWithUHFUART.getInstance()
            if (mReader == null) {
                Log.e(TAG, "Failed to get UHF reader instance")
                return
            }
            Log.d(TAG, "Got UHF reader instance, attempting initialization")
            val success = mReader?.init(context) ?: false
            Log.d(TAG, "UHF reader initialization result: $success")
            if (success) {
                Log.d(TAG, "UHF reader initialized successfully")
                try {
                    Log.d(TAG, "Setting UHF reader power to 30")
                    val powerSuccess = mReader?.setPower(30) ?: false
                    Log.d(TAG, "Power setting result: $powerSuccess")
                    if (!powerSuccess) {
                        Log.e(TAG, "Failed to set power")
                    }
                    
                    Log.d(TAG, "Setting frequency mode to 0x02")
                    val freqSuccess = mReader?.setFrequencyMode(0x02) ?: false
                    Log.d(TAG, "Frequency mode setting result: $freqSuccess")
                    if (!freqSuccess) {
                        Log.e(TAG, "Failed to set frequency mode")
                    }
                    
                    Log.d(TAG, "Setting EPC mode")
                    val epcSuccess = mReader?.setEPCMode() ?: false
                    Log.d(TAG, "EPC mode setting result: $epcSuccess")
                    if (!epcSuccess) {
                        Log.e(TAG, "Failed to set EPC mode")
                    }
                    
                    if (powerSuccess && freqSuccess && epcSuccess) {
                        Log.d(TAG, "UHF reader configured successfully")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error during UHF configuration", e)
                    e.printStackTrace()
                }
                setupChannels()
            } else {
                Log.e(TAG, "Failed to initialize UHF reader")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize UHF plugin", e)
            e.printStackTrace()
        }
    }

    private fun setupChannels() {
        // Setup MethodChannel
        methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.example.tj_tms_mobile/uhf_scanner")
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "init" -> {
                    try {
                        Log.d(TAG, "Received init method call from Flutter")
                        if (mReader == null) {
                            Log.e(TAG, "UHF reader is null during init")
                            result.error("INIT_ERROR", "UHF reader is null", null)
                            return@setMethodCallHandler
                        }
                        val success = mReader?.init(context) ?: false
                        Log.d(TAG, "UHF reader initialization result: $success")
                        result.success(success)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error during initialization", e)
                        result.error("INIT_ERROR", e.message, null)
                    }
                }
                "free" -> {
                    try {
                        mReader?.free()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("FREE_ERROR", e.message, null)
                    }
                }
                "startScan" -> {
                    try {
                        if (mReader == null) {
                            Log.e(TAG, "UHF reader is null during startScan")
                            result.error("SCAN_ERROR", "UHF reader is null", null)
                            return@setMethodCallHandler
                        }

                        if (!isScanning) {
                            Log.d(TAG, "Starting scan")
                            isScanning = true
                            tagList.clear()
                            scannedTags.clear()
                            pendingTags.clear()
                            
                            try {
                                mReader?.setInventoryCallback(null)
                                
                                mReader?.setInventoryCallback(object : IUHFInventoryCallback {
                                    override fun callback(tagInfo: UHFTAGInfo) {
                                        if (tagInfo != null) {
                                            val epc = tagInfo.epc
                                            if (!epc.isNullOrEmpty() && !tagList.contains(epc)) {
                                                Log.d(TAG, "Scanned tag: $epc, RSSI: ${tagInfo.rssi}")
                                                val tagData = hashMapOf<String, Any>(
                                                    "epc" to epc, // 标签的EPC号
                                                    "rssi" to tagInfo.rssi, // 标签的RSSI值
                                                    "tid" to (tagInfo.tid ?: ""), // 标签的TID号
                                                    "user" to (tagInfo.user ?: ""), // 标签的用户数据
                                                    "timestamp" to System.currentTimeMillis() // 当前时间戳
                                                )
                                                Log.d(TAG, "Sending tag data to Flutter: $tagData")
                                                mainHandler.post {
                                                    eventSink?.success(tagData)
                                                    Log.d(TAG, "Tag data sent to Flutter successfully")
                                                }
                                                tagList.add(epc)
                                            }
                                        }
                                    }
                                })
                                
                                val success = mReader?.startInventoryTag() ?: false
                                if (!success) {
                                    Log.e(TAG, "Failed to start inventory")
                                    result.error("SCAN_ERROR", "Failed to start inventory", null)
                                    return@setMethodCallHandler
                                }
                                Log.d(TAG, "Started inventory successfully")
                            } catch (e: Exception) {
                                Log.e(TAG, "Error during scan setup", e)
                                e.printStackTrace()
                                result.error("SCAN_ERROR", e.message, null)
                                return@setMethodCallHandler
                            }
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error during scan", e)
                        e.printStackTrace()
                        result.error("SCAN_ERROR", e.message, null)
                    }
                }
                "stopScan" -> {
                    try {
                        if (isScanning) {
                            Log.d(TAG, "Stopping scan")
                            mReader?.stopInventory()
                            mReader?.setInventoryCallback(null)
                            isScanning = false
                            Log.d(TAG, "Scan stopped successfully")
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error during stop scan", e)
                        e.printStackTrace()
                        result.error("STOP_SCAN_ERROR", e.message, null)
                    }
                }
                "writeTag" -> {
                    try {
                        val epc = call.argument<String>("epc") ?: ""
                        val data = call.argument<String>("data") ?: ""
                        val success = mReader?.writeDataToEpc("00000000", data) ?: false
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("WRITE_TAG_ERROR", e.message, null)
                    }
                }
                "lockTag" -> {
                    try {
                        val epc = call.argument<String>("epc") ?: ""
                        val lockCode = mReader?.generateLockCode(arrayListOf(IUHF.LockBank_EPC), IUHF.LockMode_LOCK)
                        val success = if (lockCode != null) {
                            mReader?.lockMem("00000000", lockCode) ?: false
                        } else {
                            false
                        }
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("LOCK_TAG_ERROR", e.message, null)
                    }
                }
                "killTag" -> {
                    try {
                        val epc = call.argument<String>("epc") ?: ""
                        val success = mReader?.killTag(epc) ?: false
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("KILL_TAG_ERROR", e.message, null)
                    }
                }
                "setPower" -> {
                    try {
                        val power = call.argument<Int>("power") ?: 30
                        val success = mReader?.setPower(power) ?: false
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("SET_POWER_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Setup EventChannel
        eventChannel = EventChannel(engine.dartExecutor.binaryMessenger, "com.example.tj_tms_mobile/uhf_scanner_events")
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                Log.d(TAG, "EventChannel onListen called")
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                Log.d(TAG, "EventChannel onCancel called")
                eventSink = null
            }
        })
    }

    fun setEventChannel(channel: EventChannel) {
        eventChannel = channel
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                Log.d(TAG, "EventChannel onListen called")
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                Log.d(TAG, "EventChannel onCancel called")
                eventSink = null
            }
        })
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    override fun release() {
        try {
            mReader?.free()
            methodChannel?.setMethodCallHandler(null)
            eventChannel?.setStreamHandler(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to release UHF plugin", e)
        }
    }
}