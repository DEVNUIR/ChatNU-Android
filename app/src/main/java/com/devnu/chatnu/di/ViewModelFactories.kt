package com.devnu.chatnu.di

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.devnu.chatnu.core.identity.IdentityStore
import com.devnu.chatnu.domain.ChatRepository
import com.devnu.chatnu.feature.chat.ConversationViewModel
import com.devnu.chatnu.feature.home.HomeViewModel
import com.devnu.chatnu.feature.node.NodeViewModel
import com.devnu.chatnu.feature.onboarding.OnboardingViewModel
import com.devnu.chatnu.feature.settings.SettingsViewModel

@Suppress("UNCHECKED_CAST")
class HomeViewModelFactory(private val repository: ChatRepository) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T = HomeViewModel(repository) as T
}

@Suppress("UNCHECKED_CAST")
class ConversationViewModelFactory(
    private val repository: ChatRepository,
    private val conversationId: String,
) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T = ConversationViewModel(repository, conversationId) as T
}

@Suppress("UNCHECKED_CAST")
class NodeViewModelFactory(private val repository: ChatRepository) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T = NodeViewModel(repository) as T
}

@Suppress("UNCHECKED_CAST")
class SettingsViewModelFactory(
    private val identityStore: IdentityStore,
    private val repository: ChatRepository,
) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T = SettingsViewModel(identityStore, repository) as T
}

@Suppress("UNCHECKED_CAST")
class OnboardingViewModelFactory(private val identityStore: IdentityStore) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T = OnboardingViewModel(identityStore) as T
}
