package com.example.remote

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import com.example.BuildConfig
import com.example.crypto.CryptoEngine
import com.example.crypto.DeviceE2ee
import com.example.crypto.EncryptedEnvelope
import com.example.crypto.RecipientDeviceKey
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
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.MultipartBody
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import okio.ByteString
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.UUID

enum class RealtimeStatus { DISCONNECTED, CONNECTING, CONNECTED }

data class CallSignalEvent(
    val type: String,
    val callId: String,
    val conversationId: String,
    val fromUserId: String? = null,
    val targetUserId: String? = null,
    val sdp: String? = null,
    val candidate: String? = null,
    val sdpMid: String? = null,
    val sdpMLineIndex: Int? = null,
    val video: Boolean = false
)

class RemoteChatRepository(
    private val context: Context,
    private val apiClient: ApiClient,
    private val tokenStore: TokenStore,
    private val authRepository: RemoteAuthRepository,
    private val deviceE2ee: DeviceE2ee
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val _conversations = MutableStateFlow<List<Conversation>>(emptyList())
    val conversations: StateFlow<List<Conversation>> = _conversations.asStateFlow()

    private val _messagesMap = MutableStateFlow<Map<String, List<Message>>>(emptyMap())
    val messagesMap: StateFlow<Map<String, List<Message>>> = _messagesMap.asStateFlow()

    private val _realtimeStatus = MutableStateFlow(RealtimeStatus.DISCONNECTED)
    val realtimeStatus: StateFlow<RealtimeStatus> = _realtimeStatus.asStateFlow()

    private val _callEvents = MutableSharedFlow<CallSignalEvent>(extraBufferCapacity = 64)
    val callEvents: SharedFlow<CallSignalEvent> = _callEvents.asSharedFlow()

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
        val dto = apiClient.api.createGroup(
            GroupConversationRequest(title.trim(), usernames.map { it.trim().lowercase() })
        ).conversation
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
        sendEncryptedPayload(
            conversationId = conversationId,
            plaintext = text,
            displayText = text,
            type = type,
            mediaUrl = mediaUrl,
            voiceDurationSeconds = voiceDurationSeconds,
            latitude = latitude,
            longitude = longitude,
            fileName = fileName,
            fileSize = fileSize,
            fileExtension = fileExtension
        )
    }

    fun sendAttachment(conversationId: String, uri: Uri) {
        val me = authRepository.currentUser.value ?: return
        val info = resolveAttachmentInfo(uri)
        val clientId = UUID.randomUUID().toString()
        val type = typeForMime(info.mimeType)
        val optimistic = Message(
            id = clientId,
            conversationId = conversationId,
            senderId = me.id,
            senderName = me.displayName,
            text = info.name,
            type = type,
            status = MessageStatus.SENDING,
            timestamp = "now",
            timestampMillis = System.currentTimeMillis(),
            fileName = info.name,
            fileSize = info.size.takeIf { it >= 0 }?.let(::formatBytes),
            fileExtension = info.name.substringAfterLast('.', "").takeIf { it.isNotBlank() },
            mimeType = info.mimeType,
            localUri = uri.toString()
        )
        appendMessage(conversationId, optimistic)

        scope.launch {
            runCatching {
                val raw = context.contentResolver.openInputStream(uri)?.use { stream ->
                    val bytes = stream.readBytes()
                    require(bytes.size <= MAX_ATTACHMENT_PLAINTEXT_BYTES) {
                        "Attachment is larger than 24 MiB"
                    }
                    bytes
                } ?: error("Could not read the selected file")

                val encrypted = deviceE2ee.encryptAttachment(raw)
                val body = encrypted.ciphertext.toRequestBody("application/octet-stream".toMediaType())
                val part = MultipartBody.Part.createFormData("file", "chatnu.enc", body)
                val conversationBody = conversationId.toRequestBody("text/plain".toMediaType())
                val uploaded = apiClient.api.uploadAttachment(conversationBody, part).attachment

                val payload = JSONObject()
                    .put("kind", "attachment")
                    .put("attachmentId", uploaded.id)
                    .put("name", info.name)
                    .put("mime", info.mimeType)
                    .put("size", raw.size)
                    .put("fileKey", encrypted.keyBase64)
                    .put("fileNonce", encrypted.nonceBase64)
                    .toString()

                sendEncryptedPayloadAwait(
                    conversationId = conversationId,
                    clientId = clientId,
                    plaintext = payload,
                    displayText = info.name,
                    type = type,
                    fileName = info.name,
                    fileSize = formatBytes(raw.size.toLong()),
                    fileExtension = info.name.substringAfterLast('.', "").takeIf { it.isNotBlank() },
                    attachmentId = uploaded.id,
                    mimeType = info.mimeType,
                    attachmentKeyBase64 = encrypted.keyBase64,
                    attachmentNonceBase64 = encrypted.nonceBase64,
                    localUri = uri.toString()
                )
            }.onSuccess { serverMessage ->
                replaceMessage(conversationId, clientId, serverMessage)
                runCatching { refreshConversations() }
            }.onFailure {
                updateMessageStatus(conversationId, clientId, MessageStatus.FAILED)
            }
        }
    }

    suspend fun downloadAttachment(message: Message): File {
        val attachmentId = message.attachmentId ?: error("Message does not contain an attachment")
        val fileKey = message.attachmentKeyBase64 ?: error("Attachment key is unavailable")
        val fileNonce = message.attachmentNonceBase64 ?: error("Attachment nonce is unavailable")
        val encrypted = apiClient.api.downloadAttachment(attachmentId).bytes()
        val plaintext = deviceE2ee.decryptAttachment(encrypted, fileKey, fileNonce)
        val dir = File(context.cacheDir, "chatnu_attachments").apply { mkdirs() }
        val safeName = sanitizeFilename(message.fileName ?: "attachment")
        val out = File(dir, "${attachmentId.take(12)}-$safeName")
        out.writeBytes(plaintext)
        return out
    }

    private fun sendEncryptedPayload(
        conversationId: String,
        plaintext: String,
        displayText: String,
        type: MessageType,
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
        val optimistic = Message(
            id = clientId,
            conversationId = conversationId,
            senderId = me.id,
            senderName = me.displayName,
            text = displayText,
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
                sendEncryptedPayloadAwait(
                    conversationId = conversationId,
                    clientId = clientId,
                    plaintext = plaintext,
                    displayText = displayText,
                    type = type,
                    mediaUrl = mediaUrl,
                    voiceDurationSeconds = voiceDurationSeconds,
                    latitude = latitude,
                    longitude = longitude,
                    fileName = fileName,
                    fileSize = fileSize,
                    fileExtension = fileExtension
                )
            }.onSuccess { serverMessage ->
                replaceMessage(conversationId, clientId, serverMessage)
                runCatching { refreshConversations() }
            }.onFailure {
                updateMessageStatus(conversationId, clientId, MessageStatus.FAILED)
            }
        }
    }

    private suspend fun sendEncryptedPayloadAwait(
        conversationId: String,
        clientId: String,
        plaintext: String,
        displayText: String,
        type: MessageType,
        mediaUrl: String? = null,
        voiceDurationSeconds: Int = 0,
        latitude: Double? = null,
        longitude: Double? = null,
        fileName: String? = null,
        fileSize: String? = null,
        fileExtension: String? = null,
        attachmentId: String? = null,
        mimeType: String? = null,
        attachmentKeyBase64: String? = null,
        attachmentNonceBase64: String? = null,
        localUri: String? = null
    ): Message {
        val keys = apiClient.api.conversationKeys(conversationId)
        if (keys.missingUserIds.isNotEmpty()) {
            error("Some members must open the updated ChatNU app before encrypted messages can be sent")
        }
        val recipientKeys = keys.devices.map {
            RecipientDeviceKey(deviceId = it.deviceId, publicKeyBase64 = it.publicKey)
        }
        val serverType = type.toServerType()
        val aad = messageAad(conversationId, clientId, serverType)
        val envelope = deviceE2ee.encryptMessage(
            plaintext = plaintext.toByteArray(Charsets.UTF_8),
            recipientKeys = recipientKeys,
            aad = aad
        )
        val metadata = mapOf<String, Any?>(
            "wrappedKeys" to envelope.wrappedKeys,
            "senderDeviceId" to tokenStore.deviceId,
            "e2ee" to true
        )
        val dto = apiClient.api.sendMessage(
            SendMessageRequest(
                conversationId = conversationId,
                clientId = clientId,
                type = serverType,
                ciphertext = envelope.ciphertextBase64,
                nonce = envelope.nonceBase64,
                protocolVersion = envelope.protocolVersion,
                metadata = metadata
            )
        ).message
        return dto.toModel().copy(
            text = displayText,
            mediaUrl = mediaUrl,
            voiceDurationSeconds = voiceDurationSeconds,
            latitude = latitude,
            longitude = longitude,
            fileName = fileName,
            fileSize = fileSize,
            fileExtension = fileExtension,
            attachmentId = attachmentId,
            mimeType = mimeType,
            attachmentKeyBase64 = attachmentKeyBase64,
            attachmentNonceBase64 = attachmentNonceBase64,
            localUri = localUri,
            status = MessageStatus.SENT
        )
    }

    fun togglePinConversation(conversationId: String) {
        val target = _conversations.value.firstOrNull { it.id == conversationId } ?: return
        val newValue = !target.isPinned
        _conversations.value = _conversations.value.map {
            if (it.id == conversationId) it.copy(isPinned = newValue) else it
        }
        scope.launch {
            runCatching {
                apiClient.api.updatePreferences(
                    conversationId,
                    ConversationPreferencesRequest(isPinned = newValue)
                )
            }.onFailure {
                _conversations.value = _conversations.value.map {
                    if (it.id == conversationId) it.copy(isPinned = !newValue) else it
                }
            }
        }
    }

    fun markRead(conversationId: String) {
        scope.launch { runCatching { apiClient.api.markRead(conversationId) } }
    }

    suspend fun rtcConfig(): RtcConfigResponse = apiClient.api.rtcConfig()

    suspend fun emitPendingCalls() {
        apiClient.api.pendingCalls().calls.forEach { call ->
            _callEvents.emit(
                CallSignalEvent(
                    type = call.type,
                    callId = call.callId,
                    conversationId = call.conversationId,
                    fromUserId = call.fromUserId,
                    targetUserId = call.targetUserId,
                    sdp = call.sdp,
                    video = call.video
                )
            )
        }
    }

    fun sendCallSignal(event: CallSignalEvent): Boolean {
        val socket = webSocket ?: return false
        val target = event.targetUserId ?: return false
        val json = JSONObject()
            .put("type", event.type)
            .put("callId", event.callId)
            .put("conversationId", event.conversationId)
            .put("targetUserId", target)
            .put("video", event.video)
        event.sdp?.let { json.put("sdp", it) }
        event.candidate?.let { json.put("candidate", it) }
        if (event.sdpMid != null) json.put("sdpMid", event.sdpMid)
        if (event.sdpMLineIndex != null) json.put("sdpMLineIndex", event.sdpMLineIndex)
        return socket.send(json.toString())
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
            if (it.id == conversationId && it.members.none { member -> member.id == user.id }) {
                it.copy(members = it.members + user)
            } else it
        }
    }

    fun removeMemberFromGroup(conversationId: String, memberId: String) {
        _conversations.value = _conversations.value.map {
            if (it.id == conversationId) {
                it.copy(members = it.members.filterNot { member -> member.id == memberId })
            } else it
        }
    }

    fun toggleGroupEncryption(conversationId: String) = Unit

    fun leaveGroup(conversationId: String) {
        _conversations.value = _conversations.value.filterNot { it.id == conversationId }
        _messagesMap.value = _messagesMap.value - conversationId
    }

    fun startRealtime() {
        if (webSocket != null) return
        val token = tokenStore.accessToken ?: run {
            _realtimeStatus.value = RealtimeStatus.DISCONNECTED
            return
        }
        _realtimeStatus.value = RealtimeStatus.CONNECTING
        val request = Request.Builder()
            .url(BuildConfig.CHATNU_WS_URL)
            .header("Authorization", "Bearer $token")
            .build()
        webSocket = apiClient.httpClient.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                _realtimeStatus.value = RealtimeStatus.CONNECTED
                scope.launch { runCatching { emitPendingCalls() } }
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                handleRealtime(text)
            }

            override fun onMessage(webSocket: WebSocket, bytes: ByteString) {
                handleRealtime(bytes.utf8())
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                this@RemoteChatRepository.webSocket = null
                _realtimeStatus.value = RealtimeStatus.DISCONNECTED
                if (authRepository.isLoggedIn.value) {
                    scope.launch {
                        delay(3_000)
                        startRealtime()
                    }
                }
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                this@RemoteChatRepository.webSocket = null
                _realtimeStatus.value = RealtimeStatus.DISCONNECTED
            }
        })
    }

    fun closeRealtime() {
        webSocket?.close(1000, "logout")
        webSocket = null
        _realtimeStatus.value = RealtimeStatus.DISCONNECTED
    }

    private fun handleRealtime(text: String) {
        runCatching {
            val event = JSONObject(text)
            val eventType = event.optString("type")
            when {
                eventType == "message.created" -> {
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
                        metadata = json.optJSONObject("metadata")?.toKotlinMap(),
                        createdAt = json.optString("createdAt", "")
                    )
                    val message = dto.toModel()
                    val existing = _messagesMap.value[message.conversationId].orEmpty()
                    if (existing.none { it.id == message.id || (dto.clientId != null && it.id == dto.clientId) }) {
                        appendMessage(message.conversationId, message)
                    }
                    scope.launch { runCatching { refreshConversations() } }
                }

                eventType == "conversation.created" -> {
                    scope.launch { runCatching { refreshConversations() } }
                }

                eventType.startsWith("call.") -> {
                    _callEvents.tryEmit(
                        CallSignalEvent(
                            type = eventType,
                            callId = event.getString("callId"),
                            conversationId = event.getString("conversationId"),
                            fromUserId = event.optNullableString("fromUserId"),
                            targetUserId = event.optNullableString("targetUserId"),
                            sdp = event.optNullableString("sdp"),
                            candidate = event.optNullableString("candidate"),
                            sdpMid = event.optNullableString("sdpMid"),
                            sdpMLineIndex = if (event.has("sdpMLineIndex") && !event.isNull("sdpMLineIndex")) {
                                event.optInt("sdpMLineIndex")
                            } else null,
                            video = event.optBoolean("video", false)
                        )
                    )
                }
            }
        }
    }

    private fun ConversationDto.toModel(): Conversation {
        val preview = lastMessage?.let { decryptPayload(it).displayText }.orEmpty()
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

    private fun MessageDto.toModel(): Message {
        val decrypted = decryptPayload(this)
        return Message(
            id = id,
            conversationId = conversationId,
            senderId = senderId,
            senderName = senderName,
            text = decrypted.displayText,
            type = type.fromServerType(),
            status = MessageStatus.READ,
            timestamp = createdAt.toDisplayTime(),
            timestampMillis = createdAt.toEpochMillis(),
            fileName = decrypted.fileName,
            fileSize = decrypted.sizeBytes?.let(::formatBytes),
            fileExtension = decrypted.fileName?.substringAfterLast('.', "")?.takeIf { it.isNotBlank() },
            attachmentId = decrypted.attachmentId,
            mimeType = decrypted.mimeType,
            attachmentKeyBase64 = decrypted.fileKey,
            attachmentNonceBase64 = decrypted.fileNonce
        )
    }

    private fun decryptPayload(message: MessageDto): DecryptedPayload {
        val plain = runCatching {
            if (message.protocolVersion == DeviceE2ee.PROTOCOL_VERSION) {
                val account = tokenStore.cryptoAccount ?: authRepository.currentUser.value?.username
                    ?: error("No crypto account")
                val deviceId = tokenStore.deviceId ?: error("No device id")
                val clientId = message.clientId ?: error("Encrypted message has no client id")
                val aad = messageAad(message.conversationId, clientId, message.type)
                String(
                    deviceE2ee.decryptMessage(
                        account = account,
                        deviceId = deviceId,
                        ciphertextBase64 = message.ciphertext,
                        nonceBase64 = message.nonce.orEmpty(),
                        metadata = message.metadata,
                        aad = aad
                    ),
                    Charsets.UTF_8
                )
            } else {
                CryptoEngine.decryptPayload(
                    EncryptedEnvelope(
                        ciphertext = message.ciphertext,
                        nonceBase64 = message.nonce.orEmpty(),
                        protocolVersion = message.protocolVersion ?: "legacy"
                    )
                )
            }
        }.getOrElse {
            return DecryptedPayload(displayText = "🔒 Encrypted message unavailable on this device")
        }

        return parseDecryptedPayload(plain)
    }

    private fun parseDecryptedPayload(plain: String): DecryptedPayload {
        return runCatching {
            val json = JSONObject(plain)
            if (json.optString("kind") != "attachment") return@runCatching DecryptedPayload(plain)
            DecryptedPayload(
                displayText = json.optString("name", "Attachment"),
                attachmentId = json.getString("attachmentId"),
                fileName = json.optString("name", "Attachment"),
                mimeType = json.optString("mime", "application/octet-stream"),
                sizeBytes = json.optLong("size").takeIf { it >= 0 },
                fileKey = json.getString("fileKey"),
                fileNonce = json.getString("fileNonce")
            )
        }.getOrElse { DecryptedPayload(displayText = plain) }
    }

    private fun String.toDisplayTime(): String {
        if (length >= 16 && getOrNull(10) == 'T') return substring(11, 16)
        return ifBlank { "now" }
    }

    private fun String.toEpochMillis(): Long {
        val patterns = listOf("yyyy-MM-dd'T'HH:mm:ss.SSSX", "yyyy-MM-dd'T'HH:mm:ssX")
        for (pattern in patterns) {
            val parsed = runCatching { SimpleDateFormat(pattern, Locale.US).parse(this)?.time }.getOrNull()
            if (parsed != null) return parsed
        }
        return System.currentTimeMillis()
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
        map[conversationId] = map[conversationId].orEmpty().map {
            if (it.id == messageId) transform(it) else it
        }
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

    private fun messageAad(conversationId: String, clientId: String, serverType: String): String =
        "$conversationId|$clientId|$serverType"

    private fun resolveAttachmentInfo(uri: Uri): AttachmentInfo {
        var name = "attachment"
        var size = -1L
        context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
            if (cursor.moveToFirst()) {
                if (nameIndex >= 0) name = cursor.getString(nameIndex) ?: name
                if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) size = cursor.getLong(sizeIndex)
            }
        }
        val mime = context.contentResolver.getType(uri) ?: "application/octet-stream"
        return AttachmentInfo(name = sanitizeFilename(name), size = size, mimeType = mime)
    }

    private fun typeForMime(mime: String): MessageType = when {
        mime.startsWith("image/") -> MessageType.IMAGE
        mime.startsWith("video/") -> MessageType.VIDEO
        mime.startsWith("audio/") -> MessageType.VOICE
        else -> MessageType.FILE
    }

    private fun sanitizeFilename(value: String): String {
        val cleaned = value.replace(Regex("[\\\\/:*?\"<>|\\u0000-\\u001F]"), "_").trim()
        return cleaned.take(120).ifBlank { "attachment" }
    }

    private fun formatBytes(value: Long): String = when {
        value >= 1024L * 1024L -> String.format(Locale.US, "%.1f MB", value / (1024.0 * 1024.0))
        value >= 1024L -> String.format(Locale.US, "%.1f KB", value / 1024.0)
        else -> "$value B"
    }

    private fun JSONObject.optNullableString(key: String): String? {
        if (!has(key) || isNull(key)) return null
        return optString(key).takeIf { it.isNotBlank() && it != "null" }
    }

    private fun JSONObject.toKotlinMap(): Map<String, Any?> {
        val result = linkedMapOf<String, Any?>()
        keys().forEach { key -> result[key] = unwrapJson(opt(key)) }
        return result
    }

    private fun unwrapJson(value: Any?): Any? = when (value) {
        JSONObject.NULL -> null
        is JSONObject -> value.toKotlinMap()
        is JSONArray -> (0 until value.length()).map { unwrapJson(value.opt(it)) }
        else -> value
    }

    private data class AttachmentInfo(val name: String, val size: Long, val mimeType: String)

    private data class DecryptedPayload(
        val displayText: String,
        val attachmentId: String? = null,
        val fileName: String? = null,
        val mimeType: String? = null,
        val sizeBytes: Long? = null,
        val fileKey: String? = null,
        val fileNonce: String? = null
    )

    companion object {
        private const val MAX_ATTACHMENT_PLAINTEXT_BYTES = 24 * 1024 * 1024
    }
}
