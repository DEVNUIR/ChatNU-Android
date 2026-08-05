package com.devnu.chatnu

import com.devnu.chatnu.feature.chat.ConversationViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class ConversationViewModelTest {
    @get:Rule val mainDispatcherRule = MainDispatcherRule()

    @Test
    fun sendClearsDraftAndWritesRepository() = runTest {
        val repository = FakeChatRepository()
        val viewModel = ConversationViewModel(repository, "active")
        viewModel.updateDraft("encrypted hello")
        viewModel.send()
        advanceUntilIdle()
        assertEquals("", viewModel.state.value.draft)
        assertEquals(listOf("encrypted hello"), repository.sentBodies)
    }
}
