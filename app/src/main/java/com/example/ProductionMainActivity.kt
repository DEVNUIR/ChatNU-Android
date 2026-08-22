package com.example

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import com.example.model.Conversation
import com.example.model.MessageType
import com.example.remote.ApiClient
import com.example.remote.ProductionAuthScreen
import com.example.remote.ProductionConversationScreen
import com.example.remote.ProductionHomeScreen
import com.example.remote.ProductionSettingsScreen
import com.example.remote.RemoteAuthRepository
import com.example.remote.RemoteChatRepository
import com.example.remote.TokenStore
import com.example.ui.theme.MyApplicationTheme
import kotlinx.coroutines.launch
import retrofit2.HttpException

enum class ProductionScreen { AUTH, HOME, CONVERSATION, SETTINGS }

class ProductionMainActivity : ComponentActivity() {
    private lateinit var authRepository: RemoteAuthRepository
    private lateinit var chatRepository: RemoteChatRepository

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        val tokenStore = TokenStore(applicationContext)
        val apiClient = ApiClient(tokenStore)
        authRepository = RemoteAuthRepository(tokenStore, apiClient)
        chatRepository = RemoteChatRepository(apiClient, tokenStore, authRepository)

        setContent {
            MyApplicationTheme {
                val scope = rememberCoroutineScope()
                val isLoggedIn by authRepository.isLoggedIn.collectAsState()
                val currentUser by authRepository.currentUser.collectAsState()
                val conversations by chatRepository.conversations.collectAsState()
                val messagesMap by chatRepository.messagesMap.collectAsState()
                val realtimeStatus by chatRepository.realtimeStatus.collectAsState()

                var screen by remember {
                    mutableStateOf(if (isLoggedIn) ProductionScreen.HOME else ProductionScreen.AUTH)
                }
                var activeConversation by remember { mutableStateOf<Conversation?>(null) }
                var isRefreshing by remember { mutableStateOf(false) }
                var homeError by remember { mutableStateOf<String?>(null) }
                var conversationLoading by remember { mutableStateOf(false) }
                var conversationError by remember { mutableStateOf<String?>(null) }

                fun refreshHome() {
                    if (isRefreshing) return
                    scope.launch {
                        isRefreshing = true
                        homeError = null
                        runCatching { chatRepository.refreshConversations() }
                            .onFailure { error ->
                                if (error is HttpException && error.code() == 401) {
                                    authRepository.forceLogout()
                                } else {
                                    homeError = error.message ?: "Could not refresh conversations."
                                }
                            }
                        isRefreshing = false
                    }
                }

                fun loadConversation(conversation: Conversation) {
                    activeConversation = conversation
                    screen = ProductionScreen.CONVERSATION
                    conversationError = null
                    scope.launch {
                        conversationLoading = true
                        runCatching { chatRepository.loadMessages(conversation.id) }
                            .onFailure { error ->
                                if (error is HttpException && error.code() == 401) {
                                    authRepository.forceLogout()
                                } else {
                                    conversationError = error.message ?: "Could not load messages."
                                }
                            }
                        conversationLoading = false
                        chatRepository.markRead(conversation.id)
                    }
                }

                LaunchedEffect(isLoggedIn) {
                    if (isLoggedIn) {
                        isRefreshing = true
                        homeError = null
                        runCatching { chatRepository.refreshConversations() }
                            .onFailure { error ->
                                if (error is HttpException && error.code() == 401) {
                                    authRepository.forceLogout()
                                } else {
                                    homeError = error.message ?: "Could not refresh conversations."
                                }
                            }
                        isRefreshing = false
                        if (authRepository.isLoggedIn.value) chatRepository.startRealtime()
                    } else {
                        chatRepository.closeRealtime()
                        activeConversation = null
                        conversationError = null
                        screen = ProductionScreen.AUTH
                    }
                }

                LaunchedEffect(conversations, activeConversation?.id) {
                    val id = activeConversation?.id ?: return@LaunchedEffect
                    conversations.firstOrNull { it.id == id }?.let { activeConversation = it }
                }

                BackHandler(enabled = screen == ProductionScreen.CONVERSATION || screen == ProductionScreen.SETTINGS) {
                    screen = ProductionScreen.HOME
                    conversationError = null
                }

                when (screen) {
                    ProductionScreen.AUTH -> ProductionAuthScreen(
                        onLogin = authRepository::login,
                        onRegister = authRepository::register,
                        onAuthSuccess = {
                            screen = ProductionScreen.HOME
                            refreshHome()
                        }
                    )

                    ProductionScreen.HOME -> ProductionHomeScreen(
                        user = currentUser,
                        conversations = conversations,
                        realtimeStatus = realtimeStatus,
                        isRefreshing = isRefreshing,
                        errorMessage = homeError,
                        onRefresh = ::refreshHome,
                        onSelectConversation = ::loadConversation,
                        onTogglePinConversation = chatRepository::togglePinConversation,
                        onOpenSettings = { screen = ProductionScreen.SETTINGS },
                        onOpenDirect = { username ->
                            runCatching {
                                val conversation = chatRepository.openDirect(username)
                                activeConversation = conversation
                                conversationError = null
                                screen = ProductionScreen.CONVERSATION
                            }
                        },
                        onCreateGroup = { title, usernames ->
                            runCatching {
                                val conversation = chatRepository.createGroup(title, usernames)
                                activeConversation = conversation
                                conversationError = null
                                screen = ProductionScreen.CONVERSATION
                            }
                        }
                    )

                    ProductionScreen.CONVERSATION -> {
                        val conversation = activeConversation
                        if (conversation == null) {
                            screen = ProductionScreen.HOME
                        } else {
                            ProductionConversationScreen(
                                conversation = conversation,
                                messages = messagesMap[conversation.id].orEmpty(),
                                currentUserId = currentUser?.id,
                                isLoading = conversationLoading,
                                errorMessage = conversationError,
                                onBack = {
                                    screen = ProductionScreen.HOME
                                    conversationError = null
                                },
                                onRetry = { loadConversation(conversation) },
                                onSendText = { text ->
                                    chatRepository.sendMessage(conversation.id, text, MessageType.TEXT)
                                }
                            )
                        }
                    }

                    ProductionScreen.SETTINGS -> ProductionSettingsScreen(
                        user = currentUser,
                        realtimeStatus = realtimeStatus,
                        onBack = { screen = ProductionScreen.HOME },
                        onLogout = {
                            scope.launch {
                                chatRepository.closeRealtime()
                                authRepository.logout()
                            }
                        }
                    )
                }
            }
        }
    }

    override fun onDestroy() {
        chatRepository.closeRealtime()
        super.onDestroy()
    }
}
