package com.devnu.chatnu.feature.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.devnu.chatnu.core.identity.IdentityStore
import com.devnu.chatnu.core.model.ConnectionState
import com.devnu.chatnu.core.model.LocalIdentity
import com.devnu.chatnu.domain.ChatRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn

data class SettingsUiState(
    val identity: LocalIdentity? = null,
    val connectionState: ConnectionState = ConnectionState.DISCONNECTED,
    val notifications: Boolean = true,
    val previews: Boolean = false,
    val reducedMotion: Boolean = false,
)

class SettingsViewModel(identityStore: IdentityStore, repository: ChatRepository) : ViewModel() {
    private val preferences = MutableStateFlow(SettingsUiState())

    val state = combine(identityStore.identity, repository.connectionState, preferences) { identity, connection, current ->
        current.copy(identity = identity, connectionState = connection)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), SettingsUiState())

    fun setNotifications(value: Boolean) { preferences.value = preferences.value.copy(notifications = value) }
    fun setPreviews(value: Boolean) { preferences.value = preferences.value.copy(previews = value) }
    fun setReducedMotion(value: Boolean) { preferences.value = preferences.value.copy(reducedMotion = value) }
}
