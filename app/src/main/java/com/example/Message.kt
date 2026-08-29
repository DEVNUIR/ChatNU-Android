package com.example.model

enum class MessageType {
    TEXT,
    IMAGE,
    VIDEO,
    VOICE,
    FILE,
    LOCATION,
    LIVE_LOCATION,
    VIEW_ONCE_IMAGE,
    VIEW_ONCE_VIDEO,
    SYSTEM_KEY_CHANGE
}

/**
 * Persistence/network-facing status values kept for source compatibility with the existing app.
 * The current server only confirms acceptance, so SENT must never be rendered as delivered/read.
 */
enum class MessageStatus {
    QUEUED,
    SENDING,
    SENT,
    DELIVERED,
    READ,
    FAILED
}

/**
 * Explicit product semantics for the UI. DELIVERED/READ are intentionally future-facing: the
 * current backend does not emit those receipts, therefore production mapping stops at
 * SENT_TO_SERVER.
 */
enum class MessageDeliveryState {
    QUEUED_OFFLINE,
    SENDING,
    SENT_TO_SERVER,
    DELIVERED_TO_RECIPIENT_DEVICE,
    READ,
    FAILED
}

fun MessageStatus.toDeliveryState(): MessageDeliveryState = when (this) {
    MessageStatus.QUEUED -> MessageDeliveryState.QUEUED_OFFLINE
    MessageStatus.SENDING -> MessageDeliveryState.SENDING
    MessageStatus.SENT -> MessageDeliveryState.SENT_TO_SERVER
    MessageStatus.DELIVERED -> MessageDeliveryState.DELIVERED_TO_RECIPIENT_DEVICE
    MessageStatus.READ -> MessageDeliveryState.READ
    MessageStatus.FAILED -> MessageDeliveryState.FAILED
}

data class Message(
    val id: String,
    val conversationId: String,
    val senderId: String,
    val senderName: String,
    val text: String,
    val type: MessageType = MessageType.TEXT,
    // Safe default for a model materialized from the server. Local optimistic sends set SENDING.
    val status: MessageStatus = MessageStatus.SENT,
    val timestamp: String,
    val timestampMillis: Long = System.currentTimeMillis(),
    val mediaUrl: String? = null,
    val mediaSize: String? = null,
    val voiceDurationSeconds: Int = 0,
    val voiceWaveform: List<Float> = emptyList(),
    val isViewOnceOpened: Boolean = false,
    val replyToText: String? = null,
    val reactions: List<String> = emptyList(),
    val latitude: Double? = null,
    val longitude: Double? = null,
    val fileName: String? = null,
    val fileSize: String? = null,
    val fileExtension: String? = null,
    val attachmentId: String? = null,
    val mimeType: String? = null,
    val attachmentKeyBase64: String? = null,
    val attachmentNonceBase64: String? = null,
    val localUri: String? = null,
    val isPinned: Boolean = false
)
