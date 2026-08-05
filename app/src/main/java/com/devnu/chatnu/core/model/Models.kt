package com.devnu.chatnu.core.model

enum class Presence { ONLINE, AWAY, OFFLINE }
enum class DeliveryState { SENDING, SENT, DELIVERED, READ }
enum class MessageKind { TEXT, IMAGE, VOICE, SYSTEM }

data class UserProfile(
    val id: String,
    val username: String,
    val displayName: String,
    val accentSeed: Int,
    val presence: Presence = Presence.OFFLINE,
    val verified: Boolean = false,
)

data class Conversation(
    val id: String,
    val peer: UserProfile,
    val preview: String,
    val timestamp: String,
    val unreadCount: Int = 0,
    val muted: Boolean = false,
    val pinned: Boolean = false,
    val typing: Boolean = false,
)

data class ChatMessage(
    val id: String,
    val conversationId: String,
    val senderId: String,
    val body: String,
    val timestamp: String,
    val mine: Boolean,
    val kind: MessageKind = MessageKind.TEXT,
    val delivery: DeliveryState = DeliveryState.READ,
    val reaction: String? = null,
)

data class RelayNode(
    val id: String,
    val name: String,
    val host: String,
    val latencyMs: Int,
    val connected: Boolean,
    val trusted: Boolean,
    val region: String,
)
