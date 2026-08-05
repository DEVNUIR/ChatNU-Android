package com.devnu.chatnu.core.database

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(tableName = "users", indices = [Index(value = ["username"], unique = true)])
data class UserEntity(
    @PrimaryKey val id: String,
    val username: String,
    val displayName: String,
    val accentSeed: Int,
    val presence: String,
    val verified: Boolean,
    val avatarUrl: String?,
)

@Entity(tableName = "conversations", indices = [Index("peerUserId")])
data class ConversationEntity(
    @PrimaryKey val id: String,
    val peerUserId: String,
    val preview: String,
    val updatedAtEpochMs: Long,
    val unreadCount: Int,
    val muted: Boolean,
    val pinned: Boolean,
    val archived: Boolean,
    val typing: Boolean,
)

@Entity(tableName = "messages", indices = [Index("conversationId"), Index("createdAtEpochMs")])
data class MessageEntity(
    @PrimaryKey val id: String,
    val conversationId: String,
    val senderId: String,
    val body: String,
    val mine: Boolean,
    val kind: String,
    val delivery: String,
    val reaction: String?,
    val replyToMessageId: String?,
    val attachmentUrl: String?,
    val createdAtEpochMs: Long,
)

@Entity(tableName = "relay_nodes", indices = [Index(value = ["host"], unique = true)])
data class RelayNodeEntity(
    @PrimaryKey val id: String,
    val name: String,
    val host: String,
    val websocketUrl: String,
    val latencyMs: Int,
    val connected: Boolean,
    val trusted: Boolean,
    val region: String,
    val compatible: Boolean,
)

@Entity(tableName = "outbox", indices = [Index("messageId", unique = true)])
data class OutboxEntity(
    @PrimaryKey val id: String,
    val messageId: String,
    val conversationId: String,
    val envelopeJson: String,
    val retryCount: Int,
    val nextAttemptAtEpochMs: Long,
)
