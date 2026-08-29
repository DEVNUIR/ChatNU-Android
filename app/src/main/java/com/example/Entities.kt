package com.example.database

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey val id: String,
    val username: String,
    val displayName: String,
    val avatarUrl: String?,
    val bio: String?,
    val isOnline: Boolean,
    val lastSeen: String,
    val identityKeyFingerprint: String
)

@Entity(tableName = "conversations")
data class ConversationEntity(
    @PrimaryKey val id: String,
    val title: String,
    val type: String,
    val avatarUrl: String?,
    val lastMessageText: String,
    val lastMessageTime: String,
    val unreadCount: Int,
    val isPinned: Boolean,
    val isMuted: Boolean,
    val isEncrypted: Boolean
)

@Entity(tableName = "messages")
data class MessageEntity(
    @PrimaryKey val id: String,
    val conversationId: String,
    val senderId: String,
    val senderName: String,
    val text: String,
    val type: String,
    val status: String,
    val timestamp: String,
    val timestampMillis: Long,
    val mediaUrl: String?,
    val voiceDurationSeconds: Int,
    val isViewOnceOpened: Boolean
)
