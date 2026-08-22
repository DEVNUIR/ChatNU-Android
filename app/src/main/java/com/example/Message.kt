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

enum class MessageStatus {
    QUEUED,
    SENDING,
    SENT,
    DELIVERED,
    READ,
    FAILED
}

data class Message(
    val id: String,
    val conversationId: String,
    val senderId: String,
    val senderName: String,
    val text: String,
    val type: MessageType = MessageType.TEXT,
    val status: MessageStatus = MessageStatus.READ,
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
