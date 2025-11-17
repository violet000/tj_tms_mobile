package com.zijin.tj_tms_mobile.plugins

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.text.TextUtils
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import cn.cloudwalk.libproject.Builder
import cn.cloudwalk.libproject.LiveStartActivity
import cn.cloudwalk.libproject.callback.FrontDetectCallback
import cn.cloudwalk.libproject.callback.ResultPageCallback
import cn.cloudwalk.libproject.code.CwLiveCode
import cn.cloudwalk.libproject.config.CwLiveConfig
import cn.cloudwalk.libproject.entity.ErrorInfo
import cn.cloudwalk.libproject.entity.LiveInfo
import com.zijin.tj_tms_mobile.plugin.Plugin
import java.util.UUID
import org.json.JSONObject
import java.nio.charset.Charset
import org.bouncycastle.crypto.digests.SM3Digest
import org.bouncycastle.pqc.math.linearalgebra.ByteUtils
import cn.cloudwalk.faceanitspoofing.util.net.HttpManager
import cn.cloudwalk.util.entity.RequestData

/**
 * 云之盾活体人脸检测插件
 * 负责活体检测功能的实现
 */
class CloudwalkFacePlugin(
    private val context: Context,
    private val engine: FlutterEngine,
    private val activity: Activity
) : Plugin, PluginRegistry.ActivityResultListener {
    
    private val TAG = "CloudwalkFacePlugin"
    private var methodChannel: MethodChannel? = null
    private var resultCallback: MethodChannel.Result? = null
    
    // ==================== 固定配置项 ====================
    companion object {
        // 云从测试环境，平台服务器地址
        private const val DEFAULT_PRIVATE_PLATFORM_SERVER_IP = "https://mix02.cloudwalk.com"
        
        // 场景ID
        private const val DEFAULT_SCENE_ID = "300"
        
        // ACCESS_KEY 和 SECRET_KEY（用于获取Token和签名）
        private const val DEFAULT_ACCESS_KEY = "42dd618734fe4eeba5a458500cabf7ab"
        private const val DEFAULT_SECRET_KEY = "42500c8b9e0241dabab5735aaa8f182a"
        
        // 授权码
        private const val DEFAULT_LICENCE = "NTQ0NjE5bm9kZXZpY2Vjd2F1dGhvcml6ZbTm5+fm5+Lq/+bg5efm4uf74ufm4Obg5Yjm5uvl5ubrkeXm5uvl5uai6+Xm5uvl5uTm6+Xm5uDm1efr5+vn6+er4Ofr5+vn65/n5+Lm4ufl"
    }
    
    // 活体检测配置参数
    private var sessionId: String = ""
    private var actionSet: String = ""
    private var sdkParam: String = ""
    private var sceneId: String = DEFAULT_SCENE_ID  // 使用默认场景ID
    private var flowId: String = ""
    private var licence: String = DEFAULT_LICENCE   // 使用默认授权码
    
    // Token 相关
    private var accessToken: String = ""
    private var timestamp: String = ""
    private var nonce: String = ""
    private var signToken: String = ""
    
    override val pluginId: String
        get() = "cloudwalk_face"
    
    override fun getName(): String {
        return "CloudwalkFacePlugin"
    }
    
    override fun initialize() {
        try {
            setupMethodChannel()
            Log.d(TAG, "云之盾活体检测插件初始化完成")
        } catch (e: Exception) {
            Log.e(TAG, "初始化云之盾活体检测插件失败", e)
            throw e
        }
    }
    
    private fun setupMethodChannel() {
        methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.zijin.tj_tms_mobile/cloudwalk_face")
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startLiveDetection" -> {
                    try {
                        // 不需要传入配置，SDK会自动获取参数
                        startLiveDetection(result)
                    } catch (e: Exception) {
                        result.error("START_ERROR", "启动活体检测失败: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    
    /**
     * 生成 SM3 签名
     */
    private fun generateSignToken(): String {
        timestamp = System.currentTimeMillis().toString()
        nonce = UUID.randomUUID().toString().replace("-", "")
        val signStr = timestamp + nonce + accessToken + DEFAULT_SECRET_KEY
        
        return try {
            val srcData = signStr.toByteArray(Charset.forName("UTF-8"))
            val digest = SM3Digest()
            digest.update(srcData, 0, srcData.size)
            val hash = ByteArray(digest.digestSize)
            digest.doFinal(hash, 0)
            ByteUtils.toHexString(hash)
        } catch (e: Exception) {
            Log.e(TAG, "生成签名失败", e)
            ""
        }
    }
    
    /**
     * 获取 Token
     */
    private fun getAccessToken(callback: (Boolean) -> Unit) {
        val httpCallback = object : HttpManager.DataCallBack {
            override fun requestFailure(errorMsg: String?) {
                Log.e(TAG, "Token获取失败: $errorMsg")
                callback(false)
            }
            
            override fun requestSucess(jb: JSONObject?) {
                try {
                    accessToken = jb?.optString("access_token") ?: ""
                    if (TextUtils.isEmpty(accessToken)) {
                        Log.e(TAG, "Token获取失败：access_token为空")
                        callback(false)
                    } else {
                        Log.d(TAG, "Token获取成功")
                        Log.d(TAG, "accessToken: $accessToken")
                        callback(true)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "解析Token响应失败", e)
                    callback(false)
                }
            }
        }
        
        HttpManager.cwPlatformToken(
            DEFAULT_PRIVATE_PLATFORM_SERVER_IP,
            DEFAULT_ACCESS_KEY,
            DEFAULT_SECRET_KEY,
            httpCallback
        )
    }
    
    /**
     * 获取动作序列（SDK初始化）
     */
    private fun getActionSequence(callback: (Boolean) -> Unit) {
        flowId = UUID.randomUUID().toString().replace("-", "")
        // val bundleId = context.packageName
        val bundleId = "cn.cloudwalk.faceanitspoofing"
        
        signToken = generateSignToken()
        
        val httpCallback = object : HttpManager.DataCallBack {
            override fun requestFailure(errorMsg: String?) {
                Log.e(TAG, "SDK初始化失败: $errorMsg")
                callback(false)
            }
            
            override fun requestSucess(jb: JSONObject?) {
                try {
                    val code = jb?.optString("code") ?: ""
                    if (code == "00000000") {
                        val data = jb?.optJSONObject("data")
                        if (data != null) {
                            sessionId = data.optString("sessionId") ?: ""
                            actionSet = data.optString("actionSet") ?: ""
                            sdkParam = data.optString("sdkParam", "")
                            
                            if (!TextUtils.isEmpty(sessionId) && !TextUtils.isEmpty(actionSet)) {
                                Log.d(TAG, "SDK初始化成功: sessionId=$sessionId, actionSet=$actionSet")
                                callback(true)
                            } else {
                                Log.e(TAG, "SDK初始化失败：sessionId 或 actionSet 为空")
                                callback(false)
                            }
                        } else {
                            Log.e(TAG, "SDK初始化失败：响应data为空")
                            callback(false)
                        }
                    } else {
                        val message = jb?.optString("message") ?: "未知错误"
                        Log.e(TAG, "SDK初始化失败: code=$code, message=$message")
                        callback(false)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "解析SDK初始化响应失败", e)
                    callback(false)
                }
            }
        }
        
        val requestData = RequestData(
            RequestData.PublicParams(accessToken, timestamp, nonce, signToken),
            RequestData.ActionSequenceParams(flowId, sceneId, bundleId)
        )
        
        HttpManager.cwPlatformActionSequence(
            DEFAULT_PRIVATE_PLATFORM_SERVER_IP,
            requestData,
            httpCallback
        )
    }
    
    /**
     * 启动活体检测
     * SDK会自动获取Token和动作序列
     */
    private fun startLiveDetection(result: MethodChannel.Result) {
        try {
            // 保存结果回调
            resultCallback = result
            
            // 先获取Token，然后获取动作序列，最后启动检测
            getAccessToken { tokenSuccess ->
                if (!tokenSuccess) {
                    result.error("TOKEN_ERROR", "获取Token失败", null)
                    return@getAccessToken
                }
                
                getActionSequence { initSuccess ->
                    if (!initSuccess) {
                        result.error("INIT_ERROR", "SDK初始化失败", null)
                        return@getActionSequence
                    }
                    
                    // 启动活体检测
                    startLive()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "启动活体检测失败", e)
            result.error("START_ERROR", "启动活体检测失败: ${e.message}", null)
        }
    }
    
    /**
     * 启动活体检测Activity
     */
    private fun startLive() {
            
        // 创建活体检测配置
        val liveConfig = CwLiveConfig()
        liveConfig
            .saveLogoPath("") // 不保存日志
            .licence(licence)
            .platformActionSequence(actionSet)
            .platformSessionId(sessionId)
            .platformSceneId(sceneId)
            .platformFlowId(flowId)
            .paramString(sdkParam)
            .showFailResultPage(false)
            .checkScreen(true)
            .facing(android.hardware.Camera.CameraInfo.CAMERA_FACING_FRONT)
            .prepareStageTimeout(0)
            .actionStageTimeout(8000)
            .playSound(true)
            .showSuccessResultPage(false)
            .showReadyPage(true)
            .showFailRestartButton(true)
            .showSwitchCamera(false)
            .checkRuntimeEnvironment(true, false)
            .landscape(false, context)
            .frontDetectCallback(frontDetectCallback)
            .resultPageCallback(resultPageCallback)
            .locale(java.util.Locale.SIMPLIFIED_CHINESE)
            .encryptType(0)
            .actionDonePlayVoice(true)
            .actionInconsistentInterrupt(false)
            .openLightInterrupt(false)
            .setHttpProxyInterrupt(false)
        
        // 设置全局配置（必须在启动Activity之前调用）
        Builder.setCwLiveConfig(liveConfig)
        
        // 启动活体检测Activity
        val intent = Intent(context, LiveStartActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        
        Log.d(TAG, "活体检测已启动")
    }
    
    /**
     * 前端检测回调
     */
    private val frontDetectCallback = object : FrontDetectCallback {
        override fun onLivenessSuccess(liveInfo: LiveInfo?) {
            Log.d(TAG, "活体检测成功")
            
            if (liveInfo == null || TextUtils.isEmpty(liveInfo.hackParams)) {
                // 失败
                Builder.setFaceResult(context, 0)
                sendResult(false, "检测失败：返回数据为空", null)
                return
            }
            
            // 成功
            Builder.setFaceResult(context, 1)
            
            val resultData = mapOf(
                "success" to true,
                "hackParams" to (liveInfo.hackParams ?: ""),
                "encryptWorkKey" to (liveInfo.encryptWorkKey ?: ""),
                "publicKeyIndex" to (liveInfo.publicKeyIndex ?: ""),
                "summary" to (liveInfo.summary ?: ""),
                "bestFace" to (liveInfo.bestFace?.let { 
                    android.util.Base64.encodeToString(it, android.util.Base64.NO_WRAP)
                } ?: ""),
                "clipedBestFace" to (liveInfo.clipedBestFace?.let {
                    android.util.Base64.encodeToString(it, android.util.Base64.NO_WRAP)
                } ?: "")
            )
            
            sendResult(true, "检测成功", resultData)
        }
        
        override fun onLivenessFail(errorInfo: ErrorInfo?) {
            val errorCode = errorInfo?.errorCode ?: CwLiveCode.FAIL
            val errorMsg = errorInfo?.errorMsg ?: CwLiveCode.getMessageByCode(errorCode)
            
            Log.e(TAG, "活体检测失败: code=$errorCode, msg=$errorMsg")
            
            val resultData = mapOf(
                "success" to false,
                "errorCode" to errorCode,
                "errorMsg" to errorMsg,
                "hackParams" to (errorInfo?.hackParams ?: ""),
                "encryptWorkKey" to (errorInfo?.encryptWorkKey ?: ""),
                "publicKeyIndex" to (errorInfo?.publicKeyIndex ?: ""),
                "summary" to (errorInfo?.summary ?: "")
            )
            
            sendResult(false, errorMsg, resultData)
        }
        
        override fun onLivenessCancel(resultCode: Int) {
            val msg = CwLiveCode.getMessageByCode(resultCode)
            Log.d(TAG, "活体检测取消: code=$resultCode, msg=$msg")
            
            val resultData = mapOf(
                "success" to false,
                "errorCode" to resultCode,
                "errorMsg" to msg,
                "cancelled" to true
            )
            
            sendResult(false, msg, resultData)
        }
    }
    
    /**
     * 结果页面回调
     */
    private val resultPageCallback = object : ResultPageCallback {
        override fun onResultPageFinish(pageType: Int, resultCode: Int) {
            Log.d(TAG, "结果页面回调: pageType=$pageType, resultCode=$resultCode")
            // 这里可以根据需要处理结果页面的回调
        }
    }
    
    /**
     * 发送结果到Flutter
     */
    private fun sendResult(success: Boolean, message: String, data: Map<String, Any>?) {
        try {
            val result = mapOf(
                "success" to success,
                "message" to message,
                "data" to (data ?: emptyMap<String, Any>())
            )
            
            resultCallback?.success(result)
            resultCallback = null
        } catch (e: Exception) {
            Log.e(TAG, "发送结果失败", e)
        }
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        // 如果需要处理Activity结果，可以在这里处理
        return false
    }
    
    override fun release() {
        try {
            methodChannel?.setMethodCallHandler(null)
            methodChannel = null
            resultCallback = null
            Log.d(TAG, "云之盾活体检测插件资源已释放")
        } catch (e: Exception) {
            Log.e(TAG, "释放云之盾活体检测插件资源失败", e)
        }
    }
}

