package com.devnu.chatnu.domain

import com.devnu.chatnu.core.model.ChatMessage
import com.devnu.chatnu.core.model.ConnectionState
import com.devnu.chatnu.core.model.Conversation
import com.devnu.chatnu.core.model.RelayNode
import kotlinx.coroutines.flow.Flow

interface ChatRepository {
    val conversations: Flow<List<Conversation>>
    val relayNodes: Flow<List<RelayNode>>
    val connectionState: Flow<ConnectionState>

    fun messages(conversationId: String): Flow<List<ChatMessage>>
    suspend fun sendMessage(conversationId: String, body: String, replyToMessageId: String? = null)
    suspend fun retryMessage(messageId: String)
    suspend fun react(messageId: String, reaction: String?)
    suspend fun togglePinned(conversationId: String)
    suspend fun toggleArchived(conversationId: String)
    suspend fun selectRelayNode(nodeId: String)
    suspend fun addRelayNode(host: String): Result<RelayNode>
    suspend fun seedIfEmpty()
}
