package com.example.data

import com.example.crypto.CryptoEngine
import com.example.model.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class ChatRepository {
    private val _conversations = MutableStateFlow<List<Conversation>>(MockBackend.initialConversations)
    val conversations: StateFlow<List<Conversation>> = _conversations.asStateFlow()

    private val _messagesMap = MutableStateFlow<Map<String, List<Message>>>(MockBackend.initialMessagesMap)
    val messagesMap: StateFlow<Map<String, List<Message>>> = _messagesMap.asStateFlow()

    fun getMessages(conversationId: String): List<Message> {
        return _messagesMap.value[conversationId] ?: emptyList()
    }

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
        val encryptedEnvelope = CryptoEngine.encryptPayload(text)
        val decryptedText = CryptoEngine.decryptPayload(encryptedEnvelope)

        val newMsgId = "msg_" + System.currentTimeMillis()
        val newMsg = Message(
            id = newMsgId,
            conversationId = conversationId,
            senderId = MockBackend.currentUser.id,
            senderName = MockBackend.currentUser.displayName,
            text = decryptedText,
            type = type,
            status = MessageStatus.SENT, // Single Tick
            timestamp = "Just now",
            mediaUrl = mediaUrl,
            voiceDurationSeconds = voiceDurationSeconds,
            latitude = latitude,
            longitude = longitude,
            fileName = fileName,
            fileSize = fileSize,
            fileExtension = fileExtension
        )

        val currentList = (_messagesMap.value[conversationId] ?: emptyList()).toMutableList()
        currentList.add(newMsg)

        val updatedMap = _messagesMap.value.toMutableMap()
        updatedMap[conversationId] = currentList
        _messagesMap.value = updatedMap

        // Update conversation last message preview
        val updatedConvs = _conversations.value.map { conv ->
            if (conv.id == conversationId) {
                conv.copy(
                    lastMessageText = if (type == MessageType.VOICE) "🎤 Voice note" else text,
                    lastMessageTime = "Just now"
                )
            } else conv
        }
        _conversations.value = updatedConvs

        // Simulate delivery tick (double tick) and read tick (blue double tick)
        kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Default).launch {
            kotlinx.coroutines.delay(1200)
            updateMessageStatus(conversationId, newMsgId, MessageStatus.DELIVERED)
            kotlinx.coroutines.delay(1500)
            updateMessageStatus(conversationId, newMsgId, MessageStatus.READ)
        }
    }

    private fun updateMessageStatus(conversationId: String, messageId: String, status: MessageStatus) {
        val currentList = (_messagesMap.value[conversationId] ?: emptyList()).map { msg ->
            if (msg.id == messageId) {
                msg.copy(status = status)
            } else msg
        }
        val updatedMap = _messagesMap.value.toMutableMap()
        updatedMap[conversationId] = currentList
        _messagesMap.value = updatedMap
    }

    fun togglePinConversation(conversationId: String) {
        _conversations.value = _conversations.value.map { conv ->
            if (conv.id == conversationId) {
                conv.copy(isPinned = !conv.isPinned)
            } else conv
        }
    }

    fun markViewOnceOpened(conversationId: String, messageId: String) {
        val currentList = (_messagesMap.value[conversationId] ?: emptyList()).map { msg ->
            if (msg.id == messageId) {
                msg.copy(isViewOnceOpened = true)
            } else msg
        }
        val updatedMap = _messagesMap.value.toMutableMap()
        updatedMap[conversationId] = currentList
        _messagesMap.value = updatedMap
    }

    fun addReaction(conversationId: String, messageId: String, emoji: String) {
        val currentList = (_messagesMap.value[conversationId] ?: emptyList()).map { msg ->
            if (msg.id == messageId) {
                val updatedReactions = msg.reactions.toMutableList().apply { add(emoji) }
                msg.copy(reactions = updatedReactions)
            } else msg
        }
        val updatedMap = _messagesMap.value.toMutableMap()
        updatedMap[conversationId] = currentList
        _messagesMap.value = updatedMap
    }

    fun togglePinMessage(conversationId: String, messageId: String) {
        val currentList = (_messagesMap.value[conversationId] ?: emptyList()).map { msg ->
            if (msg.id == messageId) {
                msg.copy(isPinned = !msg.isPinned)
            } else msg
        }
        val updatedMap = _messagesMap.value.toMutableMap()
        updatedMap[conversationId] = currentList
        _messagesMap.value = updatedMap
    }

    fun createGroup(title: String, description: String = ""): Conversation {
        val newGroup = Conversation(
            id = "conv_group_" + System.currentTimeMillis(),
            title = title,
            type = ConversationType.GROUP,
            avatarUrl = "https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=150",
            lastMessageText = "Group created. Encrypted session established.",
            lastMessageTime = "Just now",
            unreadCount = 0,
            isPinned = true,
            isEncrypted = true,
            members = listOf(MockBackend.currentUser)
        )

        _conversations.value = listOf(newGroup) + _conversations.value

        val initialSysMsg = Message(
            id = "msg_sys_" + System.currentTimeMillis(),
            conversationId = newGroup.id,
            senderId = "system",
            senderName = "System",
            text = "Group \"$title\" created with Signal E2EE. $description",
            type = MessageType.SYSTEM_KEY_CHANGE,
            status = MessageStatus.READ,
            timestamp = "Just now"
        )

        val updatedMap = _messagesMap.value.toMutableMap()
        updatedMap[newGroup.id] = listOf(initialSysMsg)
        _messagesMap.value = updatedMap

        return newGroup
    }

    fun updateGroupInfo(conversationId: String, title: String, avatarUrl: String) {
        _conversations.value = _conversations.value.map { conv ->
            if (conv.id == conversationId) {
                conv.copy(
                    title = title.ifBlank { conv.title },
                    avatarUrl = avatarUrl.ifBlank { conv.avatarUrl }
                )
            } else conv
        }
    }

    fun addMemberToGroup(conversationId: String, user: User) {
        _conversations.value = _conversations.value.map { conv ->
            if (conv.id == conversationId) {
                val currentMembers = conv.members.toMutableList()
                if (currentMembers.none { it.id == user.id }) {
                    currentMembers.add(user)
                }
                conv.copy(members = currentMembers)
            } else conv
        }
    }

    fun removeMemberFromGroup(conversationId: String, memberId: String) {
        _conversations.value = _conversations.value.map { conv ->
            if (conv.id == conversationId) {
                val updatedMembers = conv.members.filterNot { it.id == memberId }
                conv.copy(members = updatedMembers)
            } else conv
        }
    }

    fun toggleGroupEncryption(conversationId: String) {
        _conversations.value = _conversations.value.map { conv ->
            if (conv.id == conversationId) {
                conv.copy(isEncrypted = !conv.isEncrypted)
            } else conv
        }
    }

    fun leaveGroup(conversationId: String) {
        _conversations.value = _conversations.value.filterNot { it.id == conversationId }
    }
}
