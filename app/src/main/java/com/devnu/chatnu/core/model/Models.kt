package com.devnu.chatnu.core.model

import kotlinx.serialization.Serializable

enum class Presence { ONLINE, AWAY, OFFLINE }
enum class DeliveryState { PENDING, SENDING, SENT, DELIVERED, READ, FAILED }
enum class MessageKind { TEXT, IMAGE, VOICE, FILE, SYSTEM }
enum class ConnectionState { DISCONNECTED, CONNECTING, CONNECTED, DEGRADED }

@Serializable
data class UserProfile(
    val id: String,
    val username: String,
    val displayName: String,
    val accentSeed: Int,
    val presence: Presence = Presence.OFFLINE,
    val verified: Boolean = false,
    val avatarUrl: String? = null,
)

@Serializable
data class Conversation(
    val id: String,
    val peer: UserProfile,
    val preview: String,
    val timestamp: String,
    val unreadCount: Int = 0,
    val muted: Boolean = false,
    val pinned: Boolean = false,
    val archived: Boolean = false,
    val typing: Boolean = false,
)

@Serializable
data class ChatMessage(
    val id: String,
    val conversationId: String,
    val senderId: String,
    val body: String,
    val timestamp: String,
    val mine: Boolean,
    val kind: MessageKind = MessageKind.TEXT,
    val delivery: DeliveryState = DeliveryState.PENDING,
    val reaction: String? = null,
    val replyToMessageId: String? = null,
    val attachmentUrl: String? = null,
    val createdAtEpochMs: Long = System.currentTimeMillis(),
)

@Serializable
data class RelayNode(
    val id: String,
    val name: String,
    val host: String,
    val websocketUrl: String,
    val latencyMs: Int,
    val connected: Boolean,
    val trusted: Boolean,
    val region: String,
    val compatible: Boolean = true,
)

@Serializable
data class LocalIdentity(
    val userId: String,
    val username: String,
    val displayName: String,
    val deviceId: String,
    val keyAlias: String,
    val publicIdentityKey: String,
    val fingerprint: String,
    val recoveryCreated: Boolean,
)
