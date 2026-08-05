package com.devnu.chatnu.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import com.devnu.chatnu.data.DemoChatRepository
import com.devnu.chatnu.navigation.ChatNuNavHost
import com.devnu.chatnu.ui.theme.ChatNuTheme

@Composable
fun ChatNuApp() {
    val repository = remember { DemoChatRepository() }
    ChatNuTheme {
        ChatNuNavHost(repository)
    }
}
