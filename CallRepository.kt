package com.example.data

import com.example.model.CallSession
import com.example.model.CallStatus
import com.example.model.CallType
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class CallRepository {
    private val _activeCall = MutableStateFlow<CallSession?>(null)
    val activeCall: StateFlow<CallSession?> = _activeCall.asStateFlow()

    fun startCall(peerName: String, peerAvatar: String?, type: CallType) {
        _activeCall.value = CallSession(
            callId = "call_" + System.currentTimeMillis(),
            peerName = peerName,
            peerAvatar = peerAvatar,
            callType = type,
            status = CallStatus.OUTGOING,
            durationSeconds = 0,
            isMuted = false,
            isCameraOn = type != CallType.VOICE
        )
    }

    fun acceptIncomingCall() {
        _activeCall.value = _activeCall.value?.copy(status = CallStatus.CONNECTED)
    }

    fun toggleMute() {
        _activeCall.value = _activeCall.value?.let { it.copy(isMuted = !it.isMuted) }
    }

    fun toggleCamera() {
        _activeCall.value = _activeCall.value?.let { it.copy(isCameraOn = !it.isCameraOn) }
    }

    fun toggleSpeaker() {
        _activeCall.value = _activeCall.value?.let { it.copy(isSpeakerOn = !it.isSpeakerOn) }
    }

    fun endCall() {
        _activeCall.value = _activeCall.value?.copy(status = CallStatus.ENDED)
        _activeCall.value = null
    }

    fun simulateIncomingCall(peerName: String, peerAvatar: String?, type: CallType) {
        _activeCall.value = CallSession(
            callId = "call_inc_" + System.currentTimeMillis(),
            peerName = peerName,
            peerAvatar = peerAvatar,
            callType = type,
            status = CallStatus.INCOMING
        )
    }
}
