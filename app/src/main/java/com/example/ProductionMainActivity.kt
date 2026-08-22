package com.example

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.example.data.CallRepository
import com.example.model.CallType
import com.example.model.Conversation
import com.example.model.MessageType
import com.example.remote.ApiClient
import com.example.remote.RemoteAuthRepository
import com.example.remote.RemoteAuthScreen
import com.example.remote.RemoteChatRepository
import com.example.remote.RemoteHomeScreen
import com.example.remote.TokenStore
import com.example.ui.components.CallOverlayView
import com.example.ui.screens.ConversationScreen
import com.example.ui.screens.SettingsScreen
import com.example.ui.theme.MyApplicationTheme
import kotlinx.coroutines.launch

enum class ProductionScreen { AUTH, HOME, CONVERSATION, SETTINGS }

class ProductionMainActivity : ComponentActivity() {
    private lateinit var authRepository: RemoteAuthRepository
    private lateinit var chatRepository: RemoteChatRepository
    private val callRepository = CallRepository()

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
                val activeCall by callRepository.activeCall.collectAsState()

                var screen by remember {
                    mutableStateOf(if (isLoggedIn) ProductionScreen.HOME else ProductionScreen.AUTH)
                }
                var activeConversation by remember { mutableStateOf<Conversation?>(null) }

                LaunchedEffect(isLoggedIn) {
                    if (isLoggedIn) {
                        runCatching { chatRepository.refreshConversations() }
                            .onFailure { if (it is retrofit2.HttpException && it.code() == 401) authRepository.forceLogout() }
                        chatRepository.startRealtime()
                    } else {
                        chatRepository.closeRealtime()
                        screen = ProductionScreen.AUTH
                    }
                }

                LaunchedEffect(conversations, activeConversation?.id) {
                    val id = activeConversation?.id ?: return@LaunchedEffect
                    conversations.firstOrNull { it.id == id }?.let { activeConversation = it }
                }

                Box(modifier = Modifier.fillMaxSize()) {
                    when (screen) {
                        ProductionScreen.AUTH -> RemoteAuthScreen(
                            onLogin = authRepository::login,
                            onRegister = authRepository::register,
                            onAuthSuccess = {
                                screen = ProductionScreen.HOME
                                scope.launch { runCatching { chatRepository.refreshConversations() } }
                            }
                        )

                        ProductionScreen.HOME -> RemoteHomeScreen(
                            conversations = conversations,
                            onSelectConversation = { conversation ->
                                activeConversation = conversation
                                screen = ProductionScreen.CONVERSATION
                                scope.launch {
                                    runCatching { chatRepository.loadMessages(conversation.id) }
                                    chatRepository.markRead(conversation.id)
                                }
                            },
                            onCreateGroup = { title, _ ->
                                scope.launch {
                                    runCatching { chatRepository.createGroup(title) }
                                        .onSuccess { conversation ->
                                            activeConversation = conversation
                                            screen = ProductionScreen.CONVERSATION
                                        }
                                }
                            },
                            onTogglePinConversation = chatRepository::togglePinConversation,
                            onOpenSettings = { screen = ProductionScreen.SETTINGS },
                            onSimulateCall = {
                                callRepository.simulateIncomingCall(
                                    "Incoming call",
                                    null,
                                    CallType.VOICE
                                )
                            },
                            onOpenDirect = { username ->
                                runCatching {
                                    val conversation = chatRepository.openDirect(username)
                                    activeConversation = conversation
                                    screen = ProductionScreen.CONVERSATION
                                }
                            }
                        )

                        ProductionScreen.CONVERSATION -> {
                            activeConversation?.let { conversation ->
                                ConversationScreen(
                                    conversation = conversation,
                                    messages = messagesMap[conversation.id].orEmpty(),
                                    onBackClick = { screen = ProductionScreen.HOME },
                                    onSendMessage = { text, type ->
                                        chatRepository.sendMessage(conversation.id, text, type)
                                    },
                                    onSendVoice = { duration ->
                                        chatRepository.sendMessage(
                                            conversation.id,
                                            "Voice message (${duration}s)",
                                            MessageType.VOICE,
                                            voiceDurationSeconds = duration
                                        )
                                    },
                                    onSendFile = { fileName, fileSize, extension ->
                                        chatRepository.sendMessage(
                                            conversation.id,
                                            fileName,
                                            MessageType.FILE,
                                            fileName = fileName,
                                            fileSize = fileSize,
                                            fileExtension = extension
                                        )
                                    },
                                    onStartVoiceCall = {
                                        callRepository.startCall(conversation.title, conversation.avatarUrl, CallType.VOICE)
                                    },
                                    onStartVideoCall = {
                                        callRepository.startCall(conversation.title, conversation.avatarUrl, CallType.VIDEO)
                                    },
                                    onMarkViewOnceOpened = { chatRepository.markViewOnceOpened(conversation.id, it) },
                                    onAddReaction = { id, emoji -> chatRepository.addReaction(conversation.id, id, emoji) },
                                    onTogglePinMessage = { chatRepository.togglePinMessage(conversation.id, it) },
                                    onUpdateGroupInfo = { title, avatar ->
                                        chatRepository.updateGroupInfo(conversation.id, title, avatar)
                                    },
                                    onAddGroupMember = { chatRepository.addMemberToGroup(conversation.id, it) },
                                    onRemoveGroupMember = { chatRepository.removeMemberFromGroup(conversation.id, it) },
                                    onToggleGroupEncryption = { chatRepository.toggleGroupEncryption(conversation.id) },
                                    onLeaveGroup = {
                                        chatRepository.leaveGroup(conversation.id)
                                        screen = ProductionScreen.HOME
                                    }
                                )
                            }
                        }

                        ProductionScreen.SETTINGS -> SettingsScreen(
                            user = currentUser,
                            onBackClick = { screen = ProductionScreen.HOME },
                            onLogoutClick = {
                                scope.launch {
                                    chatRepository.closeRealtime()
                                    authRepository.logout()
                                    screen = ProductionScreen.AUTH
                                }
                            }
                        )
                    }

                    activeCall?.let { callSession ->
                        CallOverlayView(
                            callSession = callSession,
                            onAcceptCall = callRepository::acceptIncomingCall,
                            onEndCall = callRepository::endCall,
                            onToggleMute = callRepository::toggleMute,
                            onToggleCamera = callRepository::toggleCamera,
                            onToggleSpeaker = callRepository::toggleSpeaker
                        )
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        chatRepository.closeRealtime()
        super.onDestroy()
    }
}
