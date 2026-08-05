package com.devnu.chatnu.feature.chat

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.devnu.chatnu.core.model.ChatMessage
import com.devnu.chatnu.core.model.Conversation
import com.devnu.chatnu.domain.ChatRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class ConversationUiState(
    val conversation: Conversation? = null,
    val messages: List<ChatMessage> = emptyList(),
    val draft: String = "",
    val replyingTo: ChatMessage? = null,
    val recording: Boolean = false,
    val attachmentTrayVisible: Boolean = false,
)

class ConversationViewModel(
    private val repository: ChatRepository,
    private val conversationId: String,
) : ViewModel() {
    private val draft = MutableStateFlow("")
    private val replyingTo = MutableStateFlow<ChatMessage?>(null)
    private val recording = MutableStateFlow(false)
    private val attachmentTrayVisible = MutableStateFlow(false)
    private val conversation = repository.conversations.map { items -> items.firstOrNull { it.id == conversationId } }

    val state = combine(
        conversation,
        repository.messages(conversationId),
        draft,
        replyingTo,
        recording,
        attachmentTrayVisible,
    ) { values ->
        ConversationUiState(
            conversation = values[0] as Conversation?,
            messages = @Suppress("UNCHECKED_CAST") (values[1] as List<ChatMessage>),
            draft = values[2] as String,
            replyingTo = values[3] as ChatMessage?,
            recording = values[4] as Boolean,
            attachmentTrayVisible = values[5] as Boolean,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), ConversationUiState())

    fun updateDraft(value: String) { draft.value = value }
    fun replyTo(message: ChatMessage?) { replyingTo.value = message }
    fun toggleRecording() { recording.value = !recording.value }
    fun toggleAttachmentTray() { attachmentTrayVisible.value = !attachmentTrayVisible.value }

    fun send() {
        val body = draft.value.trim()
        if (body.isBlank()) return
        val replyId = replyingTo.value?.id
        draft.value = ""
        replyingTo.value = null
        viewModelScope.launch { repository.sendMessage(conversationId, body, replyId) }
    }

    fun retry(messageId: String) = viewModelScope.launch { repository.retryMessage(messageId) }
    fun react(messageId: String, reaction: String?) = viewModelScope.launch { repository.react(messageId, reaction) }
}
