package com.example.remote

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.AttachFile
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.CallEnd
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material.icons.filled.InsertDriveFile
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.MicOff
import androidx.compose.material.icons.filled.Photo
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Send
import androidx.compose.material.icons.filled.SpeakerPhone
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material.icons.filled.VideocamOff
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.core.content.ContextCompat
import com.example.model.Conversation
import com.example.model.ConversationType
import com.example.model.Message
import com.example.model.MessageStatus
import com.example.model.MessageType
import org.webrtc.SurfaceViewRenderer

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EnhancedProductionConversationScreen(
    conversation: Conversation,
    messages: List<Message>,
    currentUserId: String?,
    isLoading: Boolean,
    errorMessage: String?,
    callState: CallUiState,
    callManager: WebRtcCallManager,
    onBack: () -> Unit,
    onRetry: () -> Unit,
    onSendText: (String) -> Unit,
    onSendAttachment: (Uri) -> Unit,
    onOpenAttachment: (Message) -> Unit
) {
    var input by remember(conversation.id) { mutableStateOf("") }
    val listState = rememberLazyListState()
    val context = LocalContext.current
    val filePicker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        uri?.let(onSendAttachment)
    }
    var pendingCallVideo by remember { mutableStateOf<Boolean?>(null) }
    val callPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { grants ->
        val video = pendingCallVideo ?: return@rememberLauncherForActivityResult
        val audioOk = grants[Manifest.permission.RECORD_AUDIO] == true ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        val cameraOk = !video || grants[Manifest.permission.CAMERA] == true ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
        if (audioOk && cameraOk) callManager.startCall(conversation, video)
        pendingCallVideo = null
    }

    fun beginCall(video: Boolean) {
        if (conversation.type != ConversationType.DIRECT || conversation.members.size != 2) return
        val required = buildList {
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                add(Manifest.permission.RECORD_AUDIO)
            }
            if (video && ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                add(Manifest.permission.CAMERA)
            }
        }
        if (required.isEmpty()) callManager.startCall(conversation, video)
        else {
            pendingCallVideo = video
            callPermissionLauncher.launch(required.toTypedArray())
        }
    }

    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) listState.animateScrollToItem(messages.lastIndex)
    }

    fun send() {
        val text = input.trim()
        if (text.isBlank()) return
        onSendText(text)
        input = ""
    }

    Scaffold(
        topBar = {
            TopAppBar(
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Surface(
                            modifier = Modifier.size(40.dp),
                            shape = CircleShape,
                            color = MaterialTheme.colorScheme.primaryContainer
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Text(
                                    conversation.title.firstOrNull()?.uppercase() ?: "?",
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                            }
                        }
                        Spacer(Modifier.width(10.dp))
                        Column {
                            Text(
                                conversation.title,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                if (conversation.type == ConversationType.GROUP) {
                                    "${conversation.members.size} members · E2EE messages"
                                } else {
                                    "Direct · E2EE messages"
                                },
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                },
                actions = {
                    if (conversation.type == ConversationType.DIRECT && conversation.members.size == 2) {
                        IconButton(onClick = { beginCall(false) }) {
                            Icon(Icons.Default.Call, contentDescription = "Voice call")
                        }
                        IconButton(onClick = { beginCall(true) }) {
                            Icon(Icons.Default.Videocam, contentDescription = "Video call")
                        }
                    }
                    IconButton(onClick = onRetry) {
                        Icon(Icons.Default.Refresh, contentDescription = "Reload messages")
                    }
                }
            )
        },
        bottomBar = {
            Surface(
                tonalElevation = 3.dp,
                modifier = Modifier.fillMaxWidth().imePadding().navigationBarsPadding()
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.Bottom,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    IconButton(
                        onClick = { filePicker.launch("*/*") },
                        modifier = Modifier.size(48.dp)
                    ) {
                        Icon(Icons.Default.AttachFile, contentDescription = "Attach encrypted file")
                    }
                    OutlinedTextField(
                        value = input,
                        onValueChange = { input = it },
                        placeholder = { Text("Encrypted message") },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(22.dp),
                        minLines = 1,
                        maxLines = 5,
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Default)
                    )
                    FilledTonalIconButton(
                        onClick = { send() },
                        enabled = input.isNotBlank(),
                        modifier = Modifier.size(48.dp)
                    ) {
                        Icon(Icons.Default.Send, contentDescription = "Send")
                    }
                }
            }
        }
    ) { padding ->
        Box(modifier = Modifier.fillMaxSize().padding(padding)) {
            when {
                isLoading && messages.isEmpty() -> CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
                errorMessage != null && messages.isEmpty() -> {
                    Column(
                        modifier = Modifier.align(Alignment.Center).padding(32.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            Icons.Default.ErrorOutline,
                            contentDescription = null,
                            modifier = Modifier.size(36.dp),
                            tint = MaterialTheme.colorScheme.error
                        )
                        Spacer(Modifier.height(10.dp))
                        Text(errorMessage, textAlign = TextAlign.Center)
                        Spacer(Modifier.height(12.dp))
                        OutlinedButton(onClick = onRetry) { Text("Try again") }
                    }
                }
                messages.isEmpty() -> {
                    Column(
                        modifier = Modifier.align(Alignment.Center).padding(32.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text("No messages yet", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                        Spacer(Modifier.height(6.dp))
                        Text("Start an end-to-end encrypted conversation.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                else -> LazyColumn(
                    state = listState,
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 12.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    items(messages, key = { it.id }) { message ->
                        EnhancedMessageBubble(
                            message = message,
                            mine = message.senderId == currentUserId,
                            onOpenAttachment = onOpenAttachment
                        )
                    }
                }
            }
            if (isLoading && messages.isNotEmpty()) {
                CircularProgressIndicator(
                    modifier = Modifier.align(Alignment.TopCenter).padding(top = 8.dp).size(22.dp),
                    strokeWidth = 2.dp
                )
            }
        }
    }

    CallOverlay(state = callState, manager = callManager)
}

@Composable
private fun EnhancedMessageBubble(
    message: Message,
    mine: Boolean,
    onOpenAttachment: (Message) -> Unit
) {
    if (message.type == MessageType.SYSTEM_KEY_CHANGE) {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
            Surface(shape = RoundedCornerShape(20.dp), color = MaterialTheme.colorScheme.surfaceContainerHighest) {
                Text(
                    message.text,
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        return
    }

    Box(modifier = Modifier.fillMaxWidth()) {
        Surface(
            modifier = Modifier
                .align(if (mine) Alignment.CenterEnd else Alignment.CenterStart)
                .widthIn(max = 360.dp)
                .then(
                    if (message.attachmentId != null) Modifier.clickable { onOpenAttachment(message) }
                    else Modifier
                ),
            shape = RoundedCornerShape(
                topStart = 20.dp,
                topEnd = 20.dp,
                bottomStart = if (mine) 20.dp else 5.dp,
                bottomEnd = if (mine) 5.dp else 20.dp
            ),
            color = if (mine) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceContainerHigh
        ) {
            Column(modifier = Modifier.padding(horizontal = 12.dp, vertical = 9.dp)) {
                if (!mine && message.senderName.isNotBlank()) {
                    Text(
                        message.senderName,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(Modifier.height(3.dp))
                }
                if (message.attachmentId != null) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            if (message.type == MessageType.IMAGE) Icons.Default.Photo else Icons.Default.InsertDriveFile,
                            contentDescription = null,
                            modifier = Modifier.size(24.dp)
                        )
                        Spacer(Modifier.width(9.dp))
                        Column {
                            Text(message.fileName ?: message.text, fontWeight = FontWeight.SemiBold, maxLines = 2)
                            message.fileSize?.let {
                                Text(it, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                            Text(
                                "Tap to decrypt and open",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                } else {
                    Text(message.text, style = MaterialTheme.typography.bodyLarge)
                }
                Spacer(Modifier.height(4.dp))
                Row(
                    modifier = Modifier.align(Alignment.End),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(5.dp)
                ) {
                    Text(message.timestamp, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    if (mine) {
                        Text(
                            when (message.status) {
                                MessageStatus.SENDING, MessageStatus.QUEUED -> "…"
                                MessageStatus.FAILED -> "!"
                                else -> "✓"
                            },
                            style = MaterialTheme.typography.labelSmall,
                            color = if (message.status == MessageStatus.FAILED) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun CallOverlay(state: CallUiState, manager: WebRtcCallManager) {
    if (state.phase == CallPhase.IDLE) return
    val context = LocalContext.current
    var accepting by remember { mutableStateOf(false) }
    val acceptPermissions = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { grants ->
        val audioOk = grants[Manifest.permission.RECORD_AUDIO] == true ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        val cameraOk = !state.video || grants[Manifest.permission.CAMERA] == true ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
        if (audioOk && cameraOk) manager.acceptIncoming()
        accepting = false
    }

    fun accept() {
        val required = buildList {
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                add(Manifest.permission.RECORD_AUDIO)
            }
            if (state.video && ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                add(Manifest.permission.CAMERA)
            }
        }
        if (required.isEmpty()) manager.acceptIncoming()
        else {
            accepting = true
            acceptPermissions.launch(required.toTypedArray())
        }
    }

    if (state.phase == CallPhase.INCOMING) {
        AlertDialog(
            onDismissRequest = {},
            title = { Text(if (state.video) "Incoming video call" else "Incoming voice call") },
            text = { Text(state.peerName.ifBlank { "ChatNU user" }) },
            confirmButton = {
                TextButton(onClick = { accept() }, enabled = !accepting) { Text("Accept") }
            },
            dismissButton = {
                TextButton(onClick = manager::rejectIncoming) { Text("Decline") }
            }
        )
        return
    }

    Dialog(
        onDismissRequest = {},
        properties = DialogProperties(usePlatformDefaultWidth = false, dismissOnBackPress = false, dismissOnClickOutside = false)
    ) {
        Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.surface) {
            Box(modifier = Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding()) {
                if (state.video && state.phase == CallPhase.ACTIVE) {
                    WebRtcRenderer(modifier = Modifier.fillMaxSize(), manager = manager, local = false)
                    Surface(
                        modifier = Modifier.align(Alignment.TopEnd).padding(16.dp).size(width = 112.dp, height = 160.dp),
                        shape = RoundedCornerShape(18.dp),
                        tonalElevation = 6.dp
                    ) {
                        WebRtcRenderer(modifier = Modifier.fillMaxSize(), manager = manager, local = true)
                    }
                } else {
                    Column(
                        modifier = Modifier.align(Alignment.Center).padding(32.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Surface(modifier = Modifier.size(96.dp), shape = CircleShape, color = MaterialTheme.colorScheme.primaryContainer) {
                            Box(contentAlignment = Alignment.Center) {
                                Text(
                                    state.peerName.firstOrNull()?.uppercase() ?: "?",
                                    style = MaterialTheme.typography.headlineLarge,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                        }
                        Spacer(Modifier.height(18.dp))
                        Text(state.peerName.ifBlank { "ChatNU call" }, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                        Spacer(Modifier.height(6.dp))
                        Text(
                            when (state.phase) {
                                CallPhase.CONNECTING -> "Connecting…"
                                CallPhase.ACTIVE -> if (state.video) "Video call" else "Voice call"
                                CallPhase.ERROR -> state.error ?: "Call failed"
                                else -> ""
                            },
                            color = if (state.phase == CallPhase.ERROR) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant,
                            textAlign = TextAlign.Center
                        )
                        if (state.phase == CallPhase.CONNECTING) {
                            Spacer(Modifier.height(18.dp))
                            CircularProgressIndicator()
                        }
                    }
                }

                Row(
                    modifier = Modifier.align(Alignment.BottomCenter).padding(24.dp),
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    FilledTonalIconButton(onClick = manager::toggleMute, modifier = Modifier.size(58.dp)) {
                        Icon(if (state.muted) Icons.Default.MicOff else Icons.Default.Mic, contentDescription = "Mute")
                    }
                    if (state.video) {
                        FilledTonalIconButton(onClick = manager::toggleCamera, modifier = Modifier.size(58.dp)) {
                            Icon(if (state.cameraEnabled) Icons.Default.Videocam else Icons.Default.VideocamOff, contentDescription = "Camera")
                        }
                    }
                    FilledTonalIconButton(onClick = manager::toggleSpeaker, modifier = Modifier.size(58.dp)) {
                        Icon(Icons.Default.SpeakerPhone, contentDescription = "Speaker")
                    }
                    FilledTonalIconButton(
                        onClick = manager::endCall,
                        modifier = Modifier.size(64.dp)
                    ) {
                        Icon(Icons.Default.CallEnd, contentDescription = "End call", tint = MaterialTheme.colorScheme.error)
                    }
                }
            }
        }
    }
}

@Composable
private fun WebRtcRenderer(
    modifier: Modifier,
    manager: WebRtcCallManager,
    local: Boolean
) {
    val context = LocalContext.current
    val renderer = remember { SurfaceViewRenderer(context) }
    DisposableEffect(renderer, local) {
        if (local) manager.attachLocalRenderer(renderer) else manager.attachRemoteRenderer(renderer)
        onDispose {
            if (local) manager.detachLocalRenderer(renderer) else manager.detachRemoteRenderer(renderer)
        }
    }
    AndroidView(factory = { renderer }, modifier = modifier)
}
