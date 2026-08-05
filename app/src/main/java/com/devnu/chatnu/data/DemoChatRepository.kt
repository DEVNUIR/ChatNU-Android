package com.devnu.chatnu.data

import com.devnu.chatnu.core.model.ChatMessage
import com.devnu.chatnu.core.model.Conversation
import com.devnu.chatnu.core.model.DeliveryState
import com.devnu.chatnu.core.model.MessageKind
import com.devnu.chatnu.core.model.Presence
import com.devnu.chatnu.core.model.RelayNode
import com.devnu.chatnu.core.model.UserProfile
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class DemoChatRepository {
    private val users = listOf(
        UserProfile("u1", "nora.mesh", "Nora", 1, Presence.ONLINE, true),
        UserProfile("u2", "farid.dev", "Farid", 2, Presence.AWAY),
        UserProfile("u3", "lena.node", "Lena", 3, Presence.ONLINE, true),
        UserProfile("u4", "openmesh", "Open Mesh", 4, Presence.ONLINE),
        UserProfile("u5", "hadi.lab", "Hadi", 5, Presence.OFFLINE),
    )

    private val _conversations = MutableStateFlow(
        listOf(
            Conversation("c1", users[0], "The new relay build is finally stable.", "18:02", 2, pinned = true),
            Conversation("c2", users[1], "Voice message · 0:18", "17:41"),
            Conversation("c3", users[2], "Typing…", "now", typing = true),
            Conversation("c4", users[3], "12 members joined the local node", "Mon", muted = true),
            Conversation("c5", users[4], "Send me the new fingerprint", "Sun"),
        ),
    )
    val conversations: StateFlow<List<Conversation>> = _conversations.asStateFlow()

    private val messageStore = mutableMapOf(
        "c1" to MutableStateFlow(
            listOf(
                ChatMessage("m1", "c1", "u1", "Your identity key changed after the reinstall.", "17:49", false, MessageKind.SYSTEM),
                ChatMessage("m2", "c1", "u1", "I moved my account to the Helsinki relay. The connection is much cleaner now.", "17:51", false),
                ChatMessage("m3", "c1", "me", "Perfect. ChatNU should switch automatically when latency spikes.", "17:53", true),
                ChatMessage("m4", "c1", "u1", "The new relay build is finally stable.", "18:02", false, reaction = "⚡"),
                ChatMessage("m5", "c1", "me", "I’ll test the encrypted attachment flow tonight.", "18:03", true, delivery = DeliveryState.READ),
            ),
        ),
    )

    private val _nodes = MutableStateFlow(
        listOf(
            RelayNode("n1", "DEVNU Helsinki", "wss://hel-1.chatnu.dev", 18, true, true, "Finland"),
            RelayNode("n2", "Community Frankfurt", "wss://fra.community.chat", 41, false, true, "Germany"),
            RelayNode("n3", "Personal Node", "wss://home-node.local", 8, false, false, "Local"),
        ),
    )
    val nodes: StateFlow<List<RelayNode>> = _nodes.asStateFlow()

    fun messages(conversationId: String): StateFlow<List<ChatMessage>> =
        messageStore.getOrPut(conversationId) { MutableStateFlow(emptyList()) }.asStateFlow()

    fun conversation(conversationId: String): Conversation? = _conversations.value.firstOrNull { it.id == conversationId }

    fun send(conversationId: String, body: String) {
        val text = body.trim()
        if (text.isEmpty()) return
        val flow = messageStore.getOrPut(conversationId) { MutableStateFlow(emptyList()) }
        flow.value += ChatMessage(
            id = "local-${System.nanoTime()}",
            conversationId = conversationId,
            senderId = "me",
            body = text,
            timestamp = "now",
            mine = true,
            delivery = DeliveryState.SENDING,
        )
    }

    fun connectNode(nodeId: String) {
        _nodes.value = _nodes.value.map { it.copy(connected = it.id == nodeId) }
    }
}
