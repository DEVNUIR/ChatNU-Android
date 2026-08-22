package com.example

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import com.example.crypto.DeviceE2ee
import com.example.model.Conversation
import com.example.model.Message
import com.example.model.MessageType
import com.example.remote.ApiClient
import com.example.remote.CallPhase
import com.example.remote.EnhancedProductionConversationScreen
import com.example.remote.ProductionAuthScreen
import com.example.remote.ProductionHomeScreen
import com.example.remote.ProductionSettingsScreen
import com.example.remote.PushRegistration
import com.example.remote.RemoteAuthRepository
import com.example.remote.RemoteChatRepository
import com.example.remote.TokenStore
import com.example.remote.WebRtcCallManager
import com.example.remote.ChatNuMessagingService
import com.example.ui.theme.MyApplicationTheme
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.launch
import retrofit2.HttpException

enum class ProductionScreen { AUTH, HOME, CONVERSATION, SETTINGS }

class ProductionMainActivity : ComponentActivity() {
    private lateinit var authRepository: RemoteAuthRepository
    private lateinit var chatRepository: RemoteChatRepository
    private lateinit var callManager: WebRtcCallManager
    private val navigationIntents = MutableSharedFlow<Intent>(extraBufferCapacity = 8)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        val tokenStore = TokenStore(applicationContext)
        val apiClient = ApiClient(tokenStore)
        val deviceE2ee = DeviceE2ee()
        authRepository = RemoteAuthRepository(tokenStore, apiClient, deviceE2ee)
        chatRepository = RemoteChatRepository(
            applicationContext,
            apiClient,
            tokenStore,
            authRepository,
            deviceE2ee
        )
        callManager = WebRtcCallManager(applicationContext, chatRepository, authRepository)

        setContent {
            MyApplicationTheme {
                val scope = rememberCoroutineScope()
                val isLoggedIn by authRepository.isLoggedIn.collectAsState()
                val currentUser by authRepository.currentUser.collectAsState()
                val conversations by chatRepository.conversations.collectAsState()
                val messagesMap by chatRepository.messagesMap.collectAsState()
                val realtimeStatus by chatRepository.realtimeStatus.collectAsState()
                val callState by callManager.state.collectAsState()

                var screen by remember {
                    mutableStateOf(if (isLoggedIn) ProductionScreen.HOME else ProductionScreen.AUTH)
                }
                var activeConversation by remember { mutableStateOf<Conversation?>(null) }
                var isRefreshing by remember { mutableStateOf(false) }
                var homeError by remember { mutableStateOf<String?>(null) }
                var conversationLoading by remember { mutableStateOf(false) }
                var conversationError by remember { mutableStateOf<String?>(null) }
                var pendingConversationId by remember {
                    mutableStateOf(intent.getStringExtra(ChatNuMessagingService.EXTRA_CONVERSATION_ID))
                }

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

                fun openEncryptedAttachment(message: Message) {
                    scope.launch {
                        conversationError = null
                        runCatching { chatRepository.downloadAttachment(message) }
                            .onSuccess { file ->
                                val uri = FileProvider.getUriForFile(
                                    this@ProductionMainActivity,
                                    "$packageName.files",
                                    file
                                )
                                val viewer = Intent(Intent.ACTION_VIEW)
                                    .setDataAndType(uri, message.mimeType ?: "application/octet-stream")
                                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                runCatching {
                                    startActivity(Intent.createChooser(viewer, "Open decrypted attachment"))
                                }.onFailure {
                                    conversationError = "No app can open this attachment type."
                                }
                            }
                            .onFailure { error ->
                                conversationError = error.message ?: "Could not decrypt attachment."
                            }
                    }
                }

                LaunchedEffect(Unit) {
                    navigationIntents.collect { newIntent ->
                        pendingConversationId = newIntent.getStringExtra(ChatNuMessagingService.EXTRA_CONVERSATION_ID)
                    }
                }

                LaunchedEffect(isLoggedIn) {
                    if (isLoggedIn) {
                        if (
                            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                            ContextCompat.checkSelfPermission(
                                this@ProductionMainActivity,
                                Manifest.permission.POST_NOTIFICATIONS
                            ) != PackageManager.PERMISSION_GRANTED
                        ) {
                            ActivityCompat.requestPermissions(
                                this@ProductionMainActivity,
                                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                NOTIFICATION_PERMISSION_REQUEST
                            )
                        }

                        isRefreshing = true
                        homeError = null
                        runCatching { authRepository.ensureDeviceIdentity() }
                            .onFailure { error ->
                                if (error is HttpException && error.code() == 401) {
                                    authRepository.forceLogout()
                                } else {
                                    homeError = "Device encryption setup failed: ${error.message ?: "unknown error"}"
                                }
                            }
                        if (authRepository.isLoggedIn.value) {
                            runCatching { chatRepository.refreshConversations() }
                                .onFailure { error ->
                                    if (error is HttpException && error.code() == 401) {
                                        authRepository.forceLogout()
                                    } else {
                                        homeError = error.message ?: "Could not refresh conversations."
                                    }
                                }
                        }
                        isRefreshing = false
                        if (authRepository.isLoggedIn.value) {
                            chatRepository.startRealtime()
                            PushRegistration.refresh(this@ProductionMainActivity, authRepository)
                        }
                    } else {
                        chatRepository.closeRealtime()
                        if (callManager.state.value.phase != CallPhase.IDLE) callManager.endCall()
                        activeConversation = null
                        conversationError = null
                        screen = ProductionScreen.AUTH
                    }
                }

                LaunchedEffect(conversations, pendingConversationId) {
                    val id = pendingConversationId ?: return@LaunchedEffect
                    conversations.firstOrNull { it.id == id }?.let { conversation ->
                        pendingConversationId = null
                        loadConversation(conversation)
                    }
                }

                LaunchedEffect(callState.phase, callState.conversationId, conversations) {
                    if (callState.phase == CallPhase.IDLE) return@LaunchedEffect
                    val id = callState.conversationId ?: return@LaunchedEffect
                    val conversation = conversations.firstOrNull { it.id == id } ?: return@LaunchedEffect
                    if (activeConversation?.id != id || screen != ProductionScreen.CONVERSATION) {
                        activeConversation = conversation
                        screen = ProductionScreen.CONVERSATION
                        if (messagesMap[id] == null) {
                            scope.launch { runCatching { chatRepository.loadMessages(id) } }
                        }
                    }
                }

                LaunchedEffect(conversations, activeConversation?.id) {
                    val id = activeConversation?.id ?: return@LaunchedEffect
                    conversations.firstOrNull { it.id == id }?.let { activeConversation = it }
                }

                BackHandler(
                    enabled = screen == ProductionScreen.CONVERSATION || screen == ProductionScreen.SETTINGS
                ) {
                    if (callState.phase == CallPhase.IDLE) {
                        screen = ProductionScreen.HOME
                        conversationError = null
                    }
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
                            EnhancedProductionConversationScreen(
                                conversation = conversation,
                                messages = messagesMap[conversation.id].orEmpty(),
                                currentUserId = currentUser?.id,
                                isLoading = conversationLoading,
                                errorMessage = conversationError,
                                callState = callState,
                                callManager = callManager,
                                onBack = {
                                    if (callState.phase == CallPhase.IDLE) {
                                        screen = ProductionScreen.HOME
                                        conversationError = null
                                    }
                                },
                                onRetry = { loadConversation(conversation) },
                                onSendText = { text ->
                                    chatRepository.sendMessage(conversation.id, text, MessageType.TEXT)
                                },
                                onSendAttachment = { uri ->
                                    chatRepository.sendAttachment(conversation.id, uri)
                                },
                                onOpenAttachment = ::openEncryptedAttachment
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

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        navigationIntents.tryEmit(intent)
    }

    override fun onDestroy() {
        chatRepository.closeRealtime()
        callManager.dispose()
        super.onDestroy()
    }

    companion object {
        private const val NOTIFICATION_PERMISSION_REQUEST = 7401
    }
}
