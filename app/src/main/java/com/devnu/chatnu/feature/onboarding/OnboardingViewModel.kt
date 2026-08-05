package com.devnu.chatnu.feature.onboarding

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.devnu.chatnu.core.identity.IdentityStore
import com.devnu.chatnu.core.model.LocalIdentity
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class OnboardingUiState(
    val identity: LocalIdentity? = null,
    val showForm: Boolean = false,
    val displayName: String = "",
    val username: String = "",
    val creating: Boolean = false,
    val error: String? = null,
)

class OnboardingViewModel(private val identityStore: IdentityStore) : ViewModel() {
    private val form = MutableStateFlow(OnboardingUiState())
    val state = combine(identityStore.identity, form) { identity, current -> current.copy(identity = identity) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), OnboardingUiState())

    fun showForm() { form.value = form.value.copy(showForm = true) }
    fun updateDisplayName(value: String) { form.value = form.value.copy(displayName = value, error = null) }
    fun updateUsername(value: String) { form.value = form.value.copy(username = value, error = null) }

    fun createIdentity() {
        val displayName = form.value.displayName.trim()
        val username = form.value.username.trim().removePrefix("@")
        if (displayName.length < 2 || username.length < 3) {
            form.value = form.value.copy(error = "Use a display name and a username with at least 3 characters")
            return
        }
        form.value = form.value.copy(creating = true, error = null)
        viewModelScope.launch {
            runCatching { identityStore.createIdentity(username, displayName) }
                .onFailure { form.value = form.value.copy(creating = false, error = it.message ?: "Identity creation failed") }
        }
    }
}
