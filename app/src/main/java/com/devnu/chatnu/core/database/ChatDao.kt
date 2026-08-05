package com.devnu.chatnu.core.database

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import kotlinx.coroutines.flow.Flow

@Dao
interface ChatDao {
    @Query("SELECT * FROM users")
    fun observeUsers(): Flow<List<UserEntity>>

    @Query("SELECT * FROM conversations ORDER BY pinned DESC, updatedAtEpochMs DESC")
    fun observeConversations(): Flow<List<ConversationEntity>>

    @Query("SELECT * FROM messages WHERE conversationId = :conversationId ORDER BY createdAtEpochMs ASC")
    fun observeMessages(conversationId: String): Flow<List<MessageEntity>>

    @Query("SELECT * FROM relay_nodes ORDER BY trusted DESC, latencyMs ASC")
    fun observeRelayNodes(): Flow<List<RelayNodeEntity>>

    @Query("SELECT COUNT(*) FROM conversations")
    suspend fun conversationCount(): Int

    @Query("SELECT * FROM conversations WHERE id = :conversationId LIMIT 1")
    suspend fun conversation(conversationId: String): ConversationEntity?

    @Query("SELECT * FROM messages WHERE id = :messageId LIMIT 1")
    suspend fun message(messageId: String): MessageEntity?

    @Query("SELECT * FROM outbox WHERE nextAttemptAtEpochMs <= :now ORDER BY nextAttemptAtEpochMs ASC LIMIT :limit")
    suspend fun pendingOutbox(now: Long, limit: Int = 50): List<OutboxEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertUsers(items: List<UserEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertConversations(items: List<ConversationEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertMessage(item: MessageEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertRelayNodes(items: List<RelayNodeEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertOutbox(item: OutboxEntity)

    @Query("UPDATE messages SET delivery = :delivery WHERE id = :messageId")
    suspend fun updateDelivery(messageId: String, delivery: String)

    @Query("UPDATE messages SET reaction = :reaction WHERE id = :messageId")
    suspend fun updateReaction(messageId: String, reaction: String?)

    @Query("UPDATE conversations SET typing = :typing WHERE id = :conversationId")
    suspend fun updateTyping(conversationId: String, typing: Boolean)

    @Query("UPDATE conversations SET pinned = NOT pinned WHERE id = :conversationId")
    suspend fun togglePinned(conversationId: String)

    @Query("UPDATE conversations SET archived = NOT archived WHERE id = :conversationId")
    suspend fun toggleArchived(conversationId: String)

    @Query("UPDATE relay_nodes SET connected = CASE WHEN id = :nodeId THEN 1 ELSE 0 END")
    suspend fun selectRelayNode(nodeId: String)

    @Query("UPDATE outbox SET retryCount = retryCount + 1, nextAttemptAtEpochMs = :nextAttempt WHERE id = :id")
    suspend fun scheduleRetry(id: String, nextAttempt: Long)

    @Query("DELETE FROM outbox WHERE messageId = :messageId")
    suspend fun removeOutboxForMessage(messageId: String)

    @Transaction
    suspend fun saveOutgoing(message: MessageEntity, outbox: OutboxEntity) {
        upsertMessage(message)
        upsertOutbox(outbox)
    }
}
