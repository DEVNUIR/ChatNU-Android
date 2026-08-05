package com.devnu.chatnu.core.network

import kotlinx.serialization.Serializable

@Serializable
data class HealthResponse(val status: String, val version: String, val nodeId: String)

@Serializable
data class RegisterRequest(
    val username: String,
    val displayName: String,
    val deviceId: String,
    val publicIdentityKey: String,
)

@Serializable
data class RegisterResponse(val userId: String, val accessToken: String, val refreshToken: String)

@Serializable
data class CipherEnvelope(
    val messageId: String,
    val conversationId: String,
    val senderDeviceId: String,
    val recipientUserId: String,
    val ciphertext: String,
    val nonce: String,
    val createdAtEpochMs: Long,
)

@Serializable
data class RealtimeEvent(
    val type: String,
    val conversationId: String? = null,
    val messageId: String? = null,
    val senderId: String? = null,
    val payload: String? = null,
    val state: String? = null,
)

sealed interface NetworkResult<out T> {
    data class Success<T>(val value: T) : NetworkResult<T>
    data class Failure(val error: Throwable) : NetworkResult<Nothing>
}
