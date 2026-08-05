package com.devnu.chatnu.feature.chat

import androidx.compose.foundation.background
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
import androidx.compose.material.icons.rounded.Call
import androidx.compose.material.icons.rounded.CameraAlt
import androidx.compose.material.icons.rounded.DoneAll
import androidx.compose.material.icons.rounded.KeyboardVoice
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material.icons.rounded.MoreHoriz
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.devnu.chatnu.core.model.ChatMessage
import com.devnu.chatnu.core.model.MessageKind
import com.devnu.chatnu.core.model.Presence
import com.devnu.chatnu.data.DemoChatRepository
import com.devnu.chatnu.ui.components.AmbientBackdrop
import com.devnu.chatnu.ui.components.GlassSurface
import com.devnu.chatnu.ui.components.GradientAvatar
import com.devnu.chatnu.ui.theme.ElectricViolet
import com.devnu.chatnu.ui.theme.SignalMint

@Composable
fun ConversationScreen(repository: DemoChatRepository, conversationId: String, onBack: () -> Unit) {
    val conversation = repository.conversation(conversationId) ?: return
    val messages by repository.messages(conversationId).collectAsStateWithLifecycle()
    var draft by remember { mutableStateOf("") }
    val listState = rememberLazyListState()
    LaunchedEffect(messages.size) { if (messages.isNotEmpty()) listState.animateScrollToItem(messages.lastIndex) }

    AmbientBackdrop {
        Column(Modifier.fillMaxSize()) {
            ConversationHeader(
                title = conversation.peer.displayName,
                subtitle = if (conversation.peer.presence == Presence.ONLINE) "online · encrypted" else "last seen recently",
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
                items(messages, key = { it.id }) { MessageBubble(it) }
            }
            Composer(
                value = draft,
                onValueChange = { draft = it },
                onSend = { repository.send(conversationId, draft); draft = "" },
            )
        }
    }
}

@Composable
private fun ConversationHeader(title: String, subtitle: String, seed: Int, onBack: () -> Unit) {
    GlassSurface(Modifier.fillMaxWidth(), RoundedCornerShape(bottomStart = 28.dp, bottomEnd = 28.dp)) {
        Row(
            Modifier.fillMaxWidth().padding(top = 48.dp, bottom = 12.dp, start = 8.dp, end = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
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

@Composable
private fun MessageBubble(message: ChatMessage) {
    if (message.kind == MessageKind.SYSTEM) {
        DatePill(message.body)
        return
    }
    Row(Modifier.fillMaxWidth(), horizontalArrangement = if (message.mine) Arrangement.End else Arrangement.Start) {
        Column(horizontalAlignment = if (message.mine) Alignment.End else Alignment.Start) {
            Box(
                Modifier
                    .clip(
                        if (message.mine) RoundedCornerShape(22.dp, 22.dp, 7.dp, 22.dp)
                        else RoundedCornerShape(22.dp, 22.dp, 22.dp, 7.dp),
                    )
                    .background(
                        if (message.mine) Brush.linearGradient(listOf(ElectricViolet, Color(0xFF5B8CFF)))
                        else Brush.linearGradient(listOf(Color(0xE6222430), Color(0xD9191B25))),
                    )
                    .padding(horizontal = 15.dp, vertical = 11.dp),
            ) {
                Text(message.body, style = MaterialTheme.typography.bodyLarge, color = Color.White)
            }
            Row(Modifier.padding(horizontal = 5.dp, vertical = 2.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                if (message.reaction != null) Text(message.reaction, style = MaterialTheme.typography.labelMedium)
                Text(message.timestamp, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                if (message.mine) Icon(Icons.Rounded.DoneAll, null, Modifier.size(14.dp), tint = SignalMint)
            }
        }
    }
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
private fun Composer(value: String, onValueChange: (String) -> Unit, onSend: () -> Unit) {
    GlassSurface(
        Modifier.fillMaxWidth().imePadding().navigationBarsPadding().padding(horizontal = 12.dp, vertical = 10.dp),
        RoundedCornerShape(26.dp),
    ) {
        Row(Modifier.fillMaxWidth().padding(7.dp), verticalAlignment = Alignment.Bottom) {
            IconButton(onClick = {}) { Icon(Icons.Rounded.Add, "Attach") }
            androidx.compose.foundation.text.BasicTextField(
                value = value,
                onValueChange = onValueChange,
                modifier = Modifier.weight(1f).padding(horizontal = 8.dp, vertical = 12.dp),
                textStyle = MaterialTheme.typography.bodyLarge.copy(color = MaterialTheme.colorScheme.onSurface),
                maxLines = 5,
                decorationBox = { inner ->
                    Box { if (value.isEmpty()) Text("Message", color = MaterialTheme.colorScheme.onSurfaceVariant); inner() }
                },
            )
            IconButton(onClick = {}) { Icon(Icons.Rounded.CameraAlt, "Camera") }
            Box(
                Modifier
                    .size(44.dp)
                    .clip(CircleShape)
                    .background(ElectricViolet)
                    .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null, onClick = if (value.isBlank()) ({}) else onSend),
                contentAlignment = Alignment.Center,
            ) {
                Icon(if (value.isBlank()) Icons.Rounded.KeyboardVoice else Icons.Rounded.Send, null, tint = Color.White)
            }
        }
    }
}
