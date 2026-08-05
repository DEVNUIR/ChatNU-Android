package com.devnu.chatnu.core.network

import kotlinx.coroutines.flow.Flow
import kotlinx.serialization.Serializable

@Serializable
data class EncryptedEnvelope(
    val messageId: String,
    val conversationId: String,
    val recipientDeviceId: String,
    val ciphertext: String,
    val nonce: String,
    val createdAt: Long,
)

sealed interface RealtimeEvent {
    data object Connected : RealtimeEvent
    data object Disconnected : RealtimeEvent
    data class EnvelopeReceived(val envelope: EncryptedEnvelope) : RealtimeEvent
    data class TypingChanged(val conversationId: String, val userId: String, val typing: Boolean) : RealtimeEvent
}

interface ChatNuApi {
    suspend fun sync(cursor: String?): SyncPage
    suspend fun sendEnvelope(envelope: EncryptedEnvelope)
}

@Serializable
data class SyncPage(
    val nextCursor: String?,
    val envelopes: List<EncryptedEnvelope>,
)

interface RealtimeClient {
    val events: Flow<RealtimeEvent>
    suspend fun connect(config: ServerConfig, bearerToken: String)
    suspend fun disconnect()
    suspend fun send(envelope: EncryptedEnvelope)
}
