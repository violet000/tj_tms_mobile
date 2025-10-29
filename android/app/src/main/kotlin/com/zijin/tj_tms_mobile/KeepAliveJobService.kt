package com.zijin.tj_tms_mobile

import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.util.Log

/**
 * 应用保活JobService
 * 使用JobScheduler机制来保持应用活跃状态
 */
class KeepAliveJobService : JobService() {
    
    companion object {
        private const val TAG = "KeepAliveJobService"
        const val JOB_ID = 1001
        
        /**
         * 调度保活任务
         */
        fun scheduleJob(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
                Log.w(TAG, "JobScheduler not supported on this Android version")
                return
            }
            
            val jobScheduler = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler
            
            // 取消之前的任务
            jobScheduler.cancel(JOB_ID)
            
            val jobInfo = JobInfo.Builder(
                JOB_ID,
                ComponentName(context, KeepAliveJobService::class.java)
            ).apply {
                // 设置网络要求
                setRequiredNetworkType(JobInfo.NETWORK_TYPE_NONE)
                // 设置设备空闲时执行
                setRequiresDeviceIdle(false)
                // 设置充电时执行
                setRequiresCharging(false)
                // 设置电池不优化
                setRequiresBatteryNotLow(false)
                // 设置重复执行，间隔15分钟
                setPeriodic(15 * 60 * 1000) // 15分钟
                // 设置持久化
                setPersisted(true)
            }.build()
            
            val result = jobScheduler.schedule(jobInfo)
            if (result == JobScheduler.RESULT_SUCCESS) {
                Log.d(TAG, "JobScheduler任务调度成功")
            } else {
                Log.e(TAG, "JobScheduler任务调度失败")
            }
        }
        
        /**
         * 取消保活任务
         */
        fun cancelJob(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
                Log.w(TAG, "JobScheduler not supported on this Android version")
                return
            }
            
            val jobScheduler = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler
            jobScheduler.cancel(JOB_ID)
            Log.d(TAG, "JobScheduler任务已取消")
        }
    }
    
    override fun onStartJob(params: JobParameters?): Boolean {
        Log.d(TAG, "KeepAliveJobService onStartJob")
        
        // 检查前台服务是否在运行
        if (!LocationForegroundService.isServiceRunning(this)) {
            Log.d(TAG, "前台服务未运行，重新启动")
            LocationForegroundService.startService(this)
        }
        
        // 检查AlarmManager是否在运行
        try {
            KeepAliveReceiver.scheduleAlarm(this)
        } catch (e: Exception) {
            Log.e(TAG, "重新设置AlarmManager失败", e)
        }
        
        // 任务执行完成
        jobFinished(params, false)
        return true
    }
    
    override fun onStopJob(params: JobParameters?): Boolean {
        Log.d(TAG, "KeepAliveJobService onStopJob")
        // 返回false表示不需要重新调度
        return false
    }
}