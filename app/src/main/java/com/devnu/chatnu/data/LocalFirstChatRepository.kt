package com.devnu.chatnu.data

import com.devnu.chatnu.core.crypto.PayloadCipher
import com.devnu.chatnu.core.database.ChatDao
import com.devnu.chatnu.core.database.ConversationEntity
import com.devnu.chatnu.core.database.MessageEntity
import com.devnu.chatnu.core.database.OutboxEntity
import com.devnu.chatnu.core.database.RelayNodeEntity
import com.devnu.chatnu.core.database.UserEntity
import com.devnu.chatnu.core.identity.IdentityStore
import com.devnu.chatnu.core.model.ChatMessage
import com.devnu.chatnu.core.model.ConnectionState
import com.devnu.chatnu.core.model.Conversation
import com.devnu.chatnu.core.model.DeliveryState
import com.devnu.chatnu.core.model.MessageKind
import com.devnu.chatnu.core.model.Presence
import com.devnu.chatnu.core.model.RelayNode
import com.devnu.chatnu.core.model.UserProfile
import com.devnu.chatnu.core.network.ChatApi
import com.devnu.chatnu.core.network.CipherEnvelope
import com.devnu.chatnu.core.network.NetworkResult
import com.devnu.chatnu.core.network.NodeValidator
import com.devnu.chatnu.core.network.RealtimeEvent
import com.devnu.chatnu.core.network.RealtimeGateway
import com.devnu.chatnu.core.session.SessionStore
import com.devnu.chatnu.domain.ChatRepository
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.UUID
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

class LocalFirstChatRepository(
    private val dao: ChatDao,
    private val api: ChatApi,
    private val realtime: RealtimeGateway,
    private val cipher: PayloadCipher,
    private val identityStore: IdentityStore,
    private val sessionStore: SessionStore,
    private val nodeValidator: NodeValidator,
    private val applicationScope: CoroutineScope,
) : ChatRepository {
    private val clock = DateTimeFormatter.ofPattern("HH:mm")
    private val json = Json { ignoreUnknownKeys = true }

    override val conversations: Flow<List<Conversation>> = combine(dao.observeConversations(), dao.observeUsers()) { conversations, users ->
        val usersById = users.associateBy(UserEntity::id)
        conversations.mapNotNull { entity -> usersById[entity.peerUserId]?.let(entity::toDomain) }
    }
    override val relayNodes = dao.observeRelayNodes().map { nodes -> nodes.map(RelayNodeEntity::toDomain) }
    override val connectionState: Flow<ConnectionState> = realtime.state
    override fun messages(conversationId: String): Flow<List<ChatMessage>> = dao.observeMessages(conversationId).map { it.map(MessageEntity::toDomain) }

    override suspend fun sendMessage(conversationId: String, body: String, replyToMessageId: String?) {
        val text = body.trim()
        if (text.isEmpty()) return
        val identity = identityStore.identity.first() ?: return
        val conversation = dao.conversation(conversationId) ?: return
        val now = System.currentTimeMillis()
        val id = UUID.randomUUID().toString()
        val encrypted = cipher.encrypt(text)
        val envelope = CipherEnvelope(id, conversationId, identity.deviceId, conversation.peerUserId, encrypted.ciphertext, encrypted.nonce, now)
        val message = MessageEntity(id, conversationId, identity.userId, text, true, MessageKind.TEXT.name, DeliveryState.PENDING.name, null, replyToMessageId, null, now)
        dao.saveOutgoing(message, OutboxEntity(UUID.randomUUID().toString(), id, conversationId, json.encodeToString(envelope), 0, now))
        deliver(message.id, envelope)
    }

    override suspend fun retryMessage(messageId: String) {
        val message = dao.message(messageId) ?: return
        val identity = identityStore.identity.first() ?: return
        val conversation = dao.conversation(message.conversationId) ?: return
        val encrypted = cipher.encrypt(message.body)
        deliver(messageId, CipherEnvelope(message.id, message.conversationId, identity.deviceId, conversation.peerUserId, encrypted.ciphertext, encrypted.nonce, message.createdAtEpochMs))
    }

    suspend fun flushOutbox() {
        dao.pendingOutbox(System.currentTimeMillis()).forEach { pending ->
            runCatching { json.decodeFromString<CipherEnvelope>(pending.envelopeJson) }
                .onSuccess { deliver(pending.messageId, it, pending) }
        }
    }

    suspend fun syncFromServer() {
        when (val result = api.sync(sessionStore.syncCursor())) {
            is NetworkResult.Success -> {
                result.value.events.forEach { event ->
                    if (event.type == "envelope") {
                        val payload = event.payload
                        handleEnvelope(
                            conversationId = payload["conversationId"]?.jsonPrimitive?.content ?: return@forEach,
                            messageId = payload["messageId"]?.jsonPrimitive?.content ?: return@forEach,
                            senderId = payload["senderId"]?.jsonPrimitive?.content ?: "remote",
                            ciphertext = payload["ciphertext"]?.jsonPrimitive?.content ?: return@forEach,
                            nonce = payload["nonce"]?.jsonPrimitive?.content ?: return@forEach,
                            createdAt = payload["createdAtEpochMs"]?.jsonPrimitive?.content?.toLongOrNull() ?: System.currentTimeMillis(),
                        )
                    }
                }
                sessionStore.saveSyncCursor(result.value.nextCursor)
            }
            is NetworkResult.Failure -> Unit
        }
    }

    private suspend fun deliver(messageId: String, envelope: CipherEnvelope, pending: OutboxEntity? = null) {
        dao.updateDelivery(messageId, DeliveryState.SENDING.name)
        when (api.sendEnvelope(envelope)) {
            is NetworkResult.Success -> {
                dao.updateDelivery(messageId, DeliveryState.SENT.name)
                dao.removeOutboxForMessage(messageId)
            }
            is NetworkResult.Failure -> {
                dao.updateDelivery(messageId, DeliveryState.FAILED.name)
                pending?.let {
                    val backoff = (1_000L * (1L shl it.retryCount.coerceAtMost(8))).coerceAtMost(15 * 60_000L)
                    dao.scheduleRetry(it.id, System.currentTimeMillis() + backoff)
                }
            }
        }
    }

    override suspend fun react(messageId: String, reaction: String?) = dao.updateReaction(messageId, reaction)
    override suspend fun togglePinned(conversationId: String) = dao.togglePinned(conversationId)
    override suspend fun toggleArchived(conversationId: String) = dao.toggleArchived(conversationId)
    override suspend fun selectRelayNode(nodeId: String) = dao.selectRelayNode(nodeId)

    override suspend fun addRelayNode(host: String): Result<RelayNode> = runCatching {
        val validated = nodeValidator.validate(host)
        val node = RelayNode(UUID.randomUUID().toString(), validated.nodeId, validated.host, validated.websocketUrl, validated.latencyMs, false, false, "Custom", true)
        dao.upsertRelayNodes(listOf(node.toEntity()))
        node
    }

    override suspend fun seedIfEmpty() {
        if (dao.conversationCount() > 0) return
        val users = listOf(
            UserEntity("1dd36d0d-8f73-4c27-bf92-5db9f344d7a3", "hanieh", "Hanieh", 17, Presence.ONLINE.name, true, null),
            UserEntity("15b40b13-830b-4f30-9fdf-615a41d7918c", "devnu", "DEVNU Community", 44, Presence.ONLINE.name, true, null),
            UserEntity("4c013aab-6a59-4358-a3ad-1e2040a41e33", "amir", "Amir", 73, Presence.AWAY.name, false, null),
        )
        val now = System.currentTimeMillis()
        dao.upsertUsers(users)
        dao.upsertConversations(listOf(
            ConversationEntity("c-hanieh", users[0].id, "Meet me on the private node.", now, 2, false, true, false, false),
            ConversationEntity("c-devnu", users[1].id, "The Android rebuild is live.", now - 70_000, 0, false, false, false, true),
            ConversationEntity("c-amir", users[2].id, "Encrypted attachment", now - 500_000, 0, true, false, false, false),
        ))
        dao.upsertMessage(MessageEntity("m-welcome", "c-hanieh", users[0].id, "ChatNU keeps the readable copy on your device.", false, MessageKind.TEXT.name, DeliveryState.READ.name, "🔐", null, null, now - 120_000))
        dao.upsertRelayNodes(listOf(
            RelayNodeEntity("official", "DEVNU Official", "https://chatnu.devnu.ir", "wss://chatnu.devnu.ir/realtime", 18, true, true, "Europe", true),
            RelayNodeEntity("community", "Community Relay", "https://relay.chatnu.community", "wss://relay.chatnu.community/realtime", 42, false, false, "Community", true),
        ))
    }

    fun startRealtime(accessToken: String?) {
        applicationScope.launch(Dispatchers.IO) { realtime.run(accessToken) }
        applicationScope.launch(Dispatchers.IO) { realtime.events.collect(::handleRealtimeEvent) }
    }

    private suspend fun handleRealtimeEvent(event: RealtimeEvent) {
        when (event.type) {
            "envelope" -> {
                val payload = event.payload?.let { json.parseToJsonElement(it).jsonObject } ?: return
                handleEnvelope(
                    conversationId = event.conversationId ?: return,
                    messageId = event.messageId ?: return,
                    senderId = event.senderId ?: "remote",
                    ciphertext = payload["ciphertext"]?.jsonPrimitive?.content ?: return,
                    nonce = payload["nonce"]?.jsonPrimitive?.content ?: return,
                    createdAt = System.currentTimeMillis(),
                )
            }
            "typing" -> dao.updateTyping(event.conversationId ?: return, event.payload?.contains("true") == true)
            "receipt" -> {
                val state = when (event.state) {
                    "read" -> DeliveryState.READ
                    "delivered" -> DeliveryState.DELIVERED
                    else -> return
                }
                dao.updateDelivery(event.messageId ?: return, state.name)
            }
        }
    }

    private suspend fun handleEnvelope(conversationId: String, messageId: String, senderId: String, ciphertext: String, nonce: String, createdAt: Long) {
        if (dao.conversation(conversationId) == null) return
        val body = runCatching { cipher.decrypt(ciphertext, nonce) }.getOrElse { "Encrypted message awaiting a compatible key session" }
        dao.upsertMessage(MessageEntity(messageId, conversationId, senderId, body, false, MessageKind.TEXT.name, DeliveryState.DELIVERED.name, null, null, null, createdAt))
    }

    private fun ConversationEntity.toDomain(peer: UserEntity) = Conversation(id, peer.toDomain(), preview, Instant.ofEpochMilli(updatedAtEpochMs).atZone(ZoneId.systemDefault()).format(clock), unreadCount, muted, pinned, archived, typing)
    private fun UserEntity.toDomain() = UserProfile(id, username, displayName, accentSeed, Presence.valueOf(presence), verified, avatarUrl)
    private fun MessageEntity.toDomain() = ChatMessage(id, conversationId, senderId, body, Instant.ofEpochMilli(createdAtEpochMs).atZone(ZoneId.systemDefault()).format(clock), mine, MessageKind.valueOf(kind), DeliveryState.valueOf(delivery), reaction, replyToMessageId, attachmentUrl, createdAtEpochMs)
    private fun RelayNodeEntity.toDomain() = RelayNode(id, name, host, websocketUrl, latencyMs, connected, trusted, region, compatible)
    private fun RelayNode.toEntity() = RelayNodeEntity(id, name, host, websocketUrl, latencyMs, connected, trusted, region, compatible)
}
