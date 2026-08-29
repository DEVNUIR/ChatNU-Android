package com.example.remote

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.net.Uri
import android.os.Build
import android.os.Looper
import android.os.SystemClock
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AttachFile
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.EmojiEmotions
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Send
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import com.example.model.Conversation
import com.example.model.ConversationType
import com.example.model.Message
import com.example.model.MessageDeliveryState
import com.example.model.MessageType
import com.example.model.toDeliveryState
import com.example.ui.chatnu2026.ChatNuAvatar
import com.example.ui.chatnu2026.ChatNuAvatarSize
import com.example.ui.chatnu2026.ChatNuGlassSurface
import com.example.ui.chatnu2026.ChatNuIconSize
import com.example.ui.chatnu2026.ChatNuLocationPreview
import com.example.ui.chatnu2026.ChatNuMotion
import com.example.ui.chatnu2026.ChatNuRadius
import com.example.ui.chatnu2026.ChatNuRichMessageBubble
import com.example.ui.chatnu2026.ChatNuSemantic
import com.example.ui.chatnu2026.ChatNuSpacing
import com.example.ui.chatnu2026.MessageGroupPosition
import com.example.ui.chatnu2026.parseCoordinates
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import java.io.File
import java.util.Locale
import java.util.UUID
import kotlin.coroutines.resume
import kotlin.math.abs

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun ChatNuConversationScreen2026(
    conversation: Conversation,
    messages: List<Message>,
    currentUserId: String?,
    isLoading: Boolean,
    errorMessage: String?,
    callState: CallUiState,
    callManager: WebRtcCallManager,
    initialDraft: String,
    onDraftChanged: (String) -> Unit,
    onBack: () -> Unit,
    onRetry: () -> Unit,
    onSendText: (String) -> Unit,
    onSendTypedMessage: (String, MessageType) -> Unit,
    onSendAttachment: (Uri) -> Unit,
    onResolveAttachment: suspend (Message) -> File,
    onOpenAttachment: (Message) -> Unit
) {
    val context = LocalContext.current
    val haptics = LocalHapticFeedback.current
    val clipboard = LocalClipboardManager.current
    val scope = rememberCoroutineScope()
    val listState = rememberLazyListState()
    val recorder = remember { ChatNuVoiceRecorder2026(context) }
    val audioPlayer = remember { ChatNuVoicePlayer2026() }

    var input by remember(conversation.id) { mutableStateOf(initialDraft) }
    var showAttachSheet by remember { mutableStateOf(false) }
    var showProfileSheet by remember { mutableStateOf(false) }
    var showEmojiTray by remember { mutableStateOf(false) }
    var searchOpen by remember { mutableStateOf(false) }
    var searchQuery by remember { mutableStateOf("") }
    var selectedMessage by remember { mutableStateOf<Message?>(null) }
    var selectedLocation by remember { mutableStateOf<Triple<Double, Double, Boolean>?>(null) }
    var recording by remember { mutableStateOf(false) }
    var recordingStartedAt by remember { mutableLongStateOf(0L) }
    var recordingSeconds by remember { mutableLongStateOf(0L) }
    var pendingCapture by remember { mutableStateOf<Uri?>(null) }
    var pendingCallVideo by remember { mutableStateOf<Boolean?>(null) }
    var pendingLocationMode by remember { mutableStateOf<LocationShareMode2026?>(null) }
    var liveLocationJob by remember { mutableStateOf<Job?>(null) }
    var liveLocationEndsAt by remember { mutableLongStateOf(0L) }
    var playingMessageId by remember { mutableStateOf<String?>(null) }

    val filePicker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        uri?.let(onSendAttachment)
    }
    val imagePicker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        uri?.let(onSendAttachment)
    }
    val videoPicker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        uri?.let(onSendAttachment)
    }
    val photoCapture = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { ok ->
        if (ok) pendingCapture?.let(onSendAttachment)
        pendingCapture = null
    }
    val videoCapture = rememberLauncherForActivityResult(ActivityResultContracts.CaptureVideo()) { ok ->
        if (ok) pendingCapture?.let(onSendAttachment)
        pendingCapture = null
    }

    fun startRecording() {
        if (recording) return
        runCatching { recorder.start() }.onSuccess {
            recordingStartedAt = SystemClock.elapsedRealtime()
            recordingSeconds = 0L
            recording = true
            showEmojiTray = false
            haptics.performHapticFeedback(HapticFeedbackType.LongPress)
        }
    }

    fun finishRecording(send: Boolean) {
        val file = runCatching { recorder.stop() }.getOrNull()
        recording = false
        recordingSeconds = 0L
        if (send && file != null && file.length() > 0L) {
            haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove)
            onSendAttachment(FileProvider.getUriForFile(context, "${context.packageName}.files", file))
        } else {
            file?.delete()
            haptics.performHapticFeedback(HapticFeedbackType.LongPress)
        }
    }

    fun startLocation(mode: LocationShareMode2026) {
        if (mode == LocationShareMode2026.ONCE) {
            scope.launch {
                currentLocation2026(context)?.let { location ->
                    onSendTypedMessage(locationPayload2026(location, live = false), MessageType.LOCATION)
                }
            }
        } else {
            liveLocationJob?.cancel()
            liveLocationEndsAt = System.currentTimeMillis() + LIVE_LOCATION_DURATION_2026
            liveLocationJob = scope.launch {
                while (isActive && System.currentTimeMillis() < liveLocationEndsAt) {
                    currentLocation2026(context)?.let { location ->
                        onSendTypedMessage(locationPayload2026(location, live = true), MessageType.LIVE_LOCATION)
                    }
                    delay(LIVE_LOCATION_INTERVAL_2026)
                }
            }
        }
    }

    val voicePermission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) startRecording()
    }
    val locationPermission = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { grants ->
        val allowed = grants[Manifest.permission.ACCESS_FINE_LOCATION] == true ||
            grants[Manifest.permission.ACCESS_COARSE_LOCATION] == true ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val mode = pendingLocationMode
        pendingLocationMode = null
        if (allowed && mode != null) startLocation(mode)
    }
    val callPermission = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { grants ->
        val video = pendingCallVideo ?: return@rememberLauncherForActivityResult
        val audioOk = grants[Manifest.permission.RECORD_AUDIO] == true ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        val cameraOk = !video || grants[Manifest.permission.CAMERA] == true ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
        if (audioOk && cameraOk) callManager.startCall(conversation, video)
        pendingCallVideo = null
    }

    fun requestLocation(mode: LocationShareMode2026) {
        val allowed = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (allowed) startLocation(mode)
        else {
            pendingLocationMode = mode
            locationPermission.launch(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION))
        }
    }

    fun beginCall(video: Boolean) {
        if (conversation.type != ConversationType.DIRECT || conversation.members.size != 2) return
        val missing = buildList {
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) add(Manifest.permission.RECORD_AUDIO)
            if (video && ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) add(Manifest.permission.CAMERA)
        }
        if (missing.isEmpty()) callManager.startCall(conversation, video)
        else {
            pendingCallVideo = video
            callPermission.launch(missing.toTypedArray())
        }
    }

    fun playVoice(message: Message) {
        if (playingMessageId == message.id) {
            audioPlayer.stop()
            playingMessageId = null
            return
        }
        scope.launch {
            runCatching { onResolveAttachment(message) }.onSuccess { file ->
                audioPlayer.play(file) { playingMessageId = null }
                playingMessageId = message.id
            }
        }
    }

    fun sendCurrentText() {
        val value = input.trim()
        if (value.isBlank()) return
        onSendText(value)
        haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove)
        input = ""
        onDraftChanged("")
        showEmojiTray = false
    }

    LaunchedEffect(input) { onDraftChanged(input) }
    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty() && !searchOpen) listState.animateScrollToItem(messages.lastIndex)
    }
    LaunchedEffect(searchQuery, searchOpen, messages) {
        if (!searchOpen || searchQuery.isBlank()) return@LaunchedEffect
        val index = messages.indexOfLast { it.text.contains(searchQuery.trim(), ignoreCase = true) }
        if (index >= 0) listState.animateScrollToItem(index)
    }
    LaunchedEffect(recording) {
        while (recording) {
            recordingSeconds = ((SystemClock.elapsedRealtime() - recordingStartedAt) / 1000L).coerceAtLeast(0L)
            delay(200L)
        }
    }
    DisposableEffect(conversation.id) {
        onDispose {
            liveLocationJob?.cancel()
            recorder.cancel()
            audioPlayer.release()
        }
    }

    Box(modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)) {
        LazyColumn(
            state = listState,
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(
                start = ChatNuSpacing.md,
                end = ChatNuSpacing.md,
                top = 94.dp,
                bottom = 116.dp
            ),
            verticalArrangement = Arrangement.spacedBy(2.dp)
        ) {
            if (isLoading && messages.isEmpty()) {
                item("loading") {
                    Box(Modifier.fillMaxWidth().padding(top = 80.dp), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator()
                    }
                }
            } else if (errorMessage != null && messages.isEmpty()) {
                item("error") {
                    Column(
                        modifier = Modifier.fillMaxWidth().padding(top = 80.dp, start = 28.dp, end = 28.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(Icons.Default.ErrorOutline, contentDescription = null, tint = MaterialTheme.colorScheme.error, modifier = Modifier.size(34.dp))
                        Spacer(Modifier.height(10.dp))
                        Text("Couldn’t load this conversation", fontWeight = FontWeight.Bold)
                        Text(errorMessage, textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Spacer(Modifier.height(10.dp))
                        OutlinedButton(onClick = onRetry) { Text("Try again") }
                    }
                }
            } else if (messages.isEmpty()) {
                item("empty") {
                    Column(
                        modifier = Modifier.fillMaxWidth().padding(top = 72.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Surface(shape = CircleShape, color = MaterialTheme.colorScheme.tertiaryContainer, modifier = Modifier.size(62.dp)) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(Icons.Default.Lock, contentDescription = null, tint = MaterialTheme.colorScheme.tertiary)
                            }
                        }
                        Spacer(Modifier.height(10.dp))
                        Text("Start the conversation", fontWeight = FontWeight.Bold)
                        Text("Messages in this chat are end-to-end encrypted.", color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodySmall)
                    }
                }
            }

            itemsIndexed(messages, key = { _, message -> message.id }) { index, message ->
                val mine = message.senderId == currentUserId
                val previous = messages.getOrNull(index - 1)
                val next = messages.getOrNull(index + 1)
                val groupedWithPrevious = previous != null && canGroup(previous, message)
                val groupedWithNext = next != null && canGroup(message, next)
                val position = when {
                    !groupedWithPrevious && !groupedWithNext -> MessageGroupPosition.SINGLE
                    !groupedWithPrevious && groupedWithNext -> MessageGroupPosition.FIRST
                    groupedWithPrevious && groupedWithNext -> MessageGroupPosition.MIDDLE
                    else -> MessageGroupPosition.LAST
                }
                val showSender = conversation.type == ConversationType.GROUP && !groupedWithPrevious
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = if (groupedWithPrevious) 0.dp else 5.dp)
                        .combinedClickable(
                            onClick = {},
                            onLongClick = {
                                haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                                selectedMessage = message
                            }
                        )
                ) {
                    ChatNuRichMessageBubble(
                        message = message,
                        mine = mine,
                        groupPosition = position,
                        showSender = showSender,
                        playing = playingMessageId == message.id,
                        onPlayVoice = { playVoice(message) },
                        onOpenAttachment = { onOpenAttachment(message) },
                        onOpenLocation = { lat, lon, live -> selectedLocation = Triple(lat, lon, live) },
                        onRetryFailed = if (mine && message.status.toDeliveryState() == MessageDeliveryState.FAILED) {
                            {
                                if (!message.localUri.isNullOrBlank()) onSendAttachment(Uri.parse(message.localUri))
                                else onSendTypedMessage(message.text, message.type)
                            }
                        } else null
                    )
                }
            }
        }

        ChatNuConversationTopBar2026(
            conversation = conversation,
            searchOpen = searchOpen,
            searchQuery = searchQuery,
            onSearchQuery = { searchQuery = it },
            onSearchToggle = {
                searchOpen = !searchOpen
                if (!searchOpen) searchQuery = ""
            },
            onBack = onBack,
            onProfile = { showProfileSheet = true },
            onVoiceCall = { beginCall(false) },
            onVideoCall = { beginCall(true) },
            modifier = Modifier.align(Alignment.TopCenter)
        )

        AnimatedVisibility(
            visible = liveLocationJob?.isActive == true,
            enter = fadeIn(),
            exit = fadeOut(),
            modifier = Modifier.align(Alignment.TopCenter).padding(top = 84.dp)
        ) {
            ChatNuGlassSurface(
                shape = RoundedCornerShape(ChatNuRadius.pill),
                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 5.dp)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.MyLocation, contentDescription = null, tint = ChatNuSemantic.Error, modifier = Modifier.size(17.dp))
                    Spacer(Modifier.width(6.dp))
                    Text("Live location sharing", style = MaterialTheme.typography.labelMedium)
                    TextButton(onClick = {
                        liveLocationJob?.cancel()
                        liveLocationJob = null
                        haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                    }) { Text("Stop") }
                }
            }
        }

        ChatNuComposer2026(
            input = input,
            onInput = { input = it },
            recording = recording,
            recordingSeconds = recordingSeconds,
            emojiTrayVisible = showEmojiTray,
            onToggleEmoji = { showEmojiTray = !showEmojiTray },
            onEmoji = { emoji -> input += emoji },
            onAttachment = { showAttachSheet = true },
            onCamera = {
                createCaptureUri2026(context, "photo", "jpg").also { uri ->
                    pendingCapture = uri
                    photoCapture.launch(uri)
                }
            },
            onSend = ::sendCurrentText,
            onRecord = {
                if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) startRecording()
                else voicePermission.launch(Manifest.permission.RECORD_AUDIO)
            },
            onCancelRecording = { finishRecording(false) },
            onSendRecording = { finishRecording(true) },
            modifier = Modifier.align(Alignment.BottomCenter)
        )
    }

    if (showAttachSheet) {
        ChatNuAttachmentSheet2026(
            onDismiss = { showAttachSheet = false },
            onGallery = { showAttachSheet = false; imagePicker.launch("image/*") },
            onCamera = {
                showAttachSheet = false
                createCaptureUri2026(context, "photo", "jpg").also { uri -> pendingCapture = uri; photoCapture.launch(uri) }
            },
            onVideo = { showAttachSheet = false; videoPicker.launch("video/*") },
            onVideoCapture = {
                showAttachSheet = false
                createCaptureUri2026(context, "video", "mp4").also { uri -> pendingCapture = uri; videoCapture.launch(uri) }
            },
            onFile = { showAttachSheet = false; filePicker.launch("*/*") },
            onLocation = { showAttachSheet = false; requestLocation(LocationShareMode2026.ONCE) },
            onLiveLocation = { showAttachSheet = false; requestLocation(LocationShareMode2026.LIVE) }
        )
    }

    if (showProfileSheet) {
        ChatNuConversationProfileSheet2026(
            conversation = conversation,
            onDismiss = { showProfileSheet = false },
            onVoiceCall = { showProfileSheet = false; beginCall(false) },
            onVideoCall = { showProfileSheet = false; beginCall(true) }
        )
    }

    selectedMessage?.let { message ->
        ModalBottomSheet(onDismissRequest = { selectedMessage = null }) {
            Text("Message", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp))
            if (message.type == MessageType.TEXT && message.text.isNotBlank()) {
                ListItem(
                    headlineContent = { Text("Copy text") },
                    leadingContent = { Icon(Icons.Default.ContentCopy, contentDescription = null) }
                )
                TextButton(onClick = {
                    clipboard.setText(AnnotatedString(message.text))
                    selectedMessage = null
                }, modifier = Modifier.padding(horizontal = 16.dp)) { Text("Copy") }
            }
            ListItem(
                headlineContent = { Text("Message details") },
                supportingContent = {
                    val knownState = if (message.senderId == currentUserId) message.status.toDeliveryState().name.replace('_', ' ').lowercase() else "received"
                    Text("${message.timestamp} · $knownState")
                },
                leadingContent = { Icon(Icons.Default.Info, contentDescription = null) }
            )
            if (message.senderId == currentUserId && message.status.toDeliveryState() == MessageDeliveryState.FAILED) {
                TextButton(onClick = {
                    if (!message.localUri.isNullOrBlank()) onSendAttachment(Uri.parse(message.localUri))
                    else onSendTypedMessage(message.text, message.type)
                    selectedMessage = null
                }, modifier = Modifier.padding(horizontal = 16.dp)) { Text("Retry send") }
            }
            Spacer(Modifier.height(20.dp))
        }
    }

    selectedLocation?.let { (lat, lon, live) ->
        ChatNuFullScreenLocation2026(
            latitude = lat,
            longitude = lon,
            live = live,
            onDismiss = { selectedLocation = null }
        )
    }

    ChatNuCallOverlay2026(callState, callManager)
}

@Composable
private fun ChatNuConversationTopBar2026(
    conversation: Conversation,
    searchOpen: Boolean,
    searchQuery: String,
    onSearchQuery: (String) -> Unit,
    onSearchToggle: () -> Unit,
    onBack: () -> Unit,
    onProfile: () -> Unit,
    onVoiceCall: () -> Unit,
    onVideoCall: () -> Unit,
    modifier: Modifier = Modifier
) {
    ChatNuGlassSurface(
        modifier = modifier
            .fillMaxWidth()
            .statusBarsPadding()
            .padding(horizontal = ChatNuSpacing.sm, vertical = 6.dp),
        shape = RoundedCornerShape(ChatNuRadius.floating),
        elevation = 8.dp,
        contentPadding = PaddingValues(horizontal = 4.dp, vertical = 3.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onBack) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
            }
            if (searchOpen) {
                TextField(
                    value = searchQuery,
                    onValueChange = onSearchQuery,
                    placeholder = { Text("Search in chat") },
                    singleLine = true,
                    modifier = Modifier.weight(1f),
                    colors = TextFieldDefaults.colors(
                        focusedContainerColor = Color.Transparent,
                        unfocusedContainerColor = Color.Transparent,
                        focusedIndicatorColor = Color.Transparent,
                        unfocusedIndicatorColor = Color.Transparent
                    )
                )
                IconButton(onClick = onSearchToggle) { Icon(Icons.Default.Close, contentDescription = "Close search") }
            } else {
                Row(
                    modifier = Modifier.weight(1f).combinedClickable(onClick = onProfile, onLongClick = onProfile),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    ChatNuAvatar(conversation.title, conversation.avatarUrl, size = 40.dp)
                    Spacer(Modifier.width(9.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(conversation.title, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        Text(
                            if (conversation.type == ConversationType.GROUP) "${conversation.members.size} members" else "End-to-end encrypted",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
                if (conversation.type == ConversationType.DIRECT && conversation.members.size == 2) {
                    IconButton(onClick = onVoiceCall) { Icon(Icons.Default.Call, contentDescription = "Voice call") }
                    IconButton(onClick = onVideoCall) { Icon(Icons.Default.Videocam, contentDescription = "Video call") }
                }
                IconButton(onClick = onSearchToggle) { Icon(Icons.Default.Search, contentDescription = "Search in chat") }
                IconButton(onClick = onProfile) { Icon(Icons.Default.MoreVert, contentDescription = "Conversation details") }
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun ChatNuComposer2026(
    input: String,
    onInput: (String) -> Unit,
    recording: Boolean,
    recordingSeconds: Long,
    emojiTrayVisible: Boolean,
    onToggleEmoji: () -> Unit,
    onEmoji: (String) -> Unit,
    onAttachment: () -> Unit,
    onCamera: () -> Unit,
    onSend: () -> Unit,
    onRecord: () -> Unit,
    onCancelRecording: () -> Unit,
    onSendRecording: () -> Unit,
    modifier: Modifier = Modifier
) {
    val haptics = LocalHapticFeedback.current
    Column(
        modifier = modifier
            .fillMaxWidth()
            .imePadding()
            .navigationBarsPadding()
            .padding(horizontal = ChatNuSpacing.sm, vertical = ChatNuSpacing.sm)
    ) {
        AnimatedVisibility(visible = emojiTrayVisible && !recording, enter = fadeIn(), exit = fadeOut()) {
            ChatNuGlassSurface(
                modifier = Modifier.fillMaxWidth().padding(bottom = 6.dp),
                shape = RoundedCornerShape(ChatNuRadius.lg),
                contentPadding = PaddingValues(8.dp)
            ) {
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                    listOf("😀", "😂", "❤️", "👍", "🔥", "🎉", "🙏", "✨").forEach { emoji ->
                        TextButton(onClick = { onEmoji(emoji) }) { Text(emoji, style = MaterialTheme.typography.titleLarge) }
                    }
                }
            }
        }

        ChatNuGlassSurface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(ChatNuRadius.floating),
            elevation = 12.dp,
            contentPadding = PaddingValues(horizontal = 5.dp, vertical = 5.dp)
        ) {
            AnimatedContent(
                targetState = recording,
                transitionSpec = {
                    (fadeIn() + scaleIn(initialScale = 0.98f)) togetherWith (fadeOut() + scaleOut(targetScale = 0.98f))
                },
                label = "composer-mode"
            ) { isRecording ->
                if (isRecording) {
                    Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                        IconButton(onClick = onCancelRecording) { Icon(Icons.Default.Close, contentDescription = "Cancel recording", tint = ChatNuSemantic.Error) }
                        Row(modifier = Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically) {
                            Box(Modifier.size(9.dp).background(ChatNuSemantic.Error, CircleShape))
                            Spacer(Modifier.width(8.dp))
                            Text(formatDuration2026(recordingSeconds), fontWeight = FontWeight.Bold)
                            Spacer(Modifier.width(8.dp))
                            Text("Recording voice", color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.labelMedium)
                        }
                        FilledIconButton(onClick = onSendRecording, modifier = Modifier.size(48.dp)) {
                            Icon(Icons.Default.Send, contentDescription = "Send voice message")
                        }
                    }
                } else {
                    Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.Bottom) {
                        IconButton(onClick = {
                            haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                            onAttachment()
                        }, modifier = Modifier.size(46.dp)) {
                            Icon(Icons.Default.AttachFile, contentDescription = "Attachments")
                        }
                        TextField(
                            value = input,
                            onValueChange = onInput,
                            placeholder = { Text("Message") },
                            leadingIcon = {
                                IconButton(onClick = onToggleEmoji) {
                                    Icon(Icons.Default.EmojiEmotions, contentDescription = "Emoji")
                                }
                            },
                            minLines = 1,
                            maxLines = 5,
                            shape = RoundedCornerShape(ChatNuRadius.lg),
                            modifier = Modifier.weight(1f),
                            colors = TextFieldDefaults.colors(
                                focusedContainerColor = Color.Transparent,
                                unfocusedContainerColor = Color.Transparent,
                                focusedIndicatorColor = Color.Transparent,
                                unfocusedIndicatorColor = Color.Transparent
                            )
                        )
                        AnimatedContent(
                            targetState = input.isNotBlank(),
                            transitionSpec = {
                                (fadeIn() + scaleIn(initialScale = 0.82f)) togetherWith (fadeOut() + scaleOut(targetScale = 0.82f))
                            },
                            label = "send-mic"
                        ) { hasText ->
                            if (hasText) {
                                FilledIconButton(onClick = onSend, modifier = Modifier.size(48.dp)) {
                                    Icon(Icons.Default.Send, contentDescription = "Send")
                                }
                            } else {
                                Row {
                                    IconButton(onClick = onCamera, modifier = Modifier.size(44.dp)) {
                                        Icon(Icons.Default.CameraAlt, contentDescription = "Camera")
                                    }
                                    androidx.compose.material3.Surface(
                                        modifier = Modifier
                                            .size(48.dp)
                                            .combinedClickable(
                                                onClick = onRecord,
                                                onLongClick = {
                                                    haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                                                    onRecord()
                                                }
                                            ),
                                        shape = CircleShape,
                                        color = MaterialTheme.colorScheme.primary,
                                        contentColor = MaterialTheme.colorScheme.onPrimary
                                    ) {
                                        Box(contentAlignment = Alignment.Center) {
                                            Icon(Icons.Default.Mic, contentDescription = "Record voice")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ChatNuAttachmentSheet2026(
    onDismiss: () -> Unit,
    onGallery: () -> Unit,
    onCamera: () -> Unit,
    onVideo: () -> Unit,
    onVideoCapture: () -> Unit,
    onFile: () -> Unit,
    onLocation: () -> Unit,
    onLiveLocation: () -> Unit
) {
    ModalBottomSheet(onDismissRequest = onDismiss) {
        Text("Share", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = ChatNuSpacing.xl, vertical = ChatNuSpacing.sm))
        Column(modifier = Modifier.padding(horizontal = ChatNuSpacing.lg), verticalArrangement = Arrangement.spacedBy(ChatNuSpacing.sm)) {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                AttachmentAction2026(Icons.Default.Image, "Gallery", onGallery)
                AttachmentAction2026(Icons.Default.CameraAlt, "Camera", onCamera)
                AttachmentAction2026(Icons.Default.Videocam, "Video", onVideo)
                AttachmentAction2026(Icons.Default.Description, "File", onFile)
            }
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                AttachmentAction2026(Icons.Default.Videocam, "Record", onVideoCapture)
                AttachmentAction2026(Icons.Default.LocationOn, "Location", onLocation)
                AttachmentAction2026(Icons.Default.MyLocation, "Live", onLiveLocation)
                Spacer(Modifier.width(68.dp))
            }
        }
        Text(
            "Attachments are encrypted before upload.",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(ChatNuSpacing.xl)
        )
        Spacer(Modifier.height(ChatNuSpacing.lg))
    }
}

@Composable
private fun AttachmentAction2026(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    onClick: () -> Unit
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.width(68.dp)) {
        FilledIconButton(onClick = onClick, modifier = Modifier.size(54.dp)) {
            Icon(icon, contentDescription = label, modifier = Modifier.size(ChatNuIconSize.standard))
        }
        Spacer(Modifier.height(4.dp))
        Text(label, style = MaterialTheme.typography.labelSmall, maxLines = 1)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ChatNuConversationProfileSheet2026(
    conversation: Conversation,
    onDismiss: () -> Unit,
    onVoiceCall: () -> Unit,
    onVideoCall: () -> Unit
) {
    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth().padding(horizontal = ChatNuSpacing.xl)) {
            ChatNuAvatar(conversation.title, conversation.avatarUrl, size = ChatNuAvatarSize.profile)
            Spacer(Modifier.height(10.dp))
            Text(conversation.title, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            Text(
                if (conversation.type == ConversationType.GROUP) "${conversation.members.size} members" else "Private conversation",
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(Modifier.height(14.dp))
            if (conversation.type == ConversationType.DIRECT && conversation.members.size == 2) {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Button(onClick = onVoiceCall) { Icon(Icons.Default.Call, contentDescription = null); Spacer(Modifier.width(6.dp)); Text("Call") }
                    OutlinedButton(onClick = onVideoCall) { Icon(Icons.Default.Videocam, contentDescription = null); Spacer(Modifier.width(6.dp)); Text("Video") }
                }
            }
            Spacer(Modifier.height(18.dp))
            ListItem(
                headlineContent = { Text("End-to-end encryption") },
                supportingContent = { Text("Security details are available without cluttering the chat header.") },
                leadingContent = { Icon(Icons.Default.Lock, contentDescription = null, tint = MaterialTheme.colorScheme.tertiary) }
            )
            if (conversation.type == ConversationType.GROUP) {
                Text("Members", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, modifier = Modifier.fillMaxWidth().padding(top = 12.dp, bottom = 4.dp))
                conversation.members.take(12).forEach { member ->
                    ListItem(
                        headlineContent = { Text(member.displayName) },
                        supportingContent = { Text("@${member.username}") },
                        leadingContent = { ChatNuAvatar(member.displayName, member.avatarUrl) }
                    )
                }
            }
        }
        Spacer(Modifier.height(ChatNuSpacing.xxl))
    }
}

@Composable
private fun ChatNuFullScreenLocation2026(
    latitude: Double,
    longitude: Double,
    live: Boolean,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Box(modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)) {
            Column(
                modifier = Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding().padding(ChatNuSpacing.lg),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    IconButton(onClick = onDismiss) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back") }
                    Text(if (live) "Live location" else "Location", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                }
                Spacer(Modifier.height(ChatNuSpacing.xl))
                ChatNuLocationPreview(latitude, longitude, live, onClick = {})
                Spacer(Modifier.height(ChatNuSpacing.lg))
                Text(
                    String.format(Locale.US, "%.6f, %.6f", latitude, longitude),
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(Modifier.height(ChatNuSpacing.md))
                Button(onClick = {
                    val uri = Uri.parse("geo:$latitude,$longitude?q=$latitude,$longitude")
                    runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, uri)) }
                }) { Icon(Icons.Default.LocationOn, contentDescription = null); Spacer(Modifier.width(7.dp)); Text("Open in maps") }
            }
        }
    }
}

private fun canGroup(first: Message, second: Message): Boolean {
    if (first.type == MessageType.SYSTEM_KEY_CHANGE || second.type == MessageType.SYSTEM_KEY_CHANGE) return false
    return first.senderId == second.senderId && abs(second.timestampMillis - first.timestampMillis) <= 2L * 60L * 1000L
}

private class ChatNuVoiceRecorder2026(private val context: Context) {
    private var recorder: MediaRecorder? = null
    private var output: File? = null

    @Suppress("DEPRECATION")
    fun start() {
        check(recorder == null) { "Recorder already active" }
        val dir = File(context.cacheDir, "chatnu_recordings").apply { mkdirs() }
        val file = File(dir, "voice-${UUID.randomUUID()}.m4a")
        val active = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) MediaRecorder(context) else MediaRecorder()
        active.setAudioSource(MediaRecorder.AudioSource.MIC)
        active.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        active.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        active.setAudioEncodingBitRate(64_000)
        active.setAudioSamplingRate(44_100)
        active.setOutputFile(file.absolutePath)
        active.prepare()
        active.start()
        recorder = active
        output = file
    }

    fun stop(): File? {
        val active = recorder ?: return output
        val file = output
        runCatching { active.stop() }
        active.reset()
        active.release()
        recorder = null
        output = null
        return file
    }

    fun cancel() { stop()?.delete() }
}

private class ChatNuVoicePlayer2026 {
    private var player: MediaPlayer? = null
    fun play(file: File, onComplete: () -> Unit) {
        release()
        player = MediaPlayer().also { active ->
            active.setDataSource(file.absolutePath)
            active.setOnCompletionListener { release(); onComplete() }
            active.prepare()
            active.start()
        }
    }
    fun stop() = release()
    fun release() {
        player?.runCatching { stop() }
        player?.release()
        player = null
    }
}

private enum class LocationShareMode2026 { ONCE, LIVE }

private fun createCaptureUri2026(context: Context, prefix: String, extension: String): Uri {
    val dir = File(context.cacheDir, "chatnu_capture").apply { mkdirs() }
    val file = File(dir, "$prefix-${UUID.randomUUID()}.$extension")
    return FileProvider.getUriForFile(context, "${context.packageName}.files", file)
}

private fun locationPayload2026(location: Location, live: Boolean): String = String.format(
    Locale.US,
    "📍 %s: %.6f, %.6f",
    if (live) "Live location" else "Location",
    location.latitude,
    location.longitude
)

private fun formatDuration2026(seconds: Long): String = String.format(Locale.US, "%02d:%02d", seconds / 60L, seconds % 60L)

@Suppress("MissingPermission", "DEPRECATION")
private suspend fun currentLocation2026(context: Context): Location? = suspendCancellableCoroutine { continuation ->
    val manager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    val provider = when {
        manager.isProviderEnabled(LocationManager.GPS_PROVIDER) -> LocationManager.GPS_PROVIDER
        manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER) -> LocationManager.NETWORK_PROVIDER
        else -> null
    }
    if (provider == null) {
        continuation.resume(null)
        return@suspendCancellableCoroutine
    }
    val cached = runCatching { manager.getLastKnownLocation(provider) }.getOrNull()
    if (cached != null && System.currentTimeMillis() - cached.time < 60_000L) {
        continuation.resume(cached)
        return@suspendCancellableCoroutine
    }
    val listener = object : LocationListener {
        override fun onLocationChanged(location: Location) {
            manager.removeUpdates(this)
            if (continuation.isActive) continuation.resume(location)
        }
    }
    continuation.invokeOnCancellation { manager.removeUpdates(listener) }
    runCatching { manager.requestSingleUpdate(provider, listener, Looper.getMainLooper()) }.onFailure {
        manager.removeUpdates(listener)
        if (continuation.isActive) continuation.resume(cached)
    }
}

private const val LIVE_LOCATION_DURATION_2026 = 15L * 60L * 1000L
private const val LIVE_LOCATION_INTERVAL_2026 = 30L * 1000L
