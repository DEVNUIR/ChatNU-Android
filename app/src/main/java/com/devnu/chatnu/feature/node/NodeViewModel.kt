package com.devnu.chatnu.feature.node

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.devnu.chatnu.core.model.ConnectionState
import com.devnu.chatnu.core.model.RelayNode
import com.devnu.chatnu.domain.ChatRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class NodeUiState(
    val nodes: List<RelayNode> = emptyList(),
    val connectionState: ConnectionState = ConnectionState.DISCONNECTED,
    val showAddDialog: Boolean = false,
    val nodeHost: String = "https://",
    val error: String? = null,
    val saving: Boolean = false,
)

class NodeViewModel(private val repository: ChatRepository) : ViewModel() {
    private val form = MutableStateFlow(NodeUiState())

    val state = combine(repository.relayNodes, repository.connectionState, form) { nodes, connection, current ->
        current.copy(nodes = nodes, connectionState = connection)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), NodeUiState())

    fun select(nodeId: String) = viewModelScope.launch { repository.selectRelayNode(nodeId) }
    fun showAddDialog(show: Boolean) { form.value = form.value.copy(showAddDialog = show, error = null) }
    fun updateHost(value: String) { form.value = form.value.copy(nodeHost = value, error = null) }

    fun addNode() {
        val host = form.value.nodeHost
        form.value = form.value.copy(saving = true, error = null)
        viewModelScope.launch {
            repository.addRelayNode(host)
                .onSuccess { form.value = form.value.copy(showAddDialog = false, saving = false, nodeHost = "https://") }
                .onFailure { form.value = form.value.copy(saving = false, error = it.message ?: "Node validation failed") }
        }
    }
}
