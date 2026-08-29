package com.example.remote

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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PushPin
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.VolumeOff
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.model.Conversation
import com.example.model.ConversationType
import com.example.model.User
import kotlinx.coroutines.launch

/**
 * A compact conversation list inspired by Telegram Android's information hierarchy:
 * avatar + title + one-line preview + timestamp + unread state, with a single compose FAB.
 * This is an original Jetpack Compose implementation; no Telegram source code is copied.
 */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun TelegramHomeScreen(
    user: User?,
    conversations: List<Conversation>,
    realtimeStatus: RealtimeStatus,
    isRefreshing: Boolean,
    errorMessage: String?,
    onRefresh: () -> Unit,
    onSelectConversation: (Conversation) -> Unit,
    onTogglePinConversation: (String) -> Unit,
    onOpenSettings: () -> Unit,
    onOpenDirect: suspend (String) -> Result<Unit>,
    onCreateGroup: suspend (String, List<String>) -> Result<Unit>
) {
    var searchOpen by remember { mutableStateOf(false) }
    var query by remember { mutableStateOf("") }
    var showComposer by remember { mutableStateOf(false) }
    var showDirectDialog by remember { mutableStateOf(false) }
    var showGroupDialog by remember { mutableStateOf(false) }
    var directUsername by remember { mutableStateOf("") }
    var groupTitle by remember { mutableStateOf("") }
    var groupMembers by remember { mutableStateOf("") }
    var composerError by remember { mutableStateOf<String?>(null) }
    var composerLoading by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    val filtered = remember(conversations, query) {
        val needle = query.trim()
        if (needle.isBlank()) conversations
        else conversations.filter {
            it.title.contains(needle, ignoreCase = true) ||
                it.lastMessageText.contains(needle, ignoreCase = true)
        }
    }

    Scaffold(
        topBar = {
            Column {
                TopAppBar(
                    title = {
                        if (searchOpen) {
                            OutlinedTextField(
                                value = query,
                                onValueChange = { query = it },
                                placeholder = { Text("Search") },
                                singleLine = true,
                                shape = RoundedCornerShape(22.dp),
                                modifier = Modifier.fillMaxWidth()
                            )
                        } else {
                            Column {
                                Text(
                                    text = "ChatNU",
                                    fontWeight = FontWeight.Bold,
                                    maxLines = 1
                                )
                                Text(
                                    text = statusText(realtimeStatus),
                                    style = MaterialTheme.typography.labelSmall,
                                    color = statusColor(realtimeStatus)
                                )
                            }
                        }
                    },
                    navigationIcon = {
                        IconButton(onClick = onOpenSettings) {
                            TelegramAvatar(
                                title = user?.displayName ?: "ChatNU",
                                url = user?.avatarUrl,
                                size = 36
                            )
                        }
                    },
                    actions = {
                        IconButton(
                            onClick = {
                                searchOpen = !searchOpen
                                if (!searchOpen) query = ""
                            }
                        ) {
                            Icon(
                                imageVector = if (searchOpen) Icons.Default.Close else Icons.Default.Search,
                                contentDescription = if (searchOpen) "Close search" else "Search"
                            )
                        }
                        if (!searchOpen) {
                            IconButton(onClick = onOpenSettings) {
                                Icon(Icons.Default.MoreVert, contentDescription = "More")
                            }
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = MaterialTheme.colorScheme.surface,
                        scrolledContainerColor = MaterialTheme.colorScheme.surface
                    )
                )
                HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.55f))
            }
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = {
                    composerError = null
                    showComposer = true
                },
                shape = CircleShape
            ) {
                Icon(Icons.Default.Edit, contentDescription = "New chat")
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .background(MaterialTheme.colorScheme.background)
        ) {
            if (errorMessage != null) {
                Surface(
                    color = MaterialTheme.colorScheme.errorContainer,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = errorMessage,
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            modifier = Modifier.weight(1f),
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis
                        )
                        TextButton(onClick = onRefresh) { Text("Retry") }
                    }
                }
            }

            if (isRefreshing && conversations.isNotEmpty()) {
                CircularProgressIndicator(
                    modifier = Modifier
                        .align(Alignment.CenterHorizontally)
                        .padding(top = 6.dp)
                        .size(20.dp),
                    strokeWidth = 2.dp
                )
            }

            if (filtered.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Surface(
                            shape = CircleShape,
                            color = MaterialTheme.colorScheme.primaryContainer,
                            modifier = Modifier.size(72.dp)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(
                                    if (query.isBlank()) Icons.Default.Person else Icons.Default.Search,
                                    contentDescription = null,
                                    modifier = Modifier.size(32.dp),
                                    tint = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                            }
                        }
                        Spacer(Modifier.height(14.dp))
                        Text(
                            if (query.isBlank()) "No chats yet" else "No results",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                        Text(
                            if (query.isBlank()) "Tap the pencil to start a conversation." else "Try another search.",
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(bottom = 92.dp)
                ) {
                    items(filtered, key = { it.id }) { conversation ->
                        TelegramConversationRow(
                            conversation = conversation,
                            onClick = { onSelectConversation(conversation) },
                            onLongClick = { onTogglePinConversation(conversation.id) }
                        )
                    }
                }
            }
        }
    }

    if (showComposer) {
        ModalBottomSheet(onDismissRequest = { showComposer = false }) {
            Text(
                "New message",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
            )
            ListItem(
                headlineContent = { Text("New private chat") },
                supportingContent = { Text("Message a user on ${ServerEndpoint.hostLabel()}") },
                leadingContent = {
                    Surface(shape = CircleShape, color = MaterialTheme.colorScheme.primaryContainer) {
                        Icon(Icons.Default.Person, contentDescription = null, modifier = Modifier.padding(12.dp))
                    }
                },
                modifier = Modifier.combinedClickable(
                    onClick = {
                        showComposer = false
                        showDirectDialog = true
                    },
                    onLongClick = {}
                )
            )
            ListItem(
                headlineContent = { Text("New group") },
                supportingContent = { Text("Create an encrypted group on this server") },
                leadingContent = {
                    Surface(shape = CircleShape, color = MaterialTheme.colorScheme.secondaryContainer) {
                        Icon(Icons.Default.Group, contentDescription = null, modifier = Modifier.padding(12.dp))
                    }
                },
                modifier = Modifier.combinedClickable(
                    onClick = {
                        showComposer = false
                        showGroupDialog = true
                    },
                    onLongClick = {}
                )
            )
            Spacer(Modifier.height(24.dp))
        }
    }

    if (showDirectDialog) {
        AlertDialog(
            onDismissRequest = { if (!composerLoading) showDirectDialog = false },
            title = { Text("New private chat") },
            text = {
                Column {
                    OutlinedTextField(
                        value = directUsername,
                        onValueChange = {
                            directUsername = it
                            composerError = null
                        },
                        label = { Text("Username") },
                        prefix = { Text("@") },
                        supportingText = { Text("This server: ${ServerEndpoint.hostLabel()}") },
                        singleLine = true
                    )
                    composerError?.let {
                        Text(it, color = MaterialTheme.colorScheme.error, modifier = Modifier.padding(top = 8.dp))
                    }
                }
            },
            confirmButton = {
                TextButton(
                    enabled = !composerLoading && directUsername.trim().removePrefix("@").length >= 3,
                    onClick = {
                        scope.launch {
                            composerLoading = true
                            composerError = null
                            onOpenDirect(directUsername.trim().removePrefix("@"))
                                .onSuccess {
                                    directUsername = ""
                                    showDirectDialog = false
                                }
                                .onFailure { composerError = it.message ?: "Could not open this chat." }
                            composerLoading = false
                        }
                    }
                ) { Text(if (composerLoading) "Opening…" else "Open") }
            },
            dismissButton = {
                TextButton(onClick = { showDirectDialog = false }) { Text("Cancel") }
            }
        )
    }

    if (showGroupDialog) {
        AlertDialog(
            onDismissRequest = { if (!composerLoading) showGroupDialog = false },
            title = { Text("New group") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedTextField(
                        value = groupTitle,
                        onValueChange = { groupTitle = it; composerError = null },
                        label = { Text("Group name") },
                        singleLine = true
                    )
                    OutlinedTextField(
                        value = groupMembers,
                        onValueChange = { groupMembers = it; composerError = null },
                        label = { Text("Usernames") },
                        supportingText = { Text("Comma-separated usernames on this server") }
                    )
                    composerError?.let { Text(it, color = MaterialTheme.colorScheme.error) }
                }
            },
            confirmButton = {
                TextButton(
                    enabled = !composerLoading && groupTitle.trim().isNotBlank(),
                    onClick = {
                        scope.launch {
                            val usernames = groupMembers
                                .split(',')
                                .map { it.trim().removePrefix("@").lowercase() }
                                .filter { it.isNotBlank() }
                                .distinct()
                            composerLoading = true
                            composerError = null
                            onCreateGroup(groupTitle.trim(), usernames)
                                .onSuccess {
                                    groupTitle = ""
                                    groupMembers = ""
                                    showGroupDialog = false
                                }
                                .onFailure { composerError = it.message ?: "Could not create group." }
                            composerLoading = false
                        }
                    }
                ) { Text(if (composerLoading) "Creating…" else "Create") }
            },
            dismissButton = {
                TextButton(onClick = { showGroupDialog = false }) { Text("Cancel") }
            }
        )
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun TelegramConversationRow(
    conversation: Conversation,
    onClick: () -> Unit,
    onLongClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .combinedClickable(onClick = onClick, onLongClick = onLongClick)
            .padding(start = 12.dp, end = 12.dp, top = 9.dp, bottom = 9.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        TelegramAvatar(conversation.title, conversation.avatarUrl, 56)
        Spacer(Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = conversation.title,
                    style = MaterialTheme.typography.titleMedium.copy(fontSize = 16.sp),
                    fontWeight = if (conversation.unreadCount > 0) FontWeight.Bold else FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )
                if (conversation.isEncrypted) {
                    Icon(
                        Icons.Default.Lock,
                        contentDescription = "Encrypted",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(14.dp)
                    )
                }
                Spacer(Modifier.width(6.dp))
                Text(
                    text = conversation.lastMessageTime,
                    style = MaterialTheme.typography.labelSmall,
                    color = if (conversation.unreadCount > 0) MaterialTheme.colorScheme.primary
                    else MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Spacer(Modifier.height(3.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (conversation.type == ConversationType.GROUP) {
                    Icon(
                        Icons.Default.Group,
                        contentDescription = null,
                        modifier = Modifier.size(15.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(Modifier.width(4.dp))
                }
                Text(
                    text = conversation.lastMessageText.ifBlank { "No messages yet" },
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )
                if (conversation.isMuted) {
                    Icon(
                        Icons.Default.VolumeOff,
                        contentDescription = "Muted",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(16.dp)
                    )
                } else if (conversation.isPinned) {
                    Icon(
                        Icons.Default.PushPin,
                        contentDescription = "Pinned",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(16.dp)
                    )
                }
                if (conversation.unreadCount > 0) {
                    Spacer(Modifier.width(8.dp))
                    Surface(
                        shape = CircleShape,
                        color = if (conversation.isMuted) MaterialTheme.colorScheme.outline
                        else MaterialTheme.colorScheme.primary
                    ) {
                        Text(
                            text = if (conversation.unreadCount > 999) "999+" else conversation.unreadCount.toString(),
                            color = Color.White,
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(horizontal = 7.dp, vertical = 2.dp)
                        )
                    }
                }
            }
        }
    }
    HorizontalDivider(
        modifier = Modifier.padding(start = 80.dp),
        color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f)
    )
}

@Composable
private fun TelegramAvatar(title: String, url: String?, size: Int) {
    Surface(
        modifier = Modifier.size(size.dp),
        shape = CircleShape,
        color = avatarColor(title)
    ) {
        Box(contentAlignment = Alignment.Center) {
            Text(
                text = title.trim().firstOrNull()?.uppercase() ?: "?",
                color = Color.White,
                fontWeight = FontWeight.Bold,
                fontSize = (size * 0.34f).sp
            )
            if (!url.isNullOrBlank()) {
                AsyncImage(
                    model = url,
                    contentDescription = title,
                    modifier = Modifier.fillMaxSize().clip(CircleShape)
                )
            }
        }
    }
}

@Composable
private fun statusColor(status: RealtimeStatus): Color = when (status) {
    RealtimeStatus.CONNECTED -> Color(0xFF2AA84A)
    RealtimeStatus.CONNECTING -> MaterialTheme.colorScheme.tertiary
    RealtimeStatus.DISCONNECTED -> MaterialTheme.colorScheme.error
}

private fun statusText(status: RealtimeStatus): String = when (status) {
    RealtimeStatus.CONNECTED -> "${ServerEndpoint.hostLabel()} • connected"
    RealtimeStatus.CONNECTING -> "${ServerEndpoint.hostLabel()} • connecting…"
    RealtimeStatus.DISCONNECTED -> "${ServerEndpoint.hostLabel()} • offline"
}

private fun avatarColor(seed: String): Color {
    val colors = listOf(
        Color(0xFF5C7CFA),
        Color(0xFF2EAD75),
        Color(0xFF8B5CF6),
        Color(0xFFE85D75),
        Color(0xFFF2994A),
        Color(0xFF3A9ED8)
    )
    return colors[(seed.hashCode() and Int.MAX_VALUE) % colors.size]
}
