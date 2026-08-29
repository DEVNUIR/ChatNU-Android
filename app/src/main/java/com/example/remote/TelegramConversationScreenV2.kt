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
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.MicOff
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Send
import androidx.compose.material.icons.filled.SpeakerPhone
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material.icons.filled.VideocamOff
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.FilledTonalIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
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
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
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
import androidx.core.content.FileProvider
import com.example.model.Conversation
import com.example.model.ConversationType
import com.example.model.Message
import com.example.model.MessageStatus
import com.example.model.MessageType
import com.example.ui.motion.ChatNuMotion
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import org.webrtc.SurfaceViewRenderer
import java.io.File
import java.util.Locale
import java.util.UUID
import kotlin.coroutines.resume

/**
 * Original Compose conversation surface guided by Telegram Android's low-friction interaction model.
 * Telegram source is a behavior reference; this file does not copy its Java implementation.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TelegramConversationScreenV2(
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
    onSendTypedMessage: (String, MessageType) -> Unit,
    onSendAttachment: (Uri) -> Unit,
    onResolveAttachment: suspend (Message) -> File,
    onOpenAttachment: (Message) -> Unit
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val listState = rememberLazyListState()
    val recorder = remember { VoiceRecorderController(context) }
    val audioPlayer = remember { VoiceNotePlayer() }

    var input by remember(conversation.id) { mutableStateOf("") }
    var showAttachSheet by remember { mutableStateOf(false) }
    var recording by remember { mutableStateOf(false) }
    var recordingStartedAt by remember { mutableLongStateOf(0L) }
    var recordingSeconds by remember { mutableLongStateOf(0L) }
    var pendingCapture by remember { mutableStateOf<Uri?>(null) }
    var pendingCallVideo by remember { mutableStateOf<Boolean?>(null) }
    var pendingLocationMode by remember { mutableStateOf<LocationShareMode?>(null) }
    var liveLocationJob by remember { mutableStateOf<Job?>(null) }
    var playingMessageId by remember { mutableStateOf<String?>(null) }

    val filePicker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri -> uri?.let(onSendAttachment) }
    val imagePicker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri -> uri?.let(onSendAttachment) }
    val videoPicker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri -> uri?.let(onSendAttachment) }
    val photoCapture = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { ok ->
        if (ok) pendingCapture?.let(onSendAttachment)
        pendingCapture = null
    }
    val videoCapture = rememberLauncherForActivityResult(ActivityResultContracts.CaptureVideo()) { ok ->
        if (ok) pendingCapture?.let(onSendAttachment)
        pendingCapture = null
    }

    fun startVoiceRecording() {
        runCatching { recorder.start() }.onSuccess {
            recordingStartedAt = SystemClock.elapsedRealtime()
            recording = true
        }
    }

    fun finishVoiceRecording(send: Boolean) {
        val file = runCatching { recorder.stop() }.getOrNull()
        recording = false
        recordingSeconds = 0L
        if (send && file != null && file.length() > 0L) {
            onSendAttachment(FileProvider.getUriForFile(context, "${context.packageName}.files", file))
        } else {
            file?.delete()
        }
    }

    fun startLocation(mode: LocationShareMode) {
        if (mode == LocationShareMode.ONCE) {
            scope.launch {
                currentLocation(context)?.let {
                    onSendTypedMessage(locationMessage(it, live = false), MessageType.LOCATION)
                }
            }
        } else {
            liveLocationJob?.cancel()
            liveLocationJob = scope.launch {
                val until = System.currentTimeMillis() + LIVE_LOCATION_DURATION_MS
                while (isActive && System.currentTimeMillis() < until) {
                    currentLocation(context)?.let {
                        onSendTypedMessage(locationMessage(it, live = true), MessageType.LIVE_LOCATION)
                    }
                    delay(LIVE_LOCATION_INTERVAL_MS)
                }
            }
        }
    }

    val voicePermission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) startVoiceRecording()
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
        val audioOk = grants[Manifest.permission.RECORD_AUDIO] == true || ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        val cameraOk = !video || grants[Manifest.permission.CAMERA] == true || ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
        if (audioOk && cameraOk) callManager.startCall(conversation, video)
        pendingCallVideo = null
    }

    fun requestLocation(mode: LocationShareMode) {
        val allowed = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (allowed) startLocation(mode) else {
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
        if (missing.isEmpty()) callManager.startCall(conversation, video) else {
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

    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) listState.animateScrollToItem(messages.lastIndex)
    }
    LaunchedEffect(recording) {
        while (recording) {
            recordingSeconds = ((SystemClock.elapsedRealtime() - recordingStartedAt) / 1000L).coerceAtLeast(0L)
            delay(250L)
        }
    }
    DisposableEffect(Unit) {
        onDispose {
            liveLocationJob?.cancel()
            recorder.cancel()
            audioPlayer.release()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, contentDescription = "Back") } },
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Surface(modifier = Modifier.size(40.dp), shape = CircleShape, color = MaterialTheme.colorScheme.primaryContainer) {
                            Box(contentAlignment = Alignment.Center) {
                                Text(conversation.title.firstOrNull()?.uppercase() ?: "?", fontWeight = FontWeight.Bold)
                            }
                        }
                        Spacer(Modifier.width(10.dp))
                        Column {
                            Text(conversation.title, maxLines = 1, overflow = TextOverflow.Ellipsis, fontWeight = FontWeight.Bold)
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.Lock, contentDescription = null, modifier = Modifier.size(12.dp), tint = MaterialTheme.colorScheme.primary)
                                Spacer(Modifier.width(4.dp))
                                Text(
                                    if (conversation.type == ConversationType.GROUP) "${conversation.members.size} members · encrypted" else "End-to-end encrypted",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                },
                actions = {
                    if (conversation.type == ConversationType.DIRECT && conversation.members.size == 2) {
                        IconButton(onClick = { beginCall(false) }) { Icon(Icons.Default.Call, contentDescription = "Voice call") }
                        IconButton(onClick = { beginCall(true) }) { Icon(Icons.Default.Videocam, contentDescription = "Video call") }
                    }
                    IconButton(onClick = onRetry) { Icon(Icons.Default.Refresh, contentDescription = "Reload") }
                }
            )
        },
        bottomBar = {
            Surface(tonalElevation = 2.dp, modifier = Modifier.fillMaxWidth().imePadding().navigationBarsPadding()) {
                AnimatedContent(
                    targetState = recording,
                    transitionSpec = {
                        (fadeIn(ChatNuMotion.fastTween) + scaleIn(ChatNuMotion.springyScale)) togetherWith
                            (fadeOut(ChatNuMotion.fastTween) + scaleOut(ChatNuMotion.springyScale))
                    },
                    label = "composer-mode"
                ) { isRecording ->
                    if (isRecording) {
                        Row(
                            modifier = Modifier.fillMaxWidth().padding(horizontal = 10.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            IconButton(onClick = { finishVoiceRecording(false) }) { Icon(Icons.Default.Close, contentDescription = "Cancel recording") }
                            Text("●  ${formatDuration(recordingSeconds)}", color = MaterialTheme.colorScheme.error, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                            FilledIconButton(onClick = { finishVoiceRecording(true) }) { Icon(Icons.Default.Send, contentDescription = "Send voice") }
                        }
                    } else {
                        Row(
                            modifier = Modifier.padding(horizontal = 7.dp, vertical = 7.dp),
                            verticalAlignment = Alignment.Bottom,
                            horizontalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            IconButton(onClick = { showAttachSheet = true }, modifier = Modifier.size(46.dp)) {
                                Icon(Icons.Default.AttachFile, contentDescription = "Attach")
                            }
                            OutlinedTextField(
                                value = input,
                                onValueChange = { input = it },
                                placeholder = { Text("Message") },
                                modifier = Modifier.weight(1f),
                                shape = RoundedCornerShape(22.dp),
                                minLines = 1,
                                maxLines = 5,
                                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Default)
                            )
                            AnimatedContent(
                                targetState = input.isNotBlank(),
                                transitionSpec = {
                                    (scaleIn(ChatNuMotion.springyScale) + fadeIn(ChatNuMotion.fastTween)) togetherWith
                                        (scaleOut(ChatNuMotion.springyScale) + fadeOut(ChatNuMotion.fastTween))
                                },
                                label = "send-mic"
                            ) { hasText ->
                                FilledIconButton(
                                    onClick = {
                                        if (hasText) {
                                            val value = input.trim()
                                            if (value.isNotEmpty()) {
                                                onSendText(value)
                                                input = ""
                                            }
                                        } else if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
                                            startVoiceRecording()
                                        } else voicePermission.launch(Manifest.permission.RECORD_AUDIO)
                                    },
                                    modifier = Modifier.size(48.dp)
                                ) {
                                    Icon(if (hasText) Icons.Default.Send else Icons.Default.Mic, contentDescription = if (hasText) "Send" else "Record voice")
                                }
                            }
                        }
                    }
                }
            }
        }
    ) { padding ->
        Box(modifier = Modifier.fillMaxSize().padding(padding)) {
            when {
                isLoading && messages.isEmpty() -> CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
                errorMessage != null && messages.isEmpty() -> {
                    Column(modifier = Modifier.align(Alignment.Center).padding(28.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(Icons.Default.ErrorOutline, contentDescription = null, tint = MaterialTheme.colorScheme.error, modifier = Modifier.size(36.dp))
                        Spacer(Modifier.height(10.dp))
                        Text(errorMessage, textAlign = TextAlign.Center)
                        Spacer(Modifier.height(10.dp))
                        OutlinedButton(onClick = onRetry) { Text("Try again") }
                    }
                }
                messages.isEmpty() -> {
                    Column(modifier = Modifier.align(Alignment.Center), horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(Icons.Default.Lock, contentDescription = null, modifier = Modifier.size(32.dp), tint = MaterialTheme.colorScheme.primary)
                        Spacer(Modifier.height(8.dp))
                        Text("Encrypted conversation", fontWeight = FontWeight.Bold)
                        Text("Messages are encrypted before upload.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                else -> LazyColumn(
                    state = listState,
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 10.dp),
                    verticalArrangement = Arrangement.spacedBy(5.dp)
                ) {
                    items(messages, key = { it.id }) { message ->
                        TelegramMessageBubbleV2(
                            message = message,
                            mine = message.senderId == currentUserId,
                            playing = playingMessageId == message.id,
                            onVoice = { playVoice(message) },
                            onOpenAttachment = { onOpenAttachment(message) },
                            onOpenLocation = { location ->
                                val uri = Uri.parse("geo:${location.first},${location.second}?q=${location.first},${location.second}")
                                runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, uri)) }
                            }
                        )
                    }
                }
            }
            AnimatedVisibility(
                visible = liveLocationJob?.isActive == true,
                enter = fadeIn(ChatNuMotion.fastTween),
                exit = fadeOut(ChatNuMotion.fastTween),
                modifier = Modifier.align(Alignment.TopCenter)
            ) {
                Surface(shape = RoundedCornerShape(18.dp), tonalElevation = 5.dp, modifier = Modifier.padding(8.dp)) {
                    Row(modifier = Modifier.padding(horizontal = 12.dp, vertical = 7.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.MyLocation, contentDescription = null, modifier = Modifier.size(17.dp))
                        Spacer(Modifier.width(6.dp))
                        Text("Live location · 15 min", style = MaterialTheme.typography.labelMedium)
                        TextButton(onClick = { liveLocationJob?.cancel(); liveLocationJob = null }) { Text("Stop") }
                    }
                }
            }
        }
    }

    if (showAttachSheet) {
        ModalBottomSheet(onDismissRequest = { showAttachSheet = false }) {
            Text("Share", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp))
            AttachAction(Icons.Default.Image, "Photo", "Encrypted gallery image") {
                showAttachSheet = false; imagePicker.launch("image/*")
            }
            AttachAction(Icons.Default.Videocam, "Video", "Encrypted gallery video") {
                showAttachSheet = false; videoPicker.launch("video/*")
            }
            AttachAction(Icons.Default.CameraAlt, "Camera photo", "Capture then encrypt") {
                showAttachSheet = false
                createCaptureUri(context, "photo", "jpg").also { pendingCapture = it; photoCapture.launch(it) }
            }
            AttachAction(Icons.Default.Videocam, "Video message", "Capture a short video then encrypt") {
                showAttachSheet = false
                createCaptureUri(context, "video-message", "mp4").also { pendingCapture = it; videoCapture.launch(it) }
            }
            AttachAction(Icons.Default.Description, "File", "Any supported file type") {
                showAttachSheet = false; filePicker.launch("*/*")
            }
            AttachAction(Icons.Default.LocationOn, "Location", "Encrypted coordinates") {
                showAttachSheet = false; requestLocation(LocationShareMode.ONCE)
            }
            AttachAction(Icons.Default.MyLocation, "Live location", "Encrypted updates for 15 minutes") {
                showAttachSheet = false; requestLocation(LocationShareMode.LIVE)
            }
            Spacer(Modifier.height(20.dp))
        }
    }

    CallOverlayV2(callState, callManager)
}

@Composable
private fun AttachAction(icon: androidx.compose.ui.graphics.vector.ImageVector, title: String, subtitle: String, onClick: () -> Unit) {
    ListItem(
        headlineContent = { Text(title, fontWeight = FontWeight.SemiBold) },
        supportingContent = { Text(subtitle) },
        leadingContent = {
            Surface(shape = CircleShape, color = MaterialTheme.colorScheme.primaryContainer) {
                Icon(icon, contentDescription = null, modifier = Modifier.padding(11.dp))
            }
        },
        modifier = Modifier.clickable(onClick = onClick)
    )
}

@Composable
private fun TelegramMessageBubbleV2(
    message: Message,
    mine: Boolean,
    playing: Boolean,
    onVoice: () -> Unit,
    onOpenAttachment: () -> Unit,
    onOpenLocation: (Pair<Double, Double>) -> Unit
) {
    if (message.type == MessageType.SYSTEM_KEY_CHANGE) {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
            Surface(shape = RoundedCornerShape(18.dp), color = MaterialTheme.colorScheme.surfaceContainerHighest) {
                Text(message.text, modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp), style = MaterialTheme.typography.labelSmall)
            }
        }
        return
    }
    val location = if (message.type == MessageType.LOCATION || message.type == MessageType.LIVE_LOCATION) parseLocation(message.text) else null
    Box(modifier = Modifier.fillMaxWidth()) {
        Surface(
            modifier = Modifier.align(if (mine) Alignment.CenterEnd else Alignment.CenterStart).widthIn(max = 360.dp),
            shape = RoundedCornerShape(
                topStart = 18.dp,
                topEnd = 18.dp,
                bottomStart = if (mine) 18.dp else 5.dp,
                bottomEnd = if (mine) 5.dp else 18.dp
            ),
            color = if (mine) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceContainerHigh
        ) {
            Column(modifier = Modifier.padding(horizontal = 11.dp, vertical = 8.dp)) {
                if (!mine && message.senderName.isNotBlank()) {
                    Text(message.senderName, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.height(3.dp))
                }
                when {
                    message.type == MessageType.VOICE && message.attachmentId != null -> {
                        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.clickable(onClick = onVoice)) {
                            FilledTonalIconButton(onClick = onVoice, modifier = Modifier.size(42.dp)) {
                                Icon(if (playing) Icons.Default.Pause else Icons.Default.PlayArrow, contentDescription = if (playing) "Pause" else "Play")
                            }
                            Spacer(Modifier.width(8.dp))
                            Column {
                                Text("Voice message", fontWeight = FontWeight.SemiBold)
                                Text(if (playing) "Playing decrypted audio" else "Tap to decrypt & play", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                    }
                    location != null -> {
                        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.clickable { onOpenLocation(location) }) {
                            Icon(if (message.type == MessageType.LIVE_LOCATION) Icons.Default.MyLocation else Icons.Default.LocationOn, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                            Spacer(Modifier.width(8.dp))
                            Column {
                                Text(if (message.type == MessageType.LIVE_LOCATION) "Live location" else "Location", fontWeight = FontWeight.SemiBold)
                                Text(String.format(Locale.US, "%.5f, %.5f", location.first, location.second), style = MaterialTheme.typography.labelSmall)
                            }
                        }
                    }
                    message.attachmentId != null -> {
                        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.clickable(onClick = onOpenAttachment)) {
                            Icon(
                                when (message.type) {
                                    MessageType.IMAGE -> Icons.Default.Image
                                    MessageType.VIDEO, MessageType.VIEW_ONCE_VIDEO -> Icons.Default.Videocam
                                    else -> Icons.Default.Description
                                },
                                contentDescription = null,
                                modifier = Modifier.size(25.dp)
                            )
                            Spacer(Modifier.width(8.dp))
                            Column {
                                Text(message.fileName ?: message.text, maxLines = 2, overflow = TextOverflow.Ellipsis, fontWeight = FontWeight.SemiBold)
                                message.fileSize?.let { Text(it, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant) }
                                Text("Encrypted media · tap to open", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary)
                            }
                        }
                    }
                    else -> Text(message.text, style = MaterialTheme.typography.bodyLarge)
                }
                Spacer(Modifier.height(4.dp))
                Row(modifier = Modifier.align(Alignment.End), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                    Text(message.timestamp, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    if (mine) {
                        Text(
                            when (message.status) {
                                MessageStatus.SENDING, MessageStatus.QUEUED -> "…"
                                MessageStatus.FAILED -> "!"
                                MessageStatus.READ -> "✓✓"
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
private fun CallOverlayV2(state: CallUiState, manager: WebRtcCallManager) {
    if (state.phase == CallPhase.IDLE) return
    val context = LocalContext.current
    var accepting by remember { mutableStateOf(false) }
    val acceptPermission = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { grants ->
        val audioOk = grants[Manifest.permission.RECORD_AUDIO] == true || ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        val cameraOk = !state.video || grants[Manifest.permission.CAMERA] == true || ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
        if (audioOk && cameraOk) manager.acceptIncoming()
        accepting = false
    }
    fun accept() {
        val missing = buildList {
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) add(Manifest.permission.RECORD_AUDIO)
            if (state.video && ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) add(Manifest.permission.CAMERA)
        }
        if (missing.isEmpty()) manager.acceptIncoming() else {
            accepting = true
            acceptPermission.launch(missing.toTypedArray())
        }
    }
    if (state.phase == CallPhase.INCOMING) {
        AlertDialog(
            onDismissRequest = {},
            title = { Text(if (state.video) "Incoming video call" else "Incoming voice call") },
            text = { Text(state.peerName.ifBlank { "ChatNU user" }) },
            confirmButton = { TextButton(onClick = { accept() }, enabled = !accepting) { Text("Accept") } },
            dismissButton = { TextButton(onClick = manager::rejectIncoming) { Text("Decline") } }
        )
        return
    }
    Dialog(onDismissRequest = {}, properties = DialogProperties(usePlatformDefaultWidth = false, dismissOnBackPress = false, dismissOnClickOutside = false)) {
        Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.surface) {
            Box(modifier = Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding()) {
                if (state.video && state.phase == CallPhase.ACTIVE) {
                    WebRtcRendererV2(Modifier.fillMaxSize(), manager, local = false)
                    Surface(modifier = Modifier.align(Alignment.TopEnd).padding(16.dp).size(width = 112.dp, height = 160.dp), shape = RoundedCornerShape(18.dp), tonalElevation = 6.dp) {
                        WebRtcRendererV2(Modifier.fillMaxSize(), manager, local = true)
                    }
                } else {
                    Column(modifier = Modifier.align(Alignment.Center).padding(32.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                        Surface(modifier = Modifier.size(96.dp), shape = CircleShape, color = MaterialTheme.colorScheme.primaryContainer) {
                            Box(contentAlignment = Alignment.Center) { Text(state.peerName.firstOrNull()?.uppercase() ?: "?", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold) }
                        }
                        Spacer(Modifier.height(18.dp))
                        Text(state.peerName.ifBlank { "ChatNU call" }, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
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
                        if (state.phase == CallPhase.CONNECTING) { Spacer(Modifier.height(16.dp)); CircularProgressIndicator() }
                    }
                }
                Row(modifier = Modifier.align(Alignment.BottomCenter).padding(24.dp), horizontalArrangement = Arrangement.spacedBy(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    FilledTonalIconButton(onClick = manager::toggleMute, modifier = Modifier.size(58.dp)) { Icon(if (state.muted) Icons.Default.MicOff else Icons.Default.Mic, contentDescription = "Mute") }
                    if (state.video) FilledTonalIconButton(onClick = manager::toggleCamera, modifier = Modifier.size(58.dp)) { Icon(if (state.cameraEnabled) Icons.Default.Videocam else Icons.Default.VideocamOff, contentDescription = "Camera") }
                    FilledTonalIconButton(onClick = manager::toggleSpeaker, modifier = Modifier.size(58.dp)) { Icon(Icons.Default.SpeakerPhone, contentDescription = "Speaker") }
                    FilledTonalIconButton(onClick = manager::endCall, modifier = Modifier.size(64.dp)) { Icon(Icons.Default.CallEnd, contentDescription = "End", tint = MaterialTheme.colorScheme.error) }
                }
            }
        }
    }
}

@Composable
private fun WebRtcRendererV2(modifier: Modifier, manager: WebRtcCallManager, local: Boolean) {
    AndroidView(
        modifier = modifier,
        factory = { context -> SurfaceViewRenderer(context).also { manager.attachRenderer(it, local) } },
        update = { manager.attachRenderer(it, local) }
    )
}

private class VoiceRecorderController(private val context: Context) {
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

private class VoiceNotePlayer {
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

private enum class LocationShareMode { ONCE, LIVE }

private fun createCaptureUri(context: Context, prefix: String, extension: String): Uri {
    val dir = File(context.cacheDir, "chatnu_capture").apply { mkdirs() }
    val file = File(dir, "$prefix-${UUID.randomUUID()}.$extension")
    return FileProvider.getUriForFile(context, "${context.packageName}.files", file)
}

private fun locationMessage(location: Location, live: Boolean): String {
    return String.format(Locale.US, "📍 %s: %.6f, %.6f", if (live) "Live location" else "Location", location.latitude, location.longitude)
}

private fun parseLocation(text: String): Pair<Double, Double>? {
    val match = Regex("(-?\\d{1,3}\\.\\d+),\\s*(-?\\d{1,3}\\.\\d+)").find(text) ?: return null
    val lat = match.groupValues[1].toDoubleOrNull() ?: return null
    val lon = match.groupValues[2].toDoubleOrNull() ?: return null
    if (lat !in -90.0..90.0 || lon !in -180.0..180.0) return null
    return lat to lon
}

private fun formatDuration(seconds: Long): String = String.format(Locale.US, "%02d:%02d", seconds / 60L, seconds % 60L)

@Suppress("MissingPermission", "DEPRECATION")
private suspend fun currentLocation(context: Context): Location? = suspendCancellableCoroutine { continuation ->
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

private const val LIVE_LOCATION_DURATION_MS = 15L * 60L * 1000L
private const val LIVE_LOCATION_INTERVAL_MS = 30L * 1000L
