package com.example.remote

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.ChatBubbleOutline
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.MarkChatRead
import androidx.compose.material.icons.filled.PeopleOutline
import androidx.compose.material.icons.filled.PersonAddAlt
import androidx.compose.material.icons.filled.PushPin
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.example.model.Conversation
import com.example.model.ConversationType
import com.example.model.User
import com.example.ui.chatnu2026.ChatNuAvatar
import com.example.ui.chatnu2026.ChatNuConversationRow
import com.example.ui.chatnu2026.ChatNuFloatingNav
import com.example.ui.chatnu2026.ChatNuFolder
import com.example.ui.chatnu2026.ChatNuFolderTabs
import com.example.ui.chatnu2026.ChatNuGlassSurface
import com.example.ui.chatnu2026.ChatNuIconSize
import com.example.ui.chatnu2026.ChatNuMotion
import com.example.ui.chatnu2026.ChatNuPrimaryDestination
import com.example.ui.chatnu2026.ChatNuRadius
import com.example.ui.chatnu2026.ChatNuSpacing
import com.example.ui.chatnu2026.LocalChatNuHazeState
import dev.chrisbanes.haze.HazeState
import dev.chrisbanes.haze.haze
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatNuHomeScreen2026(
    user: User?,
    conversations: List<Conversation>,
    realtimeStatus: RealtimeStatus,
    isRefreshing: Boolean,
    errorMessage: String?,
    drafts: Map<String, String>,
    onRefresh: () -> Unit,
    onSelectConversation: (Conversation) -> Unit,
    onTogglePinConversation: (String) -> Unit,
    onMarkReadConversation: (String) -> Unit,
    onOpenSettings: () -> Unit,
    onOpenDirect: suspend (String) -> Result<Unit>,
    onCreateGroup: suspend (String, List<String>) -> Result<Unit>,
    onSearchUsers: suspend (String) -> List<User>
) {
    var folder by remember { mutableStateOf(ChatNuFolder.ALL) }
    var destination by remember { mutableStateOf(ChatNuPrimaryDestination.CHATS) }
    var searchOpen by remember { mutableStateOf(false) }
    var searchQuery by remember { mutableStateOf("") }
    var showCreateSheet by remember { mutableStateOf(false) }
    var contextConversation by remember { mutableStateOf<Conversation?>(null) }
    val hazeState = remember { HazeState() }

    if (destination == ChatNuPrimaryDestination.SETTINGS) {
        LaunchedEffect(Unit) {
            destination = ChatNuPrimaryDestination.CHATS
            onOpenSettings()
        }
    }

    LaunchedEffect(destination) {
        if (destination != ChatNuPrimaryDestination.CHATS) {
            searchOpen = false
            searchQuery = ""
        }
    }

    val foldered = remember(conversations, folder, searchQuery, drafts) {
        conversations
            .filter { conversation ->
                when (folder) {
                    ChatNuFolder.ALL -> true
                    ChatNuFolder.UNREAD -> conversation.unreadCount > 0
                    ChatNuFolder.PERSONAL -> conversation.type == ConversationType.DIRECT
                    ChatNuFolder.GROUPS -> conversation.type == ConversationType.GROUP
                }
            }
            .filter { conversation ->
                val needle = searchQuery.trim()
                needle.isBlank() ||
                    conversation.title.contains(needle, ignoreCase = true) ||
                    conversation.lastMessageText.contains(needle, ignoreCase = true) ||
                    drafts[conversation.id].orEmpty().contains(needle, ignoreCase = true)
            }
            .sortedWith(
                compareByDescending<Conversation> { it.isPinned }
                    .thenByDescending { it.lastMessageTimestampMillis }
            )
    }
    val unread = conversations.sumOf { it.unreadCount }
    val groupUnread = conversations.filter { it.type == ConversationType.GROUP }.sumOf { it.unreadCount }

    CompositionLocalProvider(LocalChatNuHazeState provides hazeState) {
        BoxWithConstraints(modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)) {
            val expanded = maxWidth >= 720.dp
            Row(modifier = Modifier.fillMaxSize()) {
                if (expanded) {
                    ChatNuDesktopRail(
                        selected = destination,
                        onSelected = { target ->
                            if (target == ChatNuPrimaryDestination.SETTINGS) onOpenSettings()
                            else destination = target
                        },
                        modifier = Modifier
                            .fillMaxHeight()
                            .statusBarsPadding()
                            .padding(start = ChatNuSpacing.md, top = ChatNuSpacing.md, bottom = ChatNuSpacing.md)
                    )
                    Spacer(Modifier.width(ChatNuSpacing.md))
                }

                Box(modifier = Modifier.weight(1f).fillMaxHeight()) {
                    val topInset = when (destination) {
                        ChatNuPrimaryDestination.CHATS -> if (errorMessage == null) 154.dp else 208.dp
                        ChatNuPrimaryDestination.CONTACTS -> if (errorMessage == null) 88.dp else 142.dp
                        ChatNuPrimaryDestination.SETTINGS -> 88.dp
                    }

                    AnimatedContent(
                        targetState = destination,
                        modifier = Modifier.fillMaxSize().haze(hazeState),
                        transitionSpec = {
                            val forward = targetState.ordinal >= initialState.ordinal
                            (slideInHorizontally(
                                animationSpec = ChatNuMotion.responsiveSpring(),
                                initialOffsetX = { width -> if (forward) width / 8 else -width / 8 }
                            ) + fadeIn()) togetherWith
                                (slideOutHorizontally(
                                    animationSpec = ChatNuMotion.responsiveSpring(),
                                    targetOffsetX = { width -> if (forward) -width / 12 else width / 12 }
                                ) + fadeOut())
                        },
                        label = "home-destination"
                    ) { target ->
                        when (target) {
                            ChatNuPrimaryDestination.CHATS -> ChatNuConversationList(
                                conversations = foldered,
                                query = searchQuery,
                                drafts = drafts,
                                topPadding = topInset,
                                onSelectConversation = onSelectConversation,
                                onTogglePinConversation = onTogglePinConversation,
                                onMarkReadConversation = onMarkReadConversation,
                                onLongPress = { contextConversation = it },
                                modifier = Modifier.fillMaxSize()
                            )
                            ChatNuPrimaryDestination.CONTACTS -> ChatNuContactsPanel(
                                onSearchUsers = onSearchUsers,
                                onOpenDirect = onOpenDirect,
                                topPadding = topInset,
                                modifier = Modifier.fillMaxSize()
                            )
                            ChatNuPrimaryDestination.SETTINGS -> Spacer(Modifier.fillMaxSize())
                        }
                    }

                    ChatNuHomeTopBar(
                        user = user,
                        destination = destination,
                        realtimeStatus = realtimeStatus,
                        searchOpen = searchOpen,
                        searchQuery = searchQuery,
                        onSearchToggle = {
                            searchOpen = !searchOpen
                            if (!searchOpen) searchQuery = ""
                        },
                        onSearchQuery = { searchQuery = it },
                        onRefresh = onRefresh,
                        isRefreshing = isRefreshing,
                        modifier = Modifier.align(Alignment.TopCenter)
                    )

                    if (destination == ChatNuPrimaryDestination.CHATS) {
                        ChatNuFolderTabs(
                            selected = folder,
                            unreadCount = unread,
                            groupUnreadCount = groupUnread,
                            onSelect = { folder = it },
                            modifier = Modifier
                                .align(Alignment.TopCenter)
                                .statusBarsPadding()
                                .padding(start = ChatNuSpacing.md, end = ChatNuSpacing.md, top = 66.dp)
                        )
                    }

                    AnimatedVisibility(
                        visible = errorMessage != null,
                        enter = fadeIn(),
                        exit = fadeOut(),
                        modifier = Modifier
                            .align(Alignment.TopCenter)
                            .statusBarsPadding()
                            .padding(
                                start = ChatNuSpacing.md,
                                end = ChatNuSpacing.md,
                                top = if (destination == ChatNuPrimaryDestination.CHATS) 119.dp else 66.dp
                            )
                    ) {
                        ChatNuConnectionError(errorMessage.orEmpty(), onRefresh)
                    }

                    if (!expanded) {
                        ChatNuFloatingNav(
                            selected = destination,
                            onSelect = { target ->
                                if (target == ChatNuPrimaryDestination.SETTINGS) onOpenSettings()
                                else destination = target
                            },
                            modifier = Modifier
                                .align(Alignment.BottomCenter)
                                .navigationBarsPadding()
                                .padding(bottom = ChatNuSpacing.sm)
                        )
                    }

                    if (destination == ChatNuPrimaryDestination.CHATS) {
                        FilledIconButton(
                            onClick = { showCreateSheet = true },
                            modifier = Modifier
                                .align(Alignment.BottomEnd)
                                .navigationBarsPadding()
                                .padding(end = ChatNuSpacing.lg, bottom = if (expanded) ChatNuSpacing.xl else 80.dp)
                                .size(56.dp),
                            shape = CircleShape
                        ) {
                            Icon(Icons.Default.Add, contentDescription = "New conversation", modifier = Modifier.size(ChatNuIconSize.prominent))
                        }
                    }
                }
            }
        }
    }

    if (showCreateSheet) {
        ChatNuCreateConversationSheet(
            onDismiss = { showCreateSheet = false },
            onOpenDirect = onOpenDirect,
            onCreateGroup = onCreateGroup
        )
    }

    contextConversation?.let { conversation ->
        ModalBottomSheet(onDismissRequest = { contextConversation = null }) {
            Text(
                conversation.title,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(horizontal = ChatNuSpacing.xl, vertical = ChatNuSpacing.sm)
            )
            ListItem(
                headlineContent = { Text(if (conversation.isPinned) "Unpin chat" else "Pin chat") },
                supportingContent = { Text(if (conversation.isPinned) "Move this chat back into normal recency order" else "Keep this chat above unpinned conversations") },
                leadingContent = { Icon(Icons.Default.PushPin, contentDescription = null) },
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable {
                        onTogglePinConversation(conversation.id)
                        contextConversation = null
                    }
            )
            if (conversation.unreadCount > 0) {
                ListItem(
                    headlineContent = { Text("Mark as read") },
                    supportingContent = { Text("Clear ${conversation.unreadCount} unread message${if (conversation.unreadCount == 1) "" else "s"}") },
                    leadingContent = { Icon(Icons.Default.MarkChatRead, contentDescription = null) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable {
                            onMarkReadConversation(conversation.id)
                            contextConversation = null
                        }
                )
            }
            Spacer(Modifier.height(ChatNuSpacing.xl))
        }
    }
}

@Composable
private fun ChatNuHomeTopBar(
    user: User?,
    destination: ChatNuPrimaryDestination,
    realtimeStatus: RealtimeStatus,
    searchOpen: Boolean,
    searchQuery: String,
    onSearchToggle: () -> Unit,
    onSearchQuery: (String) -> Unit,
    onRefresh: () -> Unit,
    isRefreshing: Boolean,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier.statusBarsPadding().padding(horizontal = ChatNuSpacing.md, vertical = ChatNuSpacing.sm)) {
        ChatNuGlassSurface(
            shape = RoundedCornerShape(ChatNuRadius.floating),
            modifier = Modifier.fillMaxWidth(),
            elevation = 6.dp,
            contentPadding = PaddingValues(horizontal = ChatNuSpacing.sm, vertical = 6.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                ChatNuAvatar(user?.displayName ?: "ChatNU", user?.avatarUrl, size = 38.dp)
                Spacer(Modifier.width(ChatNuSpacing.sm))
                if (destination == ChatNuPrimaryDestination.CHATS) {
                    AnimatedVisibility(visible = !searchOpen, enter = fadeIn(), exit = fadeOut(), modifier = Modifier.weight(1f)) {
                        Column {
                            Text("Chats", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                            Text(
                                when (realtimeStatus) {
                                    RealtimeStatus.CONNECTED -> "Connected"
                                    RealtimeStatus.CONNECTING -> "Connecting…"
                                    RealtimeStatus.DISCONNECTED -> "Offline"
                                },
                                style = MaterialTheme.typography.labelSmall,
                                color = if (realtimeStatus == RealtimeStatus.CONNECTED) MaterialTheme.colorScheme.tertiary
                                else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                    AnimatedVisibility(visible = searchOpen, enter = fadeIn(), exit = fadeOut(), modifier = Modifier.weight(1f)) {
                        OutlinedTextField(
                            value = searchQuery,
                            onValueChange = onSearchQuery,
                            placeholder = { Text("Search chats") },
                            singleLine = true,
                            shape = RoundedCornerShape(ChatNuRadius.pill),
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                    IconButton(onClick = onSearchToggle) {
                        Icon(if (searchOpen) Icons.Default.Close else Icons.Default.Search, contentDescription = if (searchOpen) "Close search" else "Search chats")
                    }
                    if (!searchOpen) {
                        IconButton(onClick = onRefresh, enabled = !isRefreshing) {
                            if (isRefreshing) CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp)
                            else Icon(Icons.Default.Refresh, contentDescription = "Refresh chats")
                        }
                    }
                } else {
                    Column(modifier = Modifier.weight(1f)) {
                        Text("Contacts", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                        Text(
                            "Find people on this server",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ChatNuConversationList(
    conversations: List<Conversation>,
    query: String,
    drafts: Map<String, String>,
    topPadding: androidx.compose.ui.unit.Dp,
    onSelectConversation: (Conversation) -> Unit,
    onTogglePinConversation: (String) -> Unit,
    onMarkReadConversation: (String) -> Unit,
    onLongPress: (Conversation) -> Unit,
    modifier: Modifier = Modifier
) {
    if (conversations.isEmpty()) {
        Box(modifier = modifier.fillMaxSize().padding(top = topPadding), contentAlignment = Alignment.Center) {
            Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.padding(36.dp)) {
                Surface(shape = CircleShape, color = MaterialTheme.colorScheme.primaryContainer, modifier = Modifier.size(72.dp)) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(if (query.isBlank()) Icons.Default.ChatBubbleOutline else Icons.Default.Search, contentDescription = null, modifier = Modifier.size(30.dp))
                    }
                }
                Spacer(Modifier.height(ChatNuSpacing.lg))
                Text(if (query.isBlank()) "No conversations yet" else "No matching chats", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Text(
                    if (query.isBlank()) "Start a private chat or create a group." else "Try a different name or message preview.",
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(top = 6.dp)
                )
            }
        }
        return
    }

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(top = topPadding, bottom = 104.dp)
    ) {
        items(conversations, key = { it.id }) { conversation ->
            val dismissState = rememberSwipeToDismissBoxState(
                confirmValueChange = { value ->
                    when (value) {
                        SwipeToDismissBoxValue.StartToEnd -> if (conversation.unreadCount > 0) onMarkReadConversation(conversation.id)
                        SwipeToDismissBoxValue.EndToStart -> onTogglePinConversation(conversation.id)
                        SwipeToDismissBoxValue.Settled -> Unit
                    }
                    false
                }
            )
            SwipeToDismissBox(
                state = dismissState,
                backgroundContent = {
                    val towardEnd = dismissState.dismissDirection == SwipeToDismissBoxValue.StartToEnd
                    val canMarkRead = conversation.unreadCount > 0
                    Row(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(
                                when {
                                    towardEnd && canMarkRead -> MaterialTheme.colorScheme.tertiaryContainer
                                    towardEnd -> MaterialTheme.colorScheme.surfaceContainer
                                    else -> MaterialTheme.colorScheme.primaryContainer
                                }
                            )
                            .padding(horizontal = ChatNuSpacing.xl),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = if (towardEnd) Arrangement.Start else Arrangement.End
                    ) {
                        Icon(
                            if (towardEnd && canMarkRead) Icons.Default.MarkChatRead else Icons.Default.PushPin,
                            contentDescription = null,
                            tint = if (towardEnd && !canMarkRead) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.onSurface
                        )
                        Spacer(Modifier.width(6.dp))
                        Text(
                            when {
                                towardEnd && canMarkRead -> "Read"
                                towardEnd -> "Already read"
                                conversation.isPinned -> "Unpin"
                                else -> "Pin"
                            },
                            fontWeight = FontWeight.Bold,
                            color = if (towardEnd && !canMarkRead) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.onSurface
                        )
                    }
                },
                content = {
                    Surface(color = MaterialTheme.colorScheme.background) {
                        ChatNuConversationRow(
                            conversation = conversation,
                            draft = drafts[conversation.id],
                            onClick = { onSelectConversation(conversation) },
                            onLongClick = { onLongPress(conversation) }
                        )
                    }
                }
            )
        }
    }
}

@Composable
private fun ChatNuConnectionError(message: String, onRefresh: () -> Unit) {
    ChatNuGlassSurface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(ChatNuRadius.lg),
        elevation = 5.dp,
        contentPadding = PaddingValues(horizontal = ChatNuSpacing.md, vertical = 5.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                message,
                modifier = Modifier.weight(1f),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodySmall
            )
            TextButton(onClick = onRefresh) { Text("Retry") }
        }
    }
}

@Composable
private fun ChatNuDesktopRail(
    selected: ChatNuPrimaryDestination,
    onSelected: (ChatNuPrimaryDestination) -> Unit,
    modifier: Modifier = Modifier
) {
    ChatNuGlassSurface(
        modifier = modifier.width(76.dp),
        shape = RoundedCornerShape(ChatNuRadius.floating),
        elevation = 8.dp,
        contentPadding = PaddingValues(vertical = ChatNuSpacing.sm)
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(ChatNuSpacing.md)) {
            ChatNuPrimaryDestination.entries.forEach { destination ->
                IconButton(onClick = { onSelected(destination) }, modifier = Modifier.size(52.dp)) {
                    Icon(
                        when (destination) {
                            ChatNuPrimaryDestination.CHATS -> Icons.Default.ChatBubbleOutline
                            ChatNuPrimaryDestination.CONTACTS -> Icons.Default.PeopleOutline
                            ChatNuPrimaryDestination.SETTINGS -> Icons.Default.Settings
                        },
                        contentDescription = destination.label,
                        tint = if (selected == destination) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@Composable
private fun ChatNuContactsPanel(
    onSearchUsers: suspend (String) -> List<User>,
    onOpenDirect: suspend (String) -> Result<Unit>,
    topPadding: androidx.compose.ui.unit.Dp,
    modifier: Modifier = Modifier
) {
    var query by remember { mutableStateOf("") }
    var users by remember { mutableStateOf<List<User>>(emptyList()) }
    var searching by remember { mutableStateOf(false) }
    var busyUserId by remember { mutableStateOf<String?>(null) }
    var error by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    LaunchedEffect(query) {
        val clean = query.trim().removePrefix("@")
        if (clean.length < 2) {
            users = emptyList()
            searching = false
            error = null
            return@LaunchedEffect
        }
        delay(250)
        searching = true
        error = null
        runCatching { onSearchUsers(clean) }
            .onSuccess { users = it }
            .onFailure { error = it.message ?: "Could not search people." }
        searching = false
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(top = topPadding, start = ChatNuSpacing.lg, end = ChatNuSpacing.lg)
    ) {
        OutlinedTextField(
            value = query,
            onValueChange = { query = it },
            leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
            placeholder = { Text("Search by username") },
            trailingIcon = { if (searching) CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp) },
            singleLine = true,
            shape = RoundedCornerShape(ChatNuRadius.floating),
            modifier = Modifier.fillMaxWidth()
        )
        error?.let {
            Text(
                it,
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodySmall,
                modifier = Modifier.padding(horizontal = ChatNuSpacing.sm, vertical = ChatNuSpacing.sm)
            )
        }
        when {
            query.trim().removePrefix("@").length < 2 -> {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.padding(32.dp)) {
                        Surface(shape = CircleShape, color = MaterialTheme.colorScheme.primaryContainer, modifier = Modifier.size(68.dp)) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(Icons.Default.PeopleOutline, contentDescription = null, modifier = Modifier.size(29.dp))
                            }
                        }
                        Spacer(Modifier.height(ChatNuSpacing.md))
                        Text("Find someone", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                        Text(
                            "Search the people directory on this ChatNU server.",
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(top = 5.dp)
                        )
                    }
                }
            }
            !searching && users.isEmpty() && error == null -> {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("No people found", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            else -> {
                LazyColumn(contentPadding = PaddingValues(top = ChatNuSpacing.sm, bottom = 100.dp)) {
                    items(users, key = { it.id }) { person ->
                        val busy = busyUserId == person.id
                        ListItem(
                            headlineContent = { Text(person.displayName, fontWeight = FontWeight.SemiBold) },
                            supportingContent = { Text("@${person.username}") },
                            leadingContent = { ChatNuAvatar(person.displayName, person.avatarUrl) },
                            trailingContent = {
                                if (busy) {
                                    CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp)
                                } else {
                                    Icon(Icons.Default.ChatBubbleOutline, contentDescription = null)
                                }
                            },
                            modifier = Modifier.clickable(enabled = !busy) {
                                scope.launch {
                                    busyUserId = person.id
                                    error = null
                                    onOpenDirect(person.username)
                                        .onFailure { error = it.message ?: "Could not open this chat." }
                                    busyUserId = null
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ChatNuCreateConversationSheet(
    onDismiss: () -> Unit,
    onOpenDirect: suspend (String) -> Result<Unit>,
    onCreateGroup: suspend (String, List<String>) -> Result<Unit>
) {
    var mode by remember { mutableStateOf<String?>(null) }
    var username by remember { mutableStateOf("") }
    var title by remember { mutableStateOf("") }
    var members by remember { mutableStateOf("") }
    var busy by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = ChatNuSpacing.xl, vertical = ChatNuSpacing.sm),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (mode != null) {
                IconButton(onClick = { mode = null; error = null }) { Icon(Icons.Default.ArrowBack, contentDescription = "Back") }
            }
            Text(
                when (mode) {
                    "direct" -> "New private chat"
                    "group" -> "New group"
                    else -> "New conversation"
                },
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.weight(1f)
            )
        }

        when (mode) {
            null -> {
                ListItem(
                    headlineContent = { Text("Private chat", fontWeight = FontWeight.SemiBold) },
                    supportingContent = { Text("Start an end-to-end encrypted conversation") },
                    leadingContent = { Icon(Icons.Default.PersonAddAlt, contentDescription = null) },
                    trailingContent = { Icon(Icons.Default.ChatBubbleOutline, contentDescription = null) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { mode = "direct" }
                )
                ListItem(
                    headlineContent = { Text("New group", fontWeight = FontWeight.SemiBold) },
                    supportingContent = { Text("Create an encrypted group with server users") },
                    leadingContent = { Icon(Icons.Default.Group, contentDescription = null) },
                    trailingContent = { Icon(Icons.Default.PeopleOutline, contentDescription = null) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { mode = "group" }
                )
            }
            "direct" -> {
                OutlinedTextField(
                    value = username,
                    onValueChange = { username = it; error = null },
                    label = { Text("Username") },
                    prefix = { Text("@") },
                    singleLine = true,
                    shape = RoundedCornerShape(ChatNuRadius.lg),
                    modifier = Modifier.fillMaxWidth().padding(horizontal = ChatNuSpacing.xl)
                )
                error?.let { Text(it, color = MaterialTheme.colorScheme.error, modifier = Modifier.padding(horizontal = ChatNuSpacing.xl, vertical = ChatNuSpacing.sm)) }
                TextButton(
                    enabled = !busy && username.trim().removePrefix("@").length >= 3,
                    onClick = {
                        scope.launch {
                            busy = true
                            onOpenDirect(username.trim().removePrefix("@"))
                                .onSuccess { onDismiss() }
                                .onFailure { error = it.message ?: "Could not open this chat." }
                            busy = false
                        }
                    },
                    modifier = Modifier.padding(ChatNuSpacing.xl)
                ) { Text(if (busy) "Opening…" else "Open chat") }
            }
            "group" -> {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it; error = null },
                    label = { Text("Group name") },
                    singleLine = true,
                    shape = RoundedCornerShape(ChatNuRadius.lg),
                    modifier = Modifier.fillMaxWidth().padding(horizontal = ChatNuSpacing.xl)
                )
                Spacer(Modifier.height(ChatNuSpacing.md))
                OutlinedTextField(
                    value = members,
                    onValueChange = { members = it; error = null },
                    label = { Text("Usernames") },
                    supportingText = { Text("Comma-separated usernames") },
                    shape = RoundedCornerShape(ChatNuRadius.lg),
                    modifier = Modifier.fillMaxWidth().padding(horizontal = ChatNuSpacing.xl)
                )
                error?.let { Text(it, color = MaterialTheme.colorScheme.error, modifier = Modifier.padding(horizontal = ChatNuSpacing.xl, vertical = ChatNuSpacing.sm)) }
                TextButton(
                    enabled = !busy && title.trim().isNotBlank(),
                    onClick = {
                        scope.launch {
                            val usernames = members.split(',').map { it.trim().removePrefix("@").lowercase() }.filter { it.isNotBlank() }.distinct()
                            busy = true
                            onCreateGroup(title.trim(), usernames)
                                .onSuccess { onDismiss() }
                                .onFailure { error = it.message ?: "Could not create group." }
                            busy = false
                        }
                    },
                    modifier = Modifier.padding(ChatNuSpacing.xl)
                ) { Text(if (busy) "Creating…" else "Create group") }
            }
        }
        Spacer(Modifier.height(ChatNuSpacing.xxl))
    }
}
