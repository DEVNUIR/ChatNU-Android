package com.devnu.chatnu.feature.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.devnu.chatnu.core.model.ConnectionState
import com.devnu.chatnu.core.model.Conversation
import com.devnu.chatnu.domain.ChatRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class HomeUiState(
    val conversations: List<Conversation> = emptyList(),
    val query: String = "",
    val showingArchived: Boolean = false,
    val connectionState: ConnectionState = ConnectionState.DISCONNECTED,
)

class HomeViewModel(private val repository: ChatRepository) : ViewModel() {
    private val query = MutableStateFlow("")
    private val showingArchived = MutableStateFlow(false)

    val state = combine(
        repository.conversations,
        query,
        showingArchived,
        repository.connectionState,
    ) { conversations, currentQuery, archived, connection ->
        HomeUiState(
            conversations = conversations.filter {
                it.archived == archived && (
                    currentQuery.isBlank() ||
                        it.peer.displayName.contains(currentQuery, ignoreCase = true) ||
                        it.peer.username.contains(currentQuery, ignoreCase = true) ||
                        it.preview.contains(currentQuery, ignoreCase = true)
                    )
            },
            query = currentQuery,
            showingArchived = archived,
            connectionState = connection,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), HomeUiState())

    fun updateQuery(value: String) { query.value = value }
    fun toggleArchiveView() { showingArchived.value = !showingArchived.value }
    fun togglePinned(conversationId: String) = viewModelScope.launch { repository.togglePinned(conversationId) }
    fun toggleArchived(conversationId: String) = viewModelScope.launch { repository.toggleArchived(conversationId) }
}
