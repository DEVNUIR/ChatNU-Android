package com.example.model

enum class ConversationType {
    DIRECT, GROUP
}

data class Conversation(
    val id: String,
    val title: String,
    val type: ConversationType,
    val avatarUrl: String? = null,
    val lastMessageText: String = "",
    val lastMessageTime: String = "",
    val unreadCount: Int = 0,
    val isPinned: Boolean = false,
    val isMuted: Boolean = false,
    val isEncrypted: Boolean = true,
    val members: List<User> = emptyList(),
    val disappearingTimerSeconds: Int = 0 // 0 means disabled
)
