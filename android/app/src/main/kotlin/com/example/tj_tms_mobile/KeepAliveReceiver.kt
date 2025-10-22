package com.example.tj_tms_mobile

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class KeepAliveReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "KeepAliveReceiver"
        private const val ACTION_KEEP_ALIVE = "com.example.tj_tms_mobile.KEEP_ALIVE"
        private const val REQUEST_CODE = 1001
        
        fun scheduleAlarm(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, KeepAliveReceiver::class.java).apply {
                action = ACTION_KEEP_ALIVE
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            // 设置重复闹钟，每30分钟执行一次
            val intervalMillis = 30 * 60 * 1000L // 30分钟
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    System.currentTimeMillis() + intervalMillis,
                    pendingIntent
                )
            } else {
                alarmManager.setRepeating(
                    AlarmManager.RTC_WAKEUP,
                    System.currentTimeMillis() + intervalMillis,
                    intervalMillis,
                    pendingIntent
                )
            }
            
            Log.d(TAG, "AlarmManager已设置")
        }
        
        fun cancelAlarm(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, KeepAliveReceiver::class.java).apply {
                action = ACTION_KEEP_ALIVE
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            alarmManager.cancel(pendingIntent)
            Log.d(TAG, "AlarmManager已取消")
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_KEEP_ALIVE) {
            Log.d(TAG, "KeepAliveReceiver被触发")
            
            // 检查前台服务是否在运行
            if (!LocationForegroundService.isServiceRunning(context)) {
                Log.d(TAG, "前台服务未运行，重新启动")
                LocationForegroundService.startService(context)
            }
            
            // 重新设置下一次闹钟
            scheduleAlarm(context)
        }
    }
}