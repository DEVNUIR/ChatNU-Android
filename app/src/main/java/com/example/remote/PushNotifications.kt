package com.example.remote

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.example.ProductionMainActivity
import com.example.R
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

object PushRegistration {
    fun refresh(context: Context, authRepository: RemoteAuthRepository) {
        if (FirebaseApp.getApps(context).isEmpty()) return
        FirebaseMessaging.getInstance().token.addOnSuccessListener { token ->
            CoroutineScope(SupervisorJob() + Dispatchers.IO).launch {
                runCatching { authRepository.registerPushToken(token) }
            }
        }
    }
}

class ChatNuMessagingService : FirebaseMessagingService() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onNewToken(token: String) {
        val tokenStore = TokenStore(applicationContext)
        if (tokenStore.accessToken.isNullOrBlank()) return
        val apiClient = ApiClient(tokenStore)
        scope.launch {
            runCatching { apiClient.api.updatePushToken(PushTokenRequest(token)) }
        }
    }

    override fun onMessageReceived(message: RemoteMessage) {
        val type = message.data["type"] ?: return
        when (type) {
            "message" -> notifyEncryptedMessage(message.data)
            "call" -> notifyIncomingCall(message.data)
        }
    }

    private fun notifyEncryptedMessage(data: Map<String, String>) {
        createChannels()
        val intent = Intent(this, ProductionMainActivity::class.java)
            .putExtra(EXTRA_CONVERSATION_ID, data["conversationId"])
            .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val pending = PendingIntent.getActivity(
            this,
            requestCode(data["messageId"] ?: data["conversationId"].orEmpty()),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification = NotificationCompat.Builder(this, CHANNEL_MESSAGES)
            .setSmallIcon(R.drawable.ic_chatnu)
            .setContentTitle("ChatNU")
            .setContentText("New encrypted message")
            .setAutoCancel(true)
            .setContentIntent(pending)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()
        notifyIfAllowed(requestCode(data["messageId"].orEmpty()), notification)
    }

    private fun notifyIncomingCall(data: Map<String, String>) {
        createChannels()
        val intent = Intent(this, ProductionMainActivity::class.java)
            .putExtra(EXTRA_CONVERSATION_ID, data["conversationId"])
            .putExtra(EXTRA_CALL_ID, data["callId"])
            .putExtra(EXTRA_CALL_VIDEO, data["video"] == "1")
            .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val pending = PendingIntent.getActivity(
            this,
            requestCode(data["callId"].orEmpty()),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification = NotificationCompat.Builder(this, CHANNEL_CALLS)
            .setSmallIcon(R.drawable.ic_chatnu)
            .setContentTitle("Incoming ChatNU call")
            .setContentText(if (data["video"] == "1") "Video call" else "Voice call")
            .setAutoCancel(true)
            .setContentIntent(pending)
            .setFullScreenIntent(pending, true)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setOngoing(false)
            .build()
        notifyIfAllowed(requestCode(data["callId"].orEmpty()), notification)
    }

    private fun notifyIfAllowed(id: Int, notification: android.app.Notification) {
        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) return
        NotificationManagerCompat.from(this).notify(id, notification)
    }

    private fun createChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_MESSAGES, "Encrypted messages", NotificationManager.IMPORTANCE_DEFAULT).apply {
                description = "Notifications for new ChatNU encrypted messages"
            }
        )
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_CALLS, "Calls", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Incoming ChatNU voice and video calls"
            }
        )
    }

    private fun requestCode(value: String): Int = value.hashCode() and 0x7fffffff

    companion object {
        const val EXTRA_CONVERSATION_ID = "chatnu_conversation_id"
        const val EXTRA_CALL_ID = "chatnu_call_id"
        const val EXTRA_CALL_VIDEO = "chatnu_call_video"
        private const val CHANNEL_MESSAGES = "chatnu_messages"
        private const val CHANNEL_CALLS = "chatnu_calls"
    }
}
