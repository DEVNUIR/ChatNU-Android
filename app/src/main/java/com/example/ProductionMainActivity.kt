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
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.animation.core.tween
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.core.view.WindowCompat
import com.example.crypto.DeviceE2ee
import com.example.model.Conversation
import com.example.model.Message
import com.example.model.MessageType
import com.example.remote.ApiClient
import com.example.remote.CallForegroundService
import com.example.remote.CallPhase
import com.example.remote.ChatNuConversationScreen2026
import com.example.remote.ChatNuHomeScreen2026
import com.example.remote.ChatNuMessagingService
import com.example.remote.EnhancedProductionSettingsScreen
import com.example.remote.PushRegistration
import com.example.remote.RemoteAuthRepository
import com.example.remote.RemoteChatRepository
import com.example.remote.ServerAwareAuthScreen
import com.example.remote.ServerEndpoint
import com.example.remote.TokenStore
import com.example.remote.WebRtcCallManager
import com.example.ui.chatnu2026.ChatNuMotion
import com.example.ui.chatnu2026.rememberChatNuAccessibilityPreferences
import com.example.ui.theme.MyApplicationTheme
import com.example.ui.theme.ThemeManager
import com.example.ui.theme.isAppInDarkTheme
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

        ServerEndpoint.initialize(applicationContext)
        ThemeManager.initialize(applicationContext)
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
            val darkTheme = isAppInDarkTheme()
            SideEffect {
                // Edge-to-edge defaults otherwise follow the phone theme, which can conflict with
                // ChatNU's explicit Light/Dark selection.
                WindowCompat.getInsetsController(window, window.decorView).apply {
                    isAppearanceLightStatusBars = !darkTheme
                    isAppearanceLightNavigationBars = !darkTheme
                }
            }

            MyApplicationTheme(darkTheme = darkTheme) {
                val scope = rememberCoroutineScope()
                val accessibility = rememberChatNuAccessibilityPreferences()
                val isLoggedIn by authRepository.isLoggedIn.collectAsState()
                val currentUser by authRepository.currentUser.collectAsState()
                val conversations by chatRepository.conversations.collectAsState()
                val messagesMap by chatRepository.messagesMap.collectAsState()
                val realtimeStatus by chatRepository.realtimeStatus.collectAsState()
                val callState by callManager.state.collectAsState()
                val drafts = remember { mutableStateMapOf<String, String>() }

                var screen by remember {
                    mutableStateOf(if (isLoggedIn) ProductionScreen.HOME else ProductionScreen.AUTH)
                }
                var activeConversation by remember { mutableStateOf<Conversation?>(null) }
                var isRefreshing by remember { mutableStateOf(false) }
                var homeError by remember { mutableStateOf<String?>(null) }
                var conversationLoading by remember { mutableStateOf(false) }
                var conversationError by remember { mutableStateOf<String?>(null) }
                var callServiceRunning by remember { mutableStateOf(false) }
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
                        if (callServiceRunning) {
                            CallForegroundService.stop(this@ProductionMainActivity)
                            callServiceRunning = false
                        }
                        activeConversation = null
                        conversationError = null
                        drafts.clear()
                        screen = ProductionScreen.AUTH
                    }
                }

                LaunchedEffect(callState.phase, callState.peerName, callState.video) {
                    val shouldRun = callState.phase == CallPhase.CONNECTING || callState.phase == CallPhase.ACTIVE
                    if (shouldRun && !callServiceRunning) {
                        CallForegroundService.start(
                            this@ProductionMainActivity,
                            callState.peerName,
                            callState.video
                        )
                        callServiceRunning = true
                    } else if (!shouldRun && callServiceRunning) {
                        CallForegroundService.stop(this@ProductionMainActivity)
                        callServiceRunning = false
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

                AnimatedContent(
                    targetState = screen,
                    transitionSpec = {
                        if (accessibility.reduceMotion) {
                            fadeIn(tween(ChatNuMotion.instantMs)) togetherWith
                                fadeOut(tween(ChatNuMotion.instantMs))
                        } else {
                            val forward = targetState.ordinal >= initialState.ordinal
                            val enter = slideInHorizontally(
                                animationSpec = tween(ChatNuMotion.emphasizedMs),
                                initialOffsetX = { width -> if (forward) width / 5 else -width / 5 }
                            ) + fadeIn(tween(ChatNuMotion.standardMs))
                            val exit = slideOutHorizontally(
                                animationSpec = tween(ChatNuMotion.standardMs),
                                targetOffsetX = { width -> if (forward) -width / 8 else width / 8 }
                            ) + fadeOut(tween(ChatNuMotion.quickMs))
                            enter togetherWith exit
                        }
                    },
                    label = "production-screen"
                ) { targetScreen ->
                    when (targetScreen) {
                        ProductionScreen.AUTH -> ServerAwareAuthScreen(
                            initialServerUrl = ServerEndpoint.apiUrl(),
                            onChangeServer = { raw ->
                                chatRepository.closeRealtime()
                                authRepository.forceLogout()
                                ServerEndpoint.configure(applicationContext, raw)
                            },
                            onLogin = authRepository::login,
                            onRegister = authRepository::register,
                            onAuthSuccess = {
                                screen = ProductionScreen.HOME
                                refreshHome()
                            }
                        )

                        ProductionScreen.HOME -> ChatNuHomeScreen2026(
                            user = currentUser,
                            conversations = conversations,
                            realtimeStatus = realtimeStatus,
                            isRefreshing = isRefreshing,
                            errorMessage = homeError,
                            drafts = drafts,
                            onRefresh = ::refreshHome,
                            onSelectConversation = ::loadConversation,
                            onTogglePinConversation = chatRepository::togglePinConversation,
                            onMarkReadConversation = chatRepository::markRead,
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
                            },
                            onSearchUsers = chatRepository::searchUsers
                        )

                        ProductionScreen.CONVERSATION -> {
                            val conversation = activeConversation
                            if (conversation == null) {
                                screen = ProductionScreen.HOME
                            } else {
                                ChatNuConversationScreen2026(
                                    conversation = conversation,
                                    messages = messagesMap[conversation.id].orEmpty(),
                                    currentUserId = currentUser?.id,
                                    isLoading = conversationLoading,
                                    errorMessage = conversationError,
                                    callState = callState,
                                    callManager = callManager,
                                    initialDraft = drafts[conversation.id].orEmpty(),
                                    onDraftChanged = { value ->
                                        if (value.isBlank()) drafts.remove(conversation.id)
                                        else drafts[conversation.id] = value
                                    },
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
                                    onSendTypedMessage = { text, type ->
                                        chatRepository.sendMessage(conversation.id, text, type)
                                    },
                                    onSendAttachment = { uri ->
                                        chatRepository.sendAttachment(conversation.id, uri)
                                    },
                                    onResolveAttachment = { message ->
                                        chatRepository.downloadAttachment(message)
                                    },
                                    onOpenAttachment = ::openEncryptedAttachment
                                )
                            }
                        }

                        ProductionScreen.SETTINGS -> EnhancedProductionSettingsScreen(
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
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        navigationIntents.tryEmit(intent)
    }

    override fun onDestroy() {
        CallForegroundService.stop(this)
        chatRepository.closeRealtime()
        callManager.dispose()
        super.onDestroy()
    }

    companion object {
        private const val NOTIFICATION_PERMISSION_REQUEST = 7401
    }
}
