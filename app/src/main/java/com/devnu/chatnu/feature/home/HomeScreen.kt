package com.devnu.chatnu.feature.home

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
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
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.Archive
import androidx.compose.material.icons.rounded.ChatBubble
import androidx.compose.material.icons.rounded.DoneAll
import androidx.compose.material.icons.rounded.Hub
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material.icons.rounded.PushPin
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material.icons.rounded.Tune
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.consume
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.devnu.chatnu.core.model.ConnectionState
import com.devnu.chatnu.core.model.Conversation
import com.devnu.chatnu.core.model.Presence
import com.devnu.chatnu.ui.components.AmbientBackdrop
import com.devnu.chatnu.ui.components.GlassSurface
import com.devnu.chatnu.ui.components.GradientAvatar
import com.devnu.chatnu.ui.components.PillButton
import com.devnu.chatnu.ui.theme.ElectricViolet
import com.devnu.chatnu.ui.theme.SignalMint
import kotlin.math.roundToInt

@Composable
fun HomeScreen(
    viewModel: HomeViewModel,
    onOpenConversation: (String) -> Unit,
    onOpenNodes: () -> Unit,
    onOpenSettings: () -> Unit,
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    AmbientBackdrop {
        Box(Modifier.fillMaxSize()) {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(top = 60.dp, bottom = 132.dp),
            ) {
                item {
                    Header(state.connectionState, onOpenNodes, onOpenSettings)
                    Spacer(Modifier.height(18.dp))
                    SearchField(state.query, viewModel::updateQuery)
                    Spacer(Modifier.height(18.dp))
                    ArchiveSwitcher(state.showingArchived, viewModel::toggleArchiveView)
                    SectionHeader(
                        if (state.showingArchived) "Archived" else "Recent",
                        "${state.conversations.size} conversations",
                    )
                }
                items(state.conversations, key = { it.id }) { conversation ->
                    SwipeConversationRow(
                        item = conversation,
                        onClick = { onOpenConversation(conversation.id) },
                        onPin = { viewModel.togglePinned(conversation.id) },
                        onArchive = { viewModel.toggleArchived(conversation.id) },
                    )
                }
            }
            BottomDock(
                modifier = Modifier.align(Alignment.BottomCenter),
                onNodes = onOpenNodes,
                onSettings = onOpenSettings,
            )
            FloatingActionButton(
                onClick = {},
                modifier = Modifier.align(Alignment.BottomEnd).navigationBarsPadding().padding(end = 24.dp, bottom = 86.dp),
                shape = CircleShape,
                containerColor = ElectricViolet,
                contentColor = Color.White,
            ) { Icon(Icons.Rounded.Add, "New chat") }
        }
    }
}

@Composable
private fun Header(connectionState: ConnectionState, onNodes: () -> Unit, onSettings: () -> Unit) {
    Column(Modifier.padding(horizontal = 20.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column {
                Text("Messages", style = MaterialTheme.typography.headlineLarge)
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    val connected = connectionState == ConnectionState.CONNECTED
                    Box(Modifier.size(7.dp).background(if (connected) SignalMint else MaterialTheme.colorScheme.error, CircleShape))
                    Text(
                        when (connectionState) {
                            ConnectionState.CONNECTED -> "Connected through chatnu.devnu.ir"
                            ConnectionState.CONNECTING -> "Connecting to relay…"
                            ConnectionState.DEGRADED -> "Offline queue active"
                            ConnectionState.DISCONNECTED -> "Disconnected"
                        },
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
            Spacer(Modifier.weight(1f))
            IconButton(onClick = onNodes) { Icon(Icons.Rounded.Hub, "Nodes") }
            IconButton(onClick = onSettings) { Icon(Icons.Rounded.Settings, "Settings") }
        }
    }
}

@Composable
private fun SearchField(value: String, onChange: (String) -> Unit) {
    GlassSurface(Modifier.padding(horizontal = 20.dp).fillMaxWidth(), RoundedCornerShape(20.dp)) {
        Row(Modifier.padding(horizontal = 16.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Rounded.Search, null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
            androidx.compose.foundation.text.BasicTextField(
                value = value,
                onValueChange = onChange,
                modifier = Modifier.weight(1f).padding(horizontal = 12.dp),
                singleLine = true,
                textStyle = MaterialTheme.typography.bodyLarge.copy(color = MaterialTheme.colorScheme.onSurface),
                decorationBox = { inner -> Box { if (value.isEmpty()) Text("Search messages or people", color = MaterialTheme.colorScheme.onSurfaceVariant); inner() } },
            )
            Icon(Icons.Rounded.Tune, null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun ArchiveSwitcher(showingArchived: Boolean, onToggle: () -> Unit) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp), horizontalArrangement = Arrangement.End) {
        Row(
            Modifier.clip(CircleShape).background(Color.White.copy(alpha = .06f)).clickable(onClick = onToggle).padding(horizontal = 12.dp, vertical = 7.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Icon(Icons.Rounded.Archive, null, Modifier.size(15.dp), tint = MaterialTheme.colorScheme.primary)
            Text(if (showingArchived) "Show active" else "Archived", style = MaterialTheme.typography.labelMedium)
        }
    }
}

@Composable
private fun SectionHeader(title: String, detail: String) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(title, style = MaterialTheme.typography.titleMedium)
        Spacer(Modifier.weight(1f))
        Text(detail, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun SwipeConversationRow(item: Conversation, onClick: () -> Unit, onPin: () -> Unit, onArchive: () -> Unit) {
    var dragOffset by remember(item.id) { mutableFloatStateOf(0f) }
    val animatedOffset by animateFloatAsState(dragOffset, label = "conversation-swipe")
    Box(Modifier.fillMaxWidth()) {
        Row(Modifier.matchParentSize().padding(horizontal = 24.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Rounded.PushPin, null, tint = SignalMint)
            Spacer(Modifier.weight(1f))
            Icon(Icons.Rounded.Archive, null, tint = MaterialTheme.colorScheme.error)
        }
        ConversationRow(
            item = item,
            modifier = Modifier
                .offset { IntOffset(animatedOffset.roundToInt(), 0) }
                .pointerInput(item.id) {
                    detectHorizontalDragGestures(
                        onHorizontalDrag = { change, amount ->
                            change.consume()
                            dragOffset = (dragOffset + amount).coerceIn(-180f, 180f)
                        },
                        onDragEnd = {
                            when {
                                dragOffset > 110f -> onPin()
                                dragOffset < -110f -> onArchive()
                            }
                            dragOffset = 0f
                        },
                        onDragCancel = { dragOffset = 0f },
                    )
                },
            onClick = onClick,
        )
    }
}

@Composable
private fun ConversationRow(item: Conversation, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Row(
        modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.background.copy(alpha = .72f))
            .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null, onClick = onClick)
            .padding(horizontal = 20.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        GradientAvatar(item.peer.displayName, item.peer.accentSeed, Modifier.size(54.dp), item.peer.presence == Presence.ONLINE)
        Column(Modifier.weight(1f).padding(horizontal = 14.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(item.peer.displayName, style = MaterialTheme.typography.titleMedium, maxLines = 1)
                if (item.peer.verified) Icon(Icons.Rounded.Lock, null, Modifier.padding(start = 6.dp).size(14.dp), tint = SignalMint)
                if (item.pinned) Icon(Icons.Rounded.PushPin, null, Modifier.padding(start = 5.dp).size(13.dp), tint = MaterialTheme.colorScheme.primary)
                Spacer(Modifier.weight(1f))
                Text(item.timestamp, style = MaterialTheme.typography.labelMedium, color = if (item.unreadCount > 0) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                AnimatedVisibility(item.typing, enter = fadeIn(), exit = fadeOut()) {
                    Text("typing…", style = MaterialTheme.typography.bodyMedium, color = SignalMint, fontWeight = FontWeight.Medium)
                }
                if (!item.typing) Text(item.preview, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Spacer(Modifier.weight(1f))
                if (item.unreadCount > 0) {
                    Box(Modifier.clip(CircleShape).background(ElectricViolet).padding(horizontal = 7.dp, vertical = 3.dp), contentAlignment = Alignment.Center) {
                        Text(item.unreadCount.toString(), style = MaterialTheme.typography.labelMedium, color = Color.White)
                    }
                } else Icon(Icons.Rounded.DoneAll, null, Modifier.size(16.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
private fun BottomDock(modifier: Modifier = Modifier, onNodes: () -> Unit, onSettings: () -> Unit) {
    GlassSurface(modifier.navigationBarsPadding().padding(horizontal = 20.dp, vertical = 12.dp).fillMaxWidth(), RoundedCornerShape(26.dp)) {
        Row(Modifier.fillMaxWidth().padding(8.dp), horizontalArrangement = Arrangement.SpaceBetween) {
            PillButton(Icons.Rounded.ChatBubble, "Chats", selected = true, onClick = {})
            PillButton(Icons.Rounded.Hub, "Nodes", onClick = onNodes)
            PillButton(Icons.Rounded.Settings, "Settings", onClick = onSettings)
        }
    }
}
