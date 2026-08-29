package com.example.model

enum class CallType {
    VOICE, VIDEO, GROUP_VIDEO
}

enum class CallStatus {
    IDLE, OUTGOING, INCOMING, CONNECTED, ENDED, BUSY
}

data class CallSession(
    val callId: String,
    val peerName: String,
    val peerAvatar: String? = null,
    val callType: CallType = CallType.VOICE,
    val status: CallStatus = CallStatus.IDLE,
    val durationSeconds: Int = 0,
    val isMuted: Boolean = false,
    val isCameraOn: Boolean = true,
    val isSpeakerOn: Boolean = false,
    val isEncrypted: Boolean = true
)
