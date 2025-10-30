package com.zijin.tj_tms_mobile

import android.app.*
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import android.content.pm.ServiceInfo
import android.content.Context

class LocationForegroundService : Service() {
    
    private var wakeLock: PowerManager.WakeLock? = null
    
    companion object {
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "location_service_channel"
        private const val CHANNEL_NAME = "位置服务"
        
        fun startService(context: Context) {
            val intent = Intent(context, LocationForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stopService(context: Context) {
            val intent = Intent(context, LocationForegroundService::class.java)
            context.stopService(intent)
        }
        
        fun isServiceRunning(context: Context): Boolean {
            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
            val runningServices = activityManager.getRunningServices(Integer.MAX_VALUE)
            for (serviceInfo in runningServices) {
                if (LocationForegroundService::class.java.name == serviceInfo.service.className) {
                    return true
                }
            }
            return false
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        acquireWakeLock()
        // 启动JobScheduler保活任务
        KeepAliveJobService.scheduleJob(this)
        // 启动AlarmManager保活任务
        KeepAliveReceiver.scheduleAlarm(this)
        // 启动进程守护服务
        ProcessGuardService.startService(this)
        // 提前在 onCreate 即前台化，避免主线程在 onStartCommand 调度前被阻塞导致超时
        try {
            val notification = createNotification()
            // 使用兼容API在支持的平台上显式声明前台服务类型（位置）
            val typeFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            } else {
                0
            }
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                notification,
                typeFlag
            )
        } catch (_: Exception) {
            // 忽略，onStartCommand 中还有一次兜底
        }
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            val notification = createNotification()
            // 确保在最早时机前台化，避免 5 秒超时崩溃
            val typeFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            } else {
                0
            }
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                notification,
                typeFlag
            )
        } catch (e: Exception) {
            // 安全停止，避免系统抛异常
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }
    
    override fun onDestroy() {
        super.onDestroy()
        releaseWakeLock()
        // 取消JobScheduler保活任务
        KeepAliveJobService.cancelJob(this)
        // 取消AlarmManager保活任务
        KeepAliveReceiver.cancelAlarm(this)
        // 停止进程守护服务
        ProcessGuardService.stopService(this)
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                // 使用 DEFAULT 提升显示优先级，确保息屏时可见
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "用于保持位置服务在后台运行"
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            // 标题使用应用名称
            .setContentTitle("天津银行外勤配送系统")
            .setContentText("正在后台运行（定位服务中）")
            .setSubText("持续定位用于天津银行外勤配送系统")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
    
    private fun acquireWakeLock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "LocationForegroundService::WakeLock"
            )
            wakeLock?.acquire(10*60*1000L /*10 minutes*/)
        } catch (e: Exception) {
            // WakeLock获取失败，不影响服务运行
        }
    }
    
    private fun releaseWakeLock() {
        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                }
            }
            wakeLock = null
        } catch (e: Exception) {
            // WakeLock释放失败
        }
    }
} 