package com.zijin.tj_tms_mobile

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.os.Handler
import android.os.Looper
import android.util.Log

class ProcessGuardService : Service() {
    
    companion object {
        private const val TAG = "ProcessGuardService"
        private const val CHECK_INTERVAL = 30 * 1000L // 30秒检查一次
        
        fun startService(context: android.content.Context) {
            val intent = Intent(context, ProcessGuardService::class.java)
            context.startService(intent)
        }
        
        fun stopService(context: android.content.Context) {
            val intent = Intent(context, ProcessGuardService::class.java)
            context.stopService(intent)
        }
    }
    
    private val handler = Handler(Looper.getMainLooper())
    private val checkRunnable = object : Runnable {
        override fun run() {
            checkAndRestartServices()
            // 继续下一次检查
            handler.postDelayed(this, CHECK_INTERVAL)
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "ProcessGuardService创建")
        handler.post(checkRunnable)
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "ProcessGuardService启动")
        return START_STICKY // 服务被杀死后自动重启
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "ProcessGuardService销毁")
        handler.removeCallbacks(checkRunnable)
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    private fun checkAndRestartServices() {
        try {
            // 检查前台服务是否在运行
            if (!LocationForegroundService.isServiceRunning(this)) {
                Log.d(TAG, "检测到前台服务未运行，重新启动")
                LocationForegroundService.startService(this)
            }
            
            // 检查JobScheduler是否在运行
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                val jobScheduler = getSystemService(android.content.Context.JOB_SCHEDULER_SERVICE) as android.app.job.JobScheduler
                val jobs = jobScheduler.getAllPendingJobs()
                var hasKeepAliveJob = false
                for (job in jobs) {
                    if (job.id == KeepAliveJobService.JOB_ID) {
                        hasKeepAliveJob = true
                        break
                    }
                }
                
                if (!hasKeepAliveJob) {
                    Log.d(TAG, "检测到JobScheduler任务丢失，重新调度")
                    KeepAliveJobService.scheduleJob(this)
                }
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "检查服务状态时发生错误", e)
        }
    }
}