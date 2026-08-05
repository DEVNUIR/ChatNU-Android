package com.devnu.chatnu

import com.devnu.chatnu.core.model.ChatMessage
import com.devnu.chatnu.core.model.ConnectionState
import com.devnu.chatnu.core.model.Conversation
import com.devnu.chatnu.core.model.DeliveryState
import com.devnu.chatnu.core.model.MessageKind
import com.devnu.chatnu.core.model.Presence
import com.devnu.chatnu.core.model.RelayNode
import com.devnu.chatnu.core.model.UserProfile
import com.devnu.chatnu.domain.ChatRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow

class FakeChatRepository : ChatRepository {
    override val conversations = MutableStateFlow(listOf(
        Conversation("active", UserProfile("u1", "alice", "Alice", 1, Presence.ONLINE), "hello", "12:00"),
        Conversation("archived", UserProfile("u2", "bob", "Bob", 2), "old", "11:00", archived = true),
    ))
    override val relayNodes = MutableStateFlow<List<RelayNode>>(emptyList())
    override val connectionState = MutableStateFlow(ConnectionState.CONNECTED)
    private val messageFlows = mutableMapOf<String, MutableStateFlow<List<ChatMessage>>>()
    val sentBodies = mutableListOf<String>()

    override fun messages(conversationId: String): Flow<List<ChatMessage>> = messageFlows.getOrPut(conversationId) { MutableStateFlow(emptyList()) }
    override suspend fun sendMessage(conversationId: String, body: String, replyToMessageId: String?) {
        sentBodies += body
        val flow = messageFlows.getOrPut(conversationId) { MutableStateFlow(emptyList()) }
        flow.value = flow.value + ChatMessage("m${flow.value.size}", conversationId, "me", body, "12:01", true, MessageKind.TEXT, DeliveryState.SENT)
    }
    override suspend fun retryMessage(messageId: String) = Unit
    override suspend fun react(messageId: String, reaction: String?) = Unit
    override suspend fun togglePinned(conversationId: String) {
        conversations.value = conversations.value.map { if (it.id == conversationId) it.copy(pinned = !it.pinned) else it }
    }
    override suspend fun toggleArchived(conversationId: String) {
        conversations.value = conversations.value.map { if (it.id == conversationId) it.copy(archived = !it.archived) else it }
    }
    override suspend fun selectRelayNode(nodeId: String) = Unit
    override suspend fun addRelayNode(host: String): Result<RelayNode> = Result.failure(UnsupportedOperationException())
    override suspend fun seedIfEmpty() = Unit
}
