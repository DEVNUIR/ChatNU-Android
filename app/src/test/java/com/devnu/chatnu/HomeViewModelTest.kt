package com.devnu.chatnu

import com.devnu.chatnu.feature.home.HomeViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class HomeViewModelTest {
    @get:Rule val mainDispatcherRule = MainDispatcherRule()

    @Test
    fun filtersActiveAndArchivedConversations() = runTest {
        val viewModel = HomeViewModel(FakeChatRepository())
        assertEquals("active", viewModel.state.value.conversations.single().id)
        viewModel.toggleArchiveView()
        assertEquals("archived", viewModel.state.value.conversations.single().id)
    }

    @Test
    fun searchMatchesDisplayName() = runTest {
        val viewModel = HomeViewModel(FakeChatRepository())
        viewModel.updateQuery("ali")
        assertEquals("Alice", viewModel.state.value.conversations.single().peer.displayName)
    }
}
