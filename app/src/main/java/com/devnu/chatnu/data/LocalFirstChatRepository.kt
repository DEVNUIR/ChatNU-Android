package com.devnu.chatnu.data

import com.devnu.chatnu.core.crypto.PayloadCipher
import com.devnu.chatnu.core.database.ChatDao
import com.devnu.chatnu.core.database.ConversationEntity
import com.devnu.chatnu.core.database.MessageEntity
import com.devnu.chatnu.core.database.OutboxEntity
import com.devnu.chatnu.core.database.RelayNodeEntity
import com.devnu.chatnu.core.database.UserEntity
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
import com.devnu.chatnu.core.network.RealtimeGateway
import com.devnu.chatnu.domain.ChatRepository
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.UUID
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class LocalFirstChatRepository(
    private val dao: ChatDao,
    private val api: ChatApi,
    private val realtime: RealtimeGateway,
    private val cipher: PayloadCipher,
    private val applicationScope: CoroutineScope,
) : ChatRepository {
    private val clock = DateTimeFormatter.ofPattern("HH:mm")
    private val json = Json

    override val conversations: Flow<List<Conversation>> = combine(
        dao.observeConversations(),
        dao.observeUsers(),
    ) { conversations, users ->
        val usersById = users.associateBy(UserEntity::id)
        conversations.mapNotNull { entity ->
            val peer = usersById[entity.peerUserId] ?: return@mapNotNull null
            entity.toDomain(peer)
        }
    }

    override val relayNodes = dao.observeRelayNodes().map { nodes -> nodes.map(RelayNodeEntity::toDomain) }
    override val connectionState: Flow<ConnectionState> = realtime.state

    override fun messages(conversationId: String): Flow<List<ChatMessage>> =
        dao.observeMessages(conversationId).map { it.map(MessageEntity::toDomain) }

    override suspend fun sendMessage(conversationId: String, body: String, replyToMessageId: String?) {
        val text = body.trim()
        if (text.isEmpty()) return
        val now = System.currentTimeMillis()
        val id = UUID.randomUUID().toString()
        val encrypted = cipher.encrypt(text)
        val envelope = CipherEnvelope(
            messageId = id,
            conversationId = conversationId,
            senderDeviceId = "local-device",
            recipientUserId = conversationId,
            ciphertext = encrypted.ciphertext,
            nonce = encrypted.nonce,
            createdAtEpochMs = now,
        )
        val message = MessageEntity(
            id = id,
            conversationId = conversationId,
            senderId = "me",
            body = text,
            mine = true,
            kind = MessageKind.TEXT.name,
            delivery = DeliveryState.PENDING.name,
            reaction = null,
            replyToMessageId = replyToMessageId,
            attachmentUrl = null,
            createdAtEpochMs = now,
        )
        dao.saveOutgoing(
            message,
            OutboxEntity(
                id = UUID.randomUUID().toString(),
                messageId = id,
                conversationId = conversationId,
                envelopeJson = json.encodeToString(envelope),
                retryCount = 0,
                nextAttemptAtEpochMs = now,
            ),
        )
        deliver(message.id, envelope)
    }

    override suspend fun retryMessage(messageId: String) {
        val message = dao.message(messageId) ?: return
        val encrypted = cipher.encrypt(message.body)
        deliver(
            messageId,
            CipherEnvelope(
                messageId = message.id,
                conversationId = message.conversationId,
                senderDeviceId = "local-device",
                recipientUserId = message.conversationId,
                ciphertext = encrypted.ciphertext,
                nonce = encrypted.nonce,
                createdAtEpochMs = message.createdAtEpochMs,
            ),
        )
    }

    private suspend fun deliver(messageId: String, envelope: CipherEnvelope) {
        dao.updateDelivery(messageId, DeliveryState.SENDING.name)
        when (api.sendEnvelope(envelope)) {
            is NetworkResult.Success -> {
                dao.updateDelivery(messageId, DeliveryState.SENT.name)
                dao.removeOutboxForMessage(messageId)
            }
            is NetworkResult.Failure -> dao.updateDelivery(messageId, DeliveryState.FAILED.name)
        }
    }

    override suspend fun react(messageId: String, reaction: String?) = dao.updateReaction(messageId, reaction)
    override suspend fun togglePinned(conversationId: String) = dao.togglePinned(conversationId)
    override suspend fun toggleArchived(conversationId: String) = dao.toggleArchived(conversationId)
    override suspend fun selectRelayNode(nodeId: String) = dao.selectRelayNode(nodeId)

    override suspend fun addRelayNode(host: String): Result<RelayNode> = runCatching {
        val normalized = host.trim().removeSuffix("/")
        require(normalized.startsWith("https://")) { "Relay nodes require HTTPS" }
        val node = RelayNode(
            id = UUID.randomUUID().toString(),
            name = normalized.substringAfter("https://").substringBefore('/'),
            host = normalized,
            websocketUrl = normalized.replaceFirst("https://", "wss://") + "/realtime",
            latencyMs = 0,
            connected = false,
            trusted = false,
            region = "Custom",
            compatible = true,
        )
        dao.upsertRelayNodes(listOf(node.toEntity()))
        node
    }

    override suspend fun seedIfEmpty() {
        if (dao.conversationCount() > 0) return
        val users = listOf(
            UserEntity("u-hanieh", "hanieh", "Hanieh", 17, Presence.ONLINE.name, true, null),
            UserEntity("u-devnu", "devnu", "DEVNU Community", 44, Presence.ONLINE.name, true, null),
            UserEntity("u-amir", "amir", "Amir", 73, Presence.AWAY.name, false, null),
        )
        val now = System.currentTimeMillis()
        dao.upsertUsers(users)
        dao.upsertConversations(listOf(
            ConversationEntity("c-hanieh", "u-hanieh", "Meet me on the private node.", now, 2, false, true, false, false),
            ConversationEntity("c-devnu", "u-devnu", "The Android rebuild is live.", now - 70_000, 0, false, false, false, true),
            ConversationEntity("c-amir", "u-amir", "Encrypted attachment", now - 500_000, 0, true, false, false, false),
        ))
        dao.upsertMessage(MessageEntity("m-welcome", "c-hanieh", "u-hanieh", "ChatNU keeps the readable copy on your device.", false, MessageKind.TEXT.name, DeliveryState.READ.name, "🔐", null, null, now - 120_000))
        dao.upsertRelayNodes(listOf(
            RelayNodeEntity("official", "DEVNU Official", "https://chatnu.devnu.ir", "wss://chatnu.devnu.ir/realtime", 18, true, true, "Europe", true),
            RelayNodeEntity("community", "Community Relay", "https://relay.chatnu.community", "wss://relay.chatnu.community/realtime", 42, false, false, "Community", true),
        ))
    }

    fun startRealtime() {
        applicationScope.launch(Dispatchers.IO) { realtime.run(null) }
    }

    private fun ConversationEntity.toDomain(peer: UserEntity) = Conversation(
        id = id,
        peer = peer.toDomain(),
        preview = preview,
        timestamp = Instant.ofEpochMilli(updatedAtEpochMs).atZone(ZoneId.systemDefault()).format(clock),
        unreadCount = unreadCount,
        muted = muted,
        pinned = pinned,
        archived = archived,
        typing = typing,
    )

    private fun UserEntity.toDomain() = UserProfile(id, username, displayName, accentSeed, Presence.valueOf(presence), verified, avatarUrl)
    private fun MessageEntity.toDomain() = ChatMessage(id, conversationId, senderId, body, Instant.ofEpochMilli(createdAtEpochMs).atZone(ZoneId.systemDefault()).format(clock), mine, MessageKind.valueOf(kind), DeliveryState.valueOf(delivery), reaction, replyToMessageId, attachmentUrl, createdAtEpochMs)
    private fun RelayNodeEntity.toDomain() = RelayNode(id, name, host, websocketUrl, latencyMs, connected, trusted, region, compatible)
    private fun RelayNode.toEntity() = RelayNodeEntity(id, name, host, websocketUrl, latencyMs, connected, trusted, region, compatible)
}
