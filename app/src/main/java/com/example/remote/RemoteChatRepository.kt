package com.example.remote

import com.example.BuildConfig
import com.example.crypto.CryptoEngine
import com.example.crypto.EncryptedEnvelope
import com.example.model.Conversation
import com.example.model.ConversationType
import com.example.model.Message
import com.example.model.MessageStatus
import com.example.model.MessageType
import com.example.model.User
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import okio.ByteString
import org.json.JSONObject
import java.util.UUID

class RemoteChatRepository(
    private val apiClient: ApiClient,
    private val tokenStore: TokenStore,
    private val authRepository: RemoteAuthRepository
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val _conversations = MutableStateFlow<List<Conversation>>(emptyList())
    val conversations: StateFlow<List<Conversation>> = _conversations.asStateFlow()

    private val _messagesMap = MutableStateFlow<Map<String, List<Message>>>(emptyMap())
    val messagesMap: StateFlow<Map<String, List<Message>>> = _messagesMap.asStateFlow()

    private var webSocket: WebSocket? = null

    suspend fun refreshConversations() {
        val result = apiClient.api.conversations()
        _conversations.value = result.conversations.map { it.toModel() }
    }

    suspend fun loadMessages(conversationId: String) {
        val response = apiClient.api.messages(conversationId, limit = 100)
        val updated = _messagesMap.value.toMutableMap()
        updated[conversationId] = response.messages.map { it.toModel() }
        _messagesMap.value = updated
    }

    suspend fun searchUsers(query: String): List<User> {
        if (query.trim().length < 2) return emptyList()
        return apiClient.api.searchUsers(query.trim()).users.map { it.toModel() }
    }

    suspend fun openDirect(username: String): Conversation {
        val dto = apiClient.api.createDirect(DirectConversationRequest(username.trim().lowercase())).conversation
        val model = dto.toModel()
        mergeConversation(model)
        loadMessages(model.id)
        return model
    }

    suspend fun createGroup(title: String, usernames: List<String> = emptyList()): Conversation {
        val dto = apiClient.api.createGroup(GroupConversationRequest(title.trim(), usernames.map { it.trim().lowercase() })).conversation
        val model = dto.toModel()
        mergeConversation(model)
        loadMessages(model.id)
        return model
    }

    fun getMessages(conversationId: String): List<Message> = _messagesMap.value[conversationId].orEmpty()

    fun sendMessage(
        conversationId: String,
        text: String,
        type: MessageType = MessageType.TEXT,
        mediaUrl: String? = null,
        voiceDurationSeconds: Int = 0,
        latitude: Double? = null,
        longitude: Double? = null,
        fileName: String? = null,
        fileSize: String? = null,
        fileExtension: String? = null
    ) {
        val me = authRepository.currentUser.value ?: return
        val clientId = UUID.randomUUID().toString()
        val envelope = CryptoEngine.encryptPayload(text)
        val optimistic = Message(
            id = clientId,
            conversationId = conversationId,
            senderId = me.id,
            senderName = me.displayName,
            text = text,
            type = type,
            status = MessageStatus.SENDING,
            timestamp = "now",
            timestampMillis = System.currentTimeMillis(),
            mediaUrl = mediaUrl,
            voiceDurationSeconds = voiceDurationSeconds,
            latitude = latitude,
            longitude = longitude,
            fileName = fileName,
            fileSize = fileSize,
            fileExtension = fileExtension
        )
        appendMessage(conversationId, optimistic)

        scope.launch {
            runCatching {
                apiClient.api.sendMessage(
                    SendMessageRequest(
                        conversationId = conversationId,
                        clientId = clientId,
                        type = type.toServerType(),
                        ciphertext = envelope.ciphertext,
                        nonce = envelope.nonceBase64,
                        protocolVersion = envelope.protocolVersion
                    )
                ).message.toModel().copy(
                    mediaUrl = mediaUrl,
                    voiceDurationSeconds = voiceDurationSeconds,
                    latitude = latitude,
                    longitude = longitude,
                    fileName = fileName,
                    fileSize = fileSize,
                    fileExtension = fileExtension,
                    status = MessageStatus.SENT
                )
            }.onSuccess { serverMessage ->
                replaceMessage(conversationId, clientId, serverMessage)
                runCatching { refreshConversations() }
            }.onFailure {
                updateMessageStatus(conversationId, clientId, MessageStatus.FAILED)
            }
        }
    }

    fun togglePinConversation(conversationId: String) {
        val target = _conversations.value.firstOrNull { it.id == conversationId } ?: return
        val newValue = !target.isPinned
        _conversations.value = _conversations.value.map { if (it.id == conversationId) it.copy(isPinned = newValue) else it }
        scope.launch {
            runCatching { apiClient.api.updatePreferences(conversationId, ConversationPreferencesRequest(isPinned = newValue)) }
                .onFailure {
                    _conversations.value = _conversations.value.map { if (it.id == conversationId) it.copy(isPinned = !newValue) else it }
                }
        }
    }

    fun markRead(conversationId: String) {
        scope.launch { runCatching { apiClient.api.markRead(conversationId) } }
    }

    fun markViewOnceOpened(conversationId: String, messageId: String) {
        mutateMessage(conversationId, messageId) { it.copy(isViewOnceOpened = true) }
    }

    fun addReaction(conversationId: String, messageId: String, emoji: String) {
        mutateMessage(conversationId, messageId) { it.copy(reactions = it.reactions + emoji) }
    }

    fun togglePinMessage(conversationId: String, messageId: String) {
        mutateMessage(conversationId, messageId) { it.copy(isPinned = !it.isPinned) }
    }

    fun updateGroupInfo(conversationId: String, title: String, avatarUrl: String) {
        _conversations.value = _conversations.value.map {
            if (it.id == conversationId) it.copy(
                title = title.ifBlank { it.title },
                avatarUrl = avatarUrl.ifBlank { it.avatarUrl }
            ) else it
        }
    }

    fun addMemberToGroup(conversationId: String, user: User) {
        _conversations.value = _conversations.value.map {
            if (it.id == conversationId && it.members.none { member -> member.id == user.id }) it.copy(members = it.members + user) else it
        }
    }

    fun removeMemberFromGroup(conversationId: String, memberId: String) {
        _conversations.value = _conversations.value.map {
            if (it.id == conversationId) it.copy(members = it.members.filterNot { member -> member.id == memberId }) else it
        }
    }

    fun toggleGroupEncryption(conversationId: String) {
        _conversations.value = _conversations.value.map {
            if (it.id == conversationId) it.copy(isEncrypted = !it.isEncrypted) else it
        }
    }

    fun leaveGroup(conversationId: String) {
        _conversations.value = _conversations.value.filterNot { it.id == conversationId }
        _messagesMap.value = _messagesMap.value - conversationId
    }

    fun startRealtime() {
        if (webSocket != null) return
        val token = tokenStore.accessToken ?: return
        val request = Request.Builder()
            .url(BuildConfig.CHATNU_WS_URL)
            .header("Authorization", "Bearer $token")
            .build()
        webSocket = apiClient.httpClient.newWebSocket(request, object : WebSocketListener() {
            override fun onMessage(webSocket: WebSocket, text: String) {
                handleRealtime(text)
            }

            override fun onMessage(webSocket: WebSocket, bytes: ByteString) {
                handleRealtime(bytes.utf8())
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                this@RemoteChatRepository.webSocket = null
                if (authRepository.isLoggedIn.value) {
                    scope.launch {
                        delay(3_000)
                        startRealtime()
                    }
                }
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                this@RemoteChatRepository.webSocket = null
            }
        })
    }

    fun closeRealtime() {
        webSocket?.close(1000, "logout")
        webSocket = null
    }

    private fun handleRealtime(text: String) {
        runCatching {
            val event = JSONObject(text)
            if (event.optString("type") != "message.created") return
            val json = event.getJSONObject("message")
            val dto = MessageDto(
                id = json.getString("id"),
                clientId = json.optNullableString("clientId"),
                conversationId = json.getString("conversationId"),
                senderId = json.getString("senderId"),
                senderUsername = json.optNullableString("senderUsername"),
                senderName = json.optString("senderName", "Unknown"),
                type = json.optString("type", "TEXT"),
                ciphertext = json.getString("ciphertext"),
                nonce = json.optNullableString("nonce"),
                protocolVersion = json.optNullableString("protocolVersion"),
                createdAt = json.optString("createdAt", "")
            )
            val message = dto.toModel()
            val existing = _messagesMap.value[message.conversationId].orEmpty()
            if (existing.none { it.id == message.id || (dto.clientId != null && it.id == dto.clientId) }) {
                appendMessage(message.conversationId, message)
            }
            scope.launch { runCatching { refreshConversations() } }
        }
    }

    private fun ConversationDto.toModel(): Conversation {
        val preview = lastMessage?.let { decrypt(it) }.orEmpty()
        return Conversation(
            id = id,
            title = title,
            type = if (type == "GROUP") ConversationType.GROUP else ConversationType.DIRECT,
            avatarUrl = avatarUrl,
            lastMessageText = preview,
            lastMessageTime = lastMessage?.createdAt?.toDisplayTime().orEmpty(),
            unreadCount = unreadCount,
            isPinned = isPinned,
            isMuted = isMuted,
            isEncrypted = true,
            members = members.map { it.toModel() }
        )
    }

    private fun MessageDto.toModel(): Message = Message(
        id = id,
        conversationId = conversationId,
        senderId = senderId,
        senderName = senderName,
        text = decrypt(this),
        type = type.fromServerType(),
        status = MessageStatus.READ,
        timestamp = createdAt.toDisplayTime(),
        timestampMillis = System.currentTimeMillis()
    )

    private fun decrypt(message: MessageDto): String = CryptoEngine.decryptPayload(
        EncryptedEnvelope(
            ciphertext = message.ciphertext,
            nonceBase64 = message.nonce.orEmpty(),
            protocolVersion = message.protocolVersion ?: "legacy"
        )
    )

    private fun String.toDisplayTime(): String {
        if (length >= 16 && getOrNull(10) == 'T') return substring(11, 16)
        return ifBlank { "now" }
    }

    private fun mergeConversation(conversation: Conversation) {
        _conversations.value = listOf(conversation) + _conversations.value.filterNot { it.id == conversation.id }
    }

    private fun appendMessage(conversationId: String, message: Message) {
        val map = _messagesMap.value.toMutableMap()
        map[conversationId] = map[conversationId].orEmpty() + message
        _messagesMap.value = map
    }

    private fun replaceMessage(conversationId: String, oldId: String, replacement: Message) {
        val map = _messagesMap.value.toMutableMap()
        map[conversationId] = map[conversationId].orEmpty().map { if (it.id == oldId) replacement else it }
        _messagesMap.value = map
    }

    private fun updateMessageStatus(conversationId: String, messageId: String, status: MessageStatus) {
        mutateMessage(conversationId, messageId) { it.copy(status = status) }
    }

    private fun mutateMessage(conversationId: String, messageId: String, transform: (Message) -> Message) {
        val map = _messagesMap.value.toMutableMap()
        map[conversationId] = map[conversationId].orEmpty().map { if (it.id == messageId) transform(it) else it }
        _messagesMap.value = map
    }

    private fun MessageType.toServerType(): String = when (this) {
        MessageType.SYSTEM_KEY_CHANGE -> "SYSTEM"
        else -> name
    }

    private fun String.fromServerType(): MessageType = when (this) {
        "SYSTEM" -> MessageType.SYSTEM_KEY_CHANGE
        else -> runCatching { MessageType.valueOf(this) }.getOrDefault(MessageType.TEXT)
    }

    private fun JSONObject.optNullableString(key: String): String? {
        if (!has(key) || isNull(key)) return null
        return optString(key).takeIf { it.isNotBlank() && it != "null" }
    }
}
