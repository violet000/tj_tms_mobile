package com.example.tj_tms_mobile.plugins

import android.content.Context
import android.util.Log

class LivenessDetectionHelper {
    companion object {
        private const val TAG = "LivenessDetectionHelper"

        fun startLive(context: Context, config: Map<String, Any?>) {
            Log.d(TAG, "Starting liveness with config keys: ${config.keys}")

            // 使用反射以避免在编译期强依赖 SDK，保证工程可编译
            try {
                val cwLiveConfigClazz = Class.forName("cn.cloudwalk.libproject.config.CwLiveConfig")
                val configInstance = cwLiveConfigClazz.getDeclaredConstructor().newInstance()

                fun callChain(methodName: String, vararg args: Any?) {
                    try {
                        val argTypes = args.map { it?.javaClass ?: Any::class.java }.toTypedArray()
                        val method = cwLiveConfigClazz.methods.firstOrNull { m ->
                            m.name == methodName && m.parameterTypes.size == argTypes.size
                        }
                        method?.invoke(configInstance, *args)
                    } catch (e: Exception) {
                        Log.w(TAG, "Invoke $methodName failed: ${e.message}")
                    }
                }

                // 基础配置
                (config["license"] as? String)?.let { callChain("licence", it) }
                (config["packageLicense"] as? String)?.let { callChain("packageLicence", it) }

                // 可选配置映射
                (config["facing"] as? Int)?.let { callChain("facing", it) }
                (config["flashType"] as? Int)?.let { callChain("flashType", it) }
                (config["hackMode"] as? Int)?.let { callChain("hackMode", it) }
                (config["actionCount"] as? Int)?.let { callChain("actionCount", it) }
                (config["randomAction"] as? Int)?.let { callChain("randomAction", it) }
                (config["mustBlink"] as? Boolean)?.let { callChain("mustBlink", it) }
                (config["prepareStageTimeout"] as? Int)?.let { callChain("prepareStageTimeout", it) }
                (config["actionStageTimeout"] as? Int)?.let { callChain("actionStageTimeout", it) }
                (config["playSound"] as? Boolean)?.let { callChain("playSound", it) }
                (config["showReadyPage"] as? Boolean)?.let { callChain("showReadyPage", it) }
                (config["showSuccessResultPage"] as? Boolean)?.let { callChain("showSuccessResultPage", it) }
                (config["showFailResultPage"] as? Boolean)?.let { callChain("showFailResultPage", it) }
                (config["saveLogPath"] as? String)?.let { callChain("saveLogPath", it) }
                (config["imageCompressionRatio"] as? Int)?.let { callChain("imageCompressionRatio", it) }
                (config["maxHackParamSize"] as? Int)?.let { callChain("maxHackParamSize", it) }
                (config["pageWidth"] as? Int)?.let { callChain("pageWidth", it) }

                // 语言配置: 仅在传入字符串时尝试设置
                (config["local"] as? String)?.let { localeStr ->
                    try {
                        val localeClazz = Class.forName("java.util.Locale")
                        val locale = when (localeStr.lowercase()) {
                            "zh_cn", "zh" -> localeClazz.getField("CHINA").get(null)
                            "zh_tw" -> localeClazz.getField("TAIWAN").get(null)
                            else -> localeClazz.getField("US").get(null)
                        }
                        val method = cwLiveConfigClazz.getMethod("pageWidth", localeClazz)
                        method.invoke(configInstance, locale)
                    } catch (e: Exception) {
                        Log.w(TAG, "Set locale failed: ${e.message}")
                    }
                }

                // 平台/基础版相关
                (config["platformActionSequence"] as? String)?.let { callChain("platformActionSequence", it) }
                (config["platformSessionId"] as? String)?.let { callChain("platformSessionId", it) }
                (config["platformSceneId"] as? String)?.let { callChain("platformSceneId", it) }
                (config["platformFlowId"] as? String)?.let { callChain("platformFlowId", it) }

                (config["showMaskImage"] as? Boolean)?.let { callChain("showMaskImage", it) }
                (config["maskImageResourceId"] as? Int)?.let { callChain("maskImageResourceId", it) }
                (config["openActionDetectConsistent"] as? Boolean)?.let { callChain("openActionDetectConsistent", it) }
                (config["actionInconsistentInterrupt"] as? Boolean)?.let { callChain("actionInconsistentInterrupt", it) }
                (config["showSwitchCamera"] as? Boolean)?.let { callChain("showSwitchCamera", it) }

                // 启动页面/检测页面（尝试反射）
                try {
                    val startClassName = config["liveStartActivityClass"] as? String
                    val liveClassName = config["liveActivityClass"] as? String
                    val startActivityMethod = when {
                        !startClassName.isNullOrBlank() && !liveClassName.isNullOrBlank() -> {
                            val readyClazz = Class.forName(startClassName)
                            val liveClazz = Class.forName(liveClassName)
                            cwLiveConfigClazz.getMethod("startActivity", Context::class.java, Class::class.java, Class::class.java, android.os.Bundle::class.java)
                                .also {
                                    it.invoke(configInstance, context, readyClazz, liveClazz, null)
                                }
                        }
                        else -> {
                            // 单参版本，尽力尝试
                            val fallbackClazzName = config["activityClass"] as? String ?: "cn.cloudwalk.livesActivity"
                            val fallbackClazz = Class.forName(fallbackClazzName)
                            cwLiveConfigClazz.getMethod("startActivity", Context::class.java, Class::class.java)
                                .also {
                                    it.invoke(configInstance, context, fallbackClazz)
                                }
                        }
                    }
                    Log.d(TAG, "Invoked startActivity: $startActivityMethod")
                } catch (e: Exception) {
                    Log.w(TAG, "startActivity invoke failed: ${e.message}")
                }
            } catch (e: ClassNotFoundException) {
                Log.e(TAG, "Cloudwalk SDK not found: ${e.message}")
            } catch (e: Exception) {
                Log.e(TAG, "Unexpected error starting liveness: ${e.message}", e)
            }
        }
    }
} 