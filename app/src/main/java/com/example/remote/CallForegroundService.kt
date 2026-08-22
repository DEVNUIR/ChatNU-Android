package com.example.remote

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.example.ProductionMainActivity
import com.example.R

class CallForegroundService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Active calls", NotificationManager.IMPORTANCE_LOW).apply {
                    description = "Keeps active ChatNU calls connected"
                    setSound(null, null)
                }
            )
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        val peerName = intent?.getStringExtra(EXTRA_PEER_NAME).orEmpty().ifBlank { "ChatNU user" }
        val video = intent?.getBooleanExtra(EXTRA_VIDEO, false) == true
        val notification = buildNotification(peerName, video)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val type = ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE or
                if (video) ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA else 0
            startForeground(NOTIFICATION_ID, notification, type)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        return START_NOT_STICKY
    }

    private fun buildNotification(peerName: String, video: Boolean): Notification {
        val openApp = PendingIntent.getActivity(
            this,
            0,
            Intent(this, ProductionMainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_chatnu)
            .setContentTitle(if (video) "ChatNU video call" else "ChatNU voice call")
            .setContentText(peerName)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(openApp)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "chatnu_active_call"
        private const val NOTIFICATION_ID = 7402
        private const val ACTION_START = "ir.devnu.chatnu.START_CALL_SERVICE"
        private const val ACTION_STOP = "ir.devnu.chatnu.STOP_CALL_SERVICE"
        private const val EXTRA_PEER_NAME = "peer_name"
        private const val EXTRA_VIDEO = "video"

        fun start(context: Context, peerName: String, video: Boolean) {
            val intent = Intent(context, CallForegroundService::class.java)
                .setAction(ACTION_START)
                .putExtra(EXTRA_PEER_NAME, peerName)
                .putExtra(EXTRA_VIDEO, video)
            ContextCompat.startForegroundService(context, intent)
        }

        fun stop(context: Context) {
            context.startService(Intent(context, CallForegroundService::class.java).setAction(ACTION_STOP))
        }
    }
}
