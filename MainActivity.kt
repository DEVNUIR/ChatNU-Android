package com.example

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import com.example.data.AuthRepository
import com.example.data.CallRepository
import com.example.data.ChatRepository
import com.example.model.CallType
import com.example.model.Conversation
import com.example.model.MessageType
import com.example.ui.components.CallOverlayView
import com.example.ui.screens.AuthScreen
import com.example.ui.screens.ConversationScreen
import com.example.ui.screens.HomeScreen
import com.example.ui.screens.SettingsScreen
import com.example.ui.theme.MyApplicationTheme

enum class ScreenState {
    AUTH, HOME, CONVERSATION, SETTINGS
}

class MainActivity : ComponentActivity() {
    private val authRepo = AuthRepository()
    private val chatRepo = ChatRepository()
    private val callRepo = CallRepository()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            MyApplicationTheme {
                var currentScreen by remember { mutableStateOf(ScreenState.HOME) }
                var activeConversation by remember { mutableStateOf<Conversation?>(null) }

                val isLoggedIn by authRepo.isLoggedIn.collectAsState()
                val currentUser by authRepo.currentUser.collectAsState()
                val conversations by chatRepo.conversations.collectAsState()
                val messagesMap by chatRepo.messagesMap.collectAsState()
                val activeCall by callRepo.activeCall.collectAsState()

                Box(modifier = Modifier.fillMaxSize()) {
                    if (!isLoggedIn) {
                        AuthScreen(
                            onAuthSuccess = { currentScreen = ScreenState.HOME }
                        )
                    } else {
                        when (currentScreen) {
                            ScreenState.HOME -> {
                                HomeScreen(
                                    conversations = conversations,
                                    onSelectConversation = { conv ->
                                        activeConversation = conv
                                        currentScreen = ScreenState.CONVERSATION
                                    },
                                    onCreateGroup = { title, desc ->
                                        val newGroup = chatRepo.createGroup(title, desc)
                                        activeConversation = newGroup
                                        currentScreen = ScreenState.CONVERSATION
                                    },
                                    onTogglePinConversation = { convId ->
                                        chatRepo.togglePinConversation(convId)
                                    },
                                    onOpenSettings = { currentScreen = ScreenState.SETTINGS },
                                    onSimulateCall = {
                                        callRepo.simulateIncomingCall("Ali Rezaei", "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150", CallType.VOICE)
                                    }
                                )
                            }

                            ScreenState.CONVERSATION -> {
                                activeConversation?.let { conv ->
                                    ConversationScreen(
                                        conversation = conv,
                                        messages = messagesMap[conv.id] ?: emptyList(),
                                        onBackClick = { currentScreen = ScreenState.HOME },
                                        onSendMessage = { text, type ->
                                            chatRepo.sendMessage(conv.id, text, type)
                                        },
                                        onSendVoice = { duration ->
                                            chatRepo.sendMessage(
                                                conversationId = conv.id,
                                                text = "Voice message (${duration}s)",
                                                type = MessageType.VOICE,
                                                voiceDurationSeconds = duration
                                            )
                                        },
                                        onSendFile = { fileName, fileSize, ext ->
                                            chatRepo.sendMessage(
                                                conversationId = conv.id,
                                                text = fileName,
                                                type = MessageType.FILE,
                                                fileName = fileName,
                                                fileSize = fileSize,
                                                fileExtension = ext
                                            )
                                        },
                                        onStartVoiceCall = {
                                            callRepo.startCall(conv.title, conv.avatarUrl, CallType.VOICE)
                                        },
                                        onStartVideoCall = {
                                            callRepo.startCall(conv.title, conv.avatarUrl, CallType.VIDEO)
                                        },
                                        onMarkViewOnceOpened = { msgId ->
                                            chatRepo.markViewOnceOpened(conv.id, msgId)
                                        },
                                        onAddReaction = { msgId, emoji ->
                                            chatRepo.addReaction(conv.id, msgId, emoji)
                                        },
                                        onTogglePinMessage = { msgId ->
                                            chatRepo.togglePinMessage(conv.id, msgId)
                                        },
                                        onUpdateGroupInfo = { title, avatarUrl ->
                                            chatRepo.updateGroupInfo(conv.id, title, avatarUrl)
                                            activeConversation = chatRepo.conversations.value.find { it.id == conv.id }
                                        },
                                        onAddGroupMember = { user ->
                                            chatRepo.addMemberToGroup(conv.id, user)
                                            activeConversation = chatRepo.conversations.value.find { it.id == conv.id }
                                        },
                                        onRemoveGroupMember = { memberId ->
                                            chatRepo.removeMemberFromGroup(conv.id, memberId)
                                            activeConversation = chatRepo.conversations.value.find { it.id == conv.id }
                                        },
                                        onToggleGroupEncryption = {
                                            chatRepo.toggleGroupEncryption(conv.id)
                                            activeConversation = chatRepo.conversations.value.find { it.id == conv.id }
                                        },
                                        onLeaveGroup = {
                                            chatRepo.leaveGroup(conv.id)
                                            currentScreen = ScreenState.HOME
                                        }
                                    )
                                }
                            }

                            ScreenState.SETTINGS -> {
                                SettingsScreen(
                                    user = currentUser,
                                    onBackClick = { currentScreen = ScreenState.HOME },
                                    onLogoutClick = {
                                        authRepo.logout()
                                        currentScreen = ScreenState.AUTH
                                    }
                                )
                            }

                            else -> {
                                HomeScreen(
                                    conversations = conversations,
                                    onSelectConversation = { conv ->
                                        activeConversation = conv
                                        currentScreen = ScreenState.CONVERSATION
                                    },
                                    onOpenSettings = { currentScreen = ScreenState.SETTINGS },
                                    onSimulateCall = {
                                        callRepo.simulateIncomingCall("Ali Rezaei", "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150", CallType.VOICE)
                                    }
                                )
                            }
                        }
                    }

                    activeCall?.let { callSession ->
                        CallOverlayView(
                            callSession = callSession,
                            onAcceptCall = { callRepo.acceptIncomingCall() },
                            onEndCall = { callRepo.endCall() },
                            onToggleMute = { callRepo.toggleMute() },
                            onToggleCamera = { callRepo.toggleCamera() },
                            onToggleSpeaker = { callRepo.toggleSpeaker() }
                        )
                    }
                }
            }
        }
    }
}
