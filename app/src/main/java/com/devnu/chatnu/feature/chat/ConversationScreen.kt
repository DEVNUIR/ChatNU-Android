package com.devnu.chatnu.feature.chat

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.ArrowBackIosNew
import androidx.compose.material.icons.rounded.AttachFile
import androidx.compose.material.icons.rounded.Call
import androidx.compose.material.icons.rounded.CameraAlt
import androidx.compose.material.icons.rounded.Description
import androidx.compose.material.icons.rounded.Done
import androidx.compose.material.icons.rounded.DoneAll
import androidx.compose.material.icons.rounded.ErrorOutline
import androidx.compose.material.icons.rounded.Image
import androidx.compose.material.icons.rounded.KeyboardVoice
import androidx.compose.material.icons.rounded.LocationOn
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material.icons.rounded.MoreHoriz
import androidx.compose.material.icons.rounded.Reply
import androidx.compose.material.icons.rounded.Schedule
import androidx.compose.material.icons.rounded.Send
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.devnu.chatnu.core.model.ChatMessage
import com.devnu.chatnu.core.model.DeliveryState
import com.devnu.chatnu.core.model.MessageKind
import com.devnu.chatnu.core.model.Presence
import com.devnu.chatnu.ui.components.AmbientBackdrop
import com.devnu.chatnu.ui.components.GlassSurface
import com.devnu.chatnu.ui.components.GradientAvatar
import com.devnu.chatnu.ui.theme.ElectricViolet
import com.devnu.chatnu.ui.theme.SignalMint

@Composable
fun ConversationScreen(viewModel: ConversationViewModel, onBack: () -> Unit) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val conversation = state.conversation ?: return
    val listState = rememberLazyListState()
    var selectedMessageId by remember { mutableStateOf<String?>(null) }
    LaunchedEffect(state.messages.size) {
        if (state.messages.isNotEmpty()) listState.animateScrollToItem(state.messages.lastIndex)
    }

    AmbientBackdrop {
        Column(Modifier.fillMaxSize()) {
            ConversationHeader(
                title = conversation.peer.displayName,
                subtitle = if (conversation.peer.presence == Presence.ONLINE) "online · encrypted transport" else "last seen recently",
                seed = conversation.peer.accentSeed,
                onBack = onBack,
            )
            LazyColumn(
                modifier = Modifier.weight(1f),
                state = listState,
                contentPadding = PaddingValues(horizontal = 14.dp, vertical = 18.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                item { DatePill("Today") }
                items(state.messages, key = { it.id }) { message ->
                    MessageBubble(
                        message = message,
                        selected = selectedMessageId == message.id,
                        onSelect = { selectedMessageId = if (selectedMessageId == message.id) null else message.id },
                        onRetry = { viewModel.retry(message.id) },
                        onReply = { viewModel.replyTo(message); selectedMessageId = null },
                        onReact = { viewModel.react(message.id, it); selectedMessageId = null },
                    )
                }
            }
            AnimatedVisibility(state.attachmentTrayVisible) { AttachmentTray() }
            Composer(
                value = state.draft,
                replyingTo = state.replyingTo,
                recording = state.recording,
                onCancelReply = { viewModel.replyTo(null) },
                onValueChange = viewModel::updateDraft,
                onSend = viewModel::send,
                onToggleRecording = viewModel::toggleRecording,
                onToggleAttachments = viewModel::toggleAttachmentTray,
            )
        }
    }
}

@Composable
private fun ConversationHeader(title: String, subtitle: String, seed: Int, onBack: () -> Unit) {
    GlassSurface(Modifier.fillMaxWidth(), RoundedCornerShape(bottomStart = 28.dp, bottomEnd = 28.dp)) {
        Row(Modifier.fillMaxWidth().padding(top = 48.dp, bottom = 12.dp, start = 8.dp, end = 8.dp), verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onBack) { Icon(Icons.Rounded.ArrowBackIosNew, "Back") }
            GradientAvatar(title, seed, Modifier.size(42.dp), online = true)
            Column(Modifier.weight(1f).padding(horizontal = 12.dp)) {
                Text(title, style = MaterialTheme.typography.titleMedium)
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Icon(Icons.Rounded.Lock, null, Modifier.size(12.dp), tint = SignalMint)
                    Text(subtitle, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            IconButton(onClick = {}) { Icon(Icons.Rounded.Call, "Call") }
            IconButton(onClick = {}) { Icon(Icons.Rounded.MoreHoriz, "More") }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun MessageBubble(
    message: ChatMessage,
    selected: Boolean,
    onSelect: () -> Unit,
    onRetry: () -> Unit,
    onReply: () -> Unit,
    onReact: (String?) -> Unit,
) {
    if (message.kind == MessageKind.SYSTEM) {
        DatePill(message.body)
        return
    }
    Row(Modifier.fillMaxWidth(), horizontalArrangement = if (message.mine) Arrangement.End else Arrangement.Start) {
        Column(horizontalAlignment = if (message.mine) Alignment.End else Alignment.Start) {
            Box(
                Modifier
                    .clip(if (message.mine) RoundedCornerShape(22.dp, 22.dp, 7.dp, 22.dp) else RoundedCornerShape(22.dp, 22.dp, 22.dp, 7.dp))
                    .background(if (message.mine) Brush.linearGradient(listOf(ElectricViolet, Color(0xFF5B8CFF))) else Brush.linearGradient(listOf(Color(0xE6222430), Color(0xD9191B25))))
                    .combinedClickable(onClick = { if (message.delivery == DeliveryState.FAILED) onRetry() }, onLongClick = onSelect)
                    .padding(horizontal = 15.dp, vertical = 11.dp),
            ) { Text(message.body, style = MaterialTheme.typography.bodyLarge, color = Color.White) }
            Row(Modifier.padding(horizontal = 5.dp, vertical = 2.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                if (message.reaction != null) Text(message.reaction, style = MaterialTheme.typography.labelMedium)
                Text(message.timestamp, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                if (message.mine) DeliveryIcon(message.delivery)
            }
            AnimatedVisibility(selected) {
                Row(
                    Modifier.clip(CircleShape).background(Color.White.copy(alpha = .08f)).padding(horizontal = 8.dp, vertical = 5.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    listOf("❤️", "😂", "👍", "🔥").forEach { emoji -> Text(emoji, Modifier.clickable { onReact(emoji) }) }
                    Icon(Icons.Rounded.Reply, "Reply", Modifier.size(18.dp).clickable(onClick = onReply), tint = MaterialTheme.colorScheme.primary)
                }
            }
        }
    }
}

@Composable
private fun DeliveryIcon(delivery: DeliveryState) {
    val icon = when (delivery) {
        DeliveryState.PENDING, DeliveryState.SENDING -> Icons.Rounded.Schedule
        DeliveryState.SENT -> Icons.Rounded.Done
        DeliveryState.DELIVERED, DeliveryState.READ -> Icons.Rounded.DoneAll
        DeliveryState.FAILED -> Icons.Rounded.ErrorOutline
    }
    val tint = if (delivery == DeliveryState.FAILED) MaterialTheme.colorScheme.error else SignalMint
    Icon(icon, null, Modifier.size(14.dp), tint = tint)
}

@Composable
private fun DatePill(text: String) {
    Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
        Box(Modifier.clip(CircleShape).background(Color.White.copy(alpha = 0.06f)).padding(horizontal = 12.dp, vertical = 6.dp)) {
            Text(text, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
        }
    }
}

@Composable
private fun AttachmentTray() {
    Row(Modifier.fillMaxWidth().padding(horizontal = 18.dp, vertical = 8.dp), horizontalArrangement = Arrangement.SpaceEvenly) {
        AttachmentAction(Icons.Rounded.Image, "Gallery")
        AttachmentAction(Icons.Rounded.CameraAlt, "Camera")
        AttachmentAction(Icons.Rounded.Description, "File")
        AttachmentAction(Icons.Rounded.LocationOn, "Location")
    }
}

@Composable
private fun AttachmentAction(icon: androidx.compose.ui.graphics.vector.ImageVector, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(5.dp)) {
        Box(Modifier.size(46.dp).clip(CircleShape).background(Color.White.copy(alpha = .07f)), contentAlignment = Alignment.Center) {
            Icon(icon, label, tint = MaterialTheme.colorScheme.primary)
        }
        Text(label, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun Composer(
    value: String,
    replyingTo: ChatMessage?,
    recording: Boolean,
    onCancelReply: () -> Unit,
    onValueChange: (String) -> Unit,
    onSend: () -> Unit,
    onToggleRecording: () -> Unit,
    onToggleAttachments: () -> Unit,
) {
    GlassSurface(Modifier.fillMaxWidth().imePadding().navigationBarsPadding().padding(horizontal = 12.dp, vertical = 10.dp), RoundedCornerShape(26.dp)) {
        Column {
            AnimatedVisibility(replyingTo != null) {
                Row(Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Rounded.Reply, null, Modifier.size(17.dp), tint = MaterialTheme.colorScheme.primary)
                    Text(replyingTo?.body.orEmpty(), Modifier.weight(1f).padding(horizontal = 8.dp), maxLines = 1, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text("×", Modifier.clickable(onClick = onCancelReply), style = MaterialTheme.typography.titleLarge)
                }
            }
            AnimatedVisibility(recording) { RecorderBar() }
            Row(Modifier.fillMaxWidth().padding(7.dp), verticalAlignment = Alignment.Bottom) {
                IconButton(onClick = onToggleAttachments) { Icon(Icons.Rounded.AttachFile, "Attach") }
                androidx.compose.foundation.text.BasicTextField(
                    value = value,
                    onValueChange = onValueChange,
                    modifier = Modifier.weight(1f).padding(horizontal = 8.dp, vertical = 12.dp),
                    textStyle = MaterialTheme.typography.bodyLarge.copy(color = MaterialTheme.colorScheme.onSurface),
                    maxLines = 5,
                    decorationBox = { inner -> Box { if (value.isEmpty()) Text(if (recording) "Recording voice…" else "Message", color = MaterialTheme.colorScheme.onSurfaceVariant); inner() } },
                )
                Box(
                    Modifier.size(44.dp).clip(CircleShape).background(ElectricViolet)
                        .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null, onClick = if (value.isBlank()) onToggleRecording else onSend),
                    contentAlignment = Alignment.Center,
                ) { Icon(if (value.isBlank()) Icons.Rounded.KeyboardVoice else Icons.Rounded.Send, null, tint = Color.White) }
            }
        }
    }
}

@Composable
private fun RecorderBar() {
    val transition = rememberInfiniteTransition(label = "recording")
    val pulse by transition.animateFloat(.35f, 1f, infiniteRepeatable(tween(700), RepeatMode.Reverse), label = "pulse")
    Row(Modifier.fillMaxWidth().height(42.dp).padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(9.dp).alpha(pulse).background(MaterialTheme.colorScheme.error, CircleShape))
        Text("00:00", Modifier.padding(start = 8.dp), color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(Modifier.weight(1f))
        Text("Tap microphone to finish", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}
