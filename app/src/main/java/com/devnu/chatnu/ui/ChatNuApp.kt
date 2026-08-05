package com.devnu.chatnu.ui

import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import com.devnu.chatnu.ChatNuApplication
import com.devnu.chatnu.navigation.ChatNuNavHost
import com.devnu.chatnu.ui.theme.ChatNuTheme

@Composable
fun ChatNuApp() {
    val application = LocalContext.current.applicationContext as ChatNuApplication
    ChatNuTheme {
        ChatNuNavHost(application.container)
    }
}
