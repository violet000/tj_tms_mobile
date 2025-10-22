package com.example.tj_tms_mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                Log.d(TAG, "设备启动完成，重新启动保活服务")
                
                // 延迟启动服务，确保系统完全启动
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    try {
                        // 启动前台服务
                        LocationForegroundService.startService(context)
                        Log.d(TAG, "开机自启动：前台服务已启动")
                        
                        // 重新调度JobScheduler
                        KeepAliveJobService.scheduleJob(context)
                        Log.d(TAG, "开机自启动：JobScheduler已重新调度")
                        
                        // 重新设置AlarmManager
                        KeepAliveReceiver.scheduleAlarm(context)
                        Log.d(TAG, "开机自启动：AlarmManager已重新设置")
                        
                    } catch (e: Exception) {
                        Log.e(TAG, "开机自启动服务失败", e)
                    }
                }, 5000) // 延迟5秒
            }
        }
    }
}