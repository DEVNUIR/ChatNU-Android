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

private data class ComposerState(
    val draft: String = "",
    val replyingTo: ChatMessage? = null,
    val recording: Boolean = false,
    val attachmentTrayVisible: Boolean = false,
)

class ConversationViewModel(
    private val repository: ChatRepository,
    private val conversationId: String,
) : ViewModel() {
    private val composer = MutableStateFlow(ComposerState())
    private val conversation = repository.conversations.map { items -> items.firstOrNull { it.id == conversationId } }

    val state = combine(
        conversation,
        repository.messages(conversationId),
        composer,
    ) { currentConversation, messages, currentComposer ->
        ConversationUiState(
            conversation = currentConversation,
            messages = messages,
            draft = currentComposer.draft,
            replyingTo = currentComposer.replyingTo,
            recording = currentComposer.recording,
            attachmentTrayVisible = currentComposer.attachmentTrayVisible,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), ConversationUiState())

    fun updateDraft(value: String) { composer.value = composer.value.copy(draft = value) }
    fun replyTo(message: ChatMessage?) { composer.value = composer.value.copy(replyingTo = message) }
    fun toggleRecording() { composer.value = composer.value.copy(recording = !composer.value.recording) }
    fun toggleAttachmentTray() { composer.value = composer.value.copy(attachmentTrayVisible = !composer.value.attachmentTrayVisible) }

    fun send() {
        val body = composer.value.draft.trim()
        if (body.isBlank()) return
        val replyId = composer.value.replyingTo?.id
        composer.value = composer.value.copy(draft = "", replyingTo = null)
        viewModelScope.launch { repository.sendMessage(conversationId, body, replyId) }
    }

    fun retry(messageId: String) = viewModelScope.launch { repository.retryMessage(messageId) }
    fun react(messageId: String, reaction: String?) = viewModelScope.launch { repository.react(messageId, reaction) }
}
