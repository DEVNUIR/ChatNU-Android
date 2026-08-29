package com.example.remote

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.DoneAll
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Logout
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PushPin
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Send
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FilledTonalIconButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LargeTopAppBar
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.BuildConfig
import com.example.model.Conversation
import com.example.model.ConversationType
import com.example.model.Message
import com.example.model.MessageStatus
import com.example.model.MessageType
import com.example.model.User
import kotlinx.coroutines.launch

private enum class AuthMode { LOGIN, REGISTER }
private enum class ComposerMode { DIRECT, GROUP }

@Composable
private fun Avatar(
    name: String,
    url: String?,
    modifier: Modifier = Modifier.size(48.dp)
) {
    Surface(
        modifier = modifier,
        shape = CircleShape,
        color = MaterialTheme.colorScheme.primaryContainer
    ) {
        Box(contentAlignment = Alignment.Center) {
            Text(
                text = name.trim().firstOrNull()?.uppercase() ?: "?",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
            if (!url.isNullOrBlank()) {
                AsyncImage(
                    model = url,
                    contentDescription = name,
                    modifier = Modifier.fillMaxSize().clip(CircleShape)
                )
            }
        }
    }
}

@Composable
fun ProductionAuthScreen(
    onLogin: suspend (String, String) -> AuthResult,
    onRegister: suspend (String, String, String) -> AuthResult,
    onAuthSuccess: () -> Unit
) {
    var mode by remember { mutableStateOf(AuthMode.LOGIN) }
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var displayName by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }
    var loading by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var recoveryCode by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val clipboard = LocalClipboardManager.current

    fun submit() {
        if (loading) return
        scope.launch {
            loading = true
            error = null
            val result = if (mode == AuthMode.REGISTER) {
                onRegister(username.trim(), password, displayName.trim())
            } else {
                onLogin(username.trim(), password)
            }
            loading = false
            if (!result.success) {
                error = result.error ?: "Could not connect to the server."
            } else if (!result.recoveryCode.isNullOrBlank()) {
                recoveryCode = result.recoveryCode
            } else {
                onAuthSuccess()
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .statusBarsPadding()
            .navigationBarsPadding()
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp, vertical = 28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Surface(
                modifier = Modifier.size(64.dp),
                shape = RoundedCornerShape(20.dp),
                color = MaterialTheme.colorScheme.primary
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text(
                        text = "NU",
                        color = MaterialTheme.colorScheme.onPrimary,
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Black
                    )
                }
            }
            Spacer(Modifier.height(18.dp))
            Text(
                text = "ChatNU",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = "Private messaging on your own server",
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            Spacer(Modifier.height(28.dp))

            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(24.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainer)
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    if (recoveryCode != null) {
                        Text("Save your recovery code", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                        Text(
                            "This is shown once. Store it somewhere you can still reach if you lose your phone.",
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Surface(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(16.dp),
                            color = MaterialTheme.colorScheme.secondaryContainer
                        ) {
                            Row(
                                modifier = Modifier.padding(16.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    recoveryCode!!,
                                    modifier = Modifier.weight(1f),
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )
                                IconButton(onClick = { clipboard.setText(AnnotatedString(recoveryCode!!)) }) {
                                    Icon(Icons.Default.ContentCopy, contentDescription = "Copy recovery code")
                                }
                            }
                        }
                        Button(onClick = onAuthSuccess, modifier = Modifier.fillMaxWidth()) {
                            Text("I saved it")
                        }
                    } else {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            FilterChip(
                                selected = mode == AuthMode.LOGIN,
                                onClick = { mode = AuthMode.LOGIN; error = null },
                                label = { Text("Sign in") },
                                modifier = Modifier.weight(1f)
                            )
                            FilterChip(
                                selected = mode == AuthMode.REGISTER,
                                onClick = { mode = AuthMode.REGISTER; error = null },
                                label = { Text("Create account") },
                                modifier = Modifier.weight(1f)
                            )
                        }

                        if (mode == AuthMode.REGISTER) {
                            OutlinedTextField(
                                value = displayName,
                                onValueChange = { displayName = it; error = null },
                                label = { Text("Display name") },
                                singleLine = true,
                                modifier = Modifier.fillMaxWidth(),
                                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next)
                            )
                        }

                        OutlinedTextField(
                            value = username,
                            onValueChange = { username = it.lowercase().replace(" ", ""); error = null },
                            label = { Text("Username") },
                            leadingIcon = { Text("@", color = MaterialTheme.colorScheme.onSurfaceVariant) },
                            supportingText = { Text("3–32 characters") },
                            singleLine = true,
                            modifier = Modifier.fillMaxWidth(),
                            keyboardOptions = KeyboardOptions(
                                keyboardType = KeyboardType.Ascii,
                                imeAction = ImeAction.Next
                            )
                        )

                        OutlinedTextField(
                            value = password,
                            onValueChange = { password = it; error = null },
                            label = { Text("Password") },
                            supportingText = { Text("At least 10 characters") },
                            singleLine = true,
                            modifier = Modifier.fillMaxWidth(),
                            visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                            trailingIcon = {
                                IconButton(onClick = { passwordVisible = !passwordVisible }) {
                                    Icon(
                                        if (passwordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                        contentDescription = if (passwordVisible) "Hide password" else "Show password"
                                    )
                                }
                            },
                            keyboardOptions = KeyboardOptions(
                                keyboardType = KeyboardType.Password,
                                imeAction = ImeAction.Done
                            ),
                            keyboardActions = KeyboardActions(onDone = { submit() })
                        )

                        error?.let {
                            Surface(
                                modifier = Modifier.fillMaxWidth(),
                                shape = RoundedCornerShape(14.dp),
                                color = MaterialTheme.colorScheme.errorContainer
                            ) {
                                Row(
                                    modifier = Modifier.padding(12.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(Icons.Default.ErrorOutline, contentDescription = null, tint = MaterialTheme.colorScheme.onErrorContainer)
                                    Spacer(Modifier.width(10.dp))
                                    Text(it, color = MaterialTheme.colorScheme.onErrorContainer)
                                }
                            }
                        }

                        val valid = username.trim().length >= 3 && password.length >= 10 &&
                            (mode == AuthMode.LOGIN || displayName.isNotBlank())
                        Button(
                            onClick = { submit() },
                            enabled = valid && !loading,
                            modifier = Modifier.fillMaxWidth().height(52.dp),
                            shape = RoundedCornerShape(16.dp)
                        ) {
                            if (loading) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(20.dp),
                                    strokeWidth = 2.dp,
                                    color = MaterialTheme.colorScheme.onPrimary
                                )
                            } else {
                                Text(if (mode == AuthMode.LOGIN) "Sign in" else "Create account", fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            }

            Spacer(Modifier.height(18.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.Lock, contentDescription = null, modifier = Modifier.size(16.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(Modifier.width(6.dp))
                Text(
                    "Credentials are sent only to the configured ChatNU server.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProductionHomeScreen(
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
    var query by remember { mutableStateOf("") }
    var showComposer by remember { mutableStateOf(false) }
    val filtered = remember(conversations, query) {
        if (query.isBlank()) conversations else conversations.filter {
            it.title.contains(query, ignoreCase = true) || it.lastMessageText.contains(query, ignoreCase = true)
        }
    }

    Scaffold(
        topBar = {
            LargeTopAppBar(
                title = {
                    Column {
                        Text("ChatNU", fontWeight = FontWeight.Bold)
                        RealtimeStatusLabel(realtimeStatus)
                    }
                },
                actions = {
                    IconButton(onClick = onRefresh, enabled = !isRefreshing) {
                        if (isRefreshing) CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                        else Icon(Icons.Default.Refresh, contentDescription = "Refresh")
                    }
                    IconButton(onClick = onOpenSettings) {
                        Icon(Icons.Default.Settings, contentDescription = "Settings")
                    }
                },
                colors = TopAppBarDefaults.largeTopAppBarColors(containerColor = MaterialTheme.colorScheme.background)
            )
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { showComposer = true },
                icon = { Icon(Icons.Default.Add, contentDescription = null) },
                text = { Text("New chat") }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            if (errorMessage != null) {
                Surface(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 6.dp),
                    shape = RoundedCornerShape(14.dp),
                    color = MaterialTheme.colorScheme.errorContainer
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.ErrorOutline, contentDescription = null, tint = MaterialTheme.colorScheme.onErrorContainer)
                        Spacer(Modifier.width(10.dp))
                        Text(errorMessage, modifier = Modifier.weight(1f), color = MaterialTheme.colorScheme.onErrorContainer)
                        TextButton(onClick = onRefresh) { Text("Retry") }
                    }
                }
            }

            OutlinedTextField(
                value = query,
                onValueChange = { query = it },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                placeholder = { Text("Search conversations") },
                singleLine = true,
                shape = RoundedCornerShape(18.dp),
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)
            )

            if (filtered.isEmpty()) {
                EmptyConversationState(
                    modifier = Modifier.weight(1f),
                    hasQuery = query.isNotBlank(),
                    userName = user?.displayName
                )
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = androidx.compose.foundation.layout.PaddingValues(bottom = 104.dp, top = 4.dp)
                ) {
                    items(filtered, key = { it.id }) { conversation ->
                        ConversationRow(
                            conversation = conversation,
                            onClick = { onSelectConversation(conversation) },
                            onTogglePin = { onTogglePinConversation(conversation.id) }
                        )
                    }
                }
            }
        }
    }

    if (showComposer) {
        NewConversationSheet(
            onDismiss = { showComposer = false },
            onOpenDirect = onOpenDirect,
            onCreateGroup = onCreateGroup
        )
    }
}

@Composable
private fun RealtimeStatusLabel(status: RealtimeStatus) {
    val (label, color) = when (status) {
        RealtimeStatus.CONNECTED -> "Realtime connected" to Color(0xFF16A34A)
        RealtimeStatus.CONNECTING -> "Connecting…" to MaterialTheme.colorScheme.tertiary
        RealtimeStatus.DISCONNECTED -> "Offline / reconnecting" to MaterialTheme.colorScheme.error
    }
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(modifier = Modifier.size(7.dp).clip(CircleShape).background(color))
        Spacer(Modifier.width(6.dp))
        Text(label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun EmptyConversationState(modifier: Modifier, hasQuery: Boolean, userName: String?) {
    Column(
        modifier = modifier.fillMaxWidth().padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Surface(shape = CircleShape, color = MaterialTheme.colorScheme.secondaryContainer, modifier = Modifier.size(72.dp)) {
            Box(contentAlignment = Alignment.Center) {
                Icon(
                    if (hasQuery) Icons.Default.Search else Icons.Default.Person,
                    contentDescription = null,
                    modifier = Modifier.size(30.dp),
                    tint = MaterialTheme.colorScheme.onSecondaryContainer
                )
            }
        }
        Spacer(Modifier.height(16.dp))
        Text(
            if (hasQuery) "No conversations found" else "No conversations yet",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )
        Spacer(Modifier.height(6.dp))
        Text(
            if (hasQuery) "Try a different search." else "${userName ?: "You"}, start a direct chat or create a group.",
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun ConversationRow(
    conversation: Conversation,
    onClick: () -> Unit,
    onTogglePin: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Avatar(conversation.title, conversation.avatarUrl, Modifier.size(52.dp))
        Spacer(Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    conversation.title,
                    modifier = Modifier.weight(1f),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    fontWeight = if (conversation.unreadCount > 0) FontWeight.Bold else FontWeight.SemiBold,
                    style = MaterialTheme.typography.titleMedium
                )
                Text(
                    conversation.lastMessageTime,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Spacer(Modifier.height(3.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (conversation.type == ConversationType.GROUP) {
                    Icon(Icons.Default.Group, contentDescription = null, modifier = Modifier.size(14.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.width(4.dp))
                }
                Text(
                    conversation.lastMessageText.ifBlank { "No messages yet" },
                    modifier = Modifier.weight(1f),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    style = MaterialTheme.typography.bodyMedium,
                    color = if (conversation.unreadCount > 0) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurfaceVariant
                )
                if (conversation.unreadCount > 0) {
                    Surface(shape = CircleShape, color = MaterialTheme.colorScheme.primary) {
                        Text(
                            if (conversation.unreadCount > 99) "99+" else conversation.unreadCount.toString(),
                            modifier = Modifier.padding(horizontal = 7.dp, vertical = 2.dp),
                            color = MaterialTheme.colorScheme.onPrimary,
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }
        IconButton(onClick = onTogglePin) {
            Icon(
                Icons.Default.PushPin,
                contentDescription = if (conversation.isPinned) "Unpin" else "Pin",
                tint = if (conversation.isPinned) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.55f),
                modifier = Modifier.size(19.dp)
            )
        }
    }
    HorizontalDivider(modifier = Modifier.padding(start = 80.dp), color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f))
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun NewConversationSheet(
    onDismiss: () -> Unit,
    onOpenDirect: suspend (String) -> Result<Unit>,
    onCreateGroup: suspend (String, List<String>) -> Result<Unit>
) {
    var mode by remember { mutableStateOf(ComposerMode.DIRECT) }
    var username by remember { mutableStateOf("") }
    var groupTitle by remember { mutableStateOf("") }
    var membersText by remember { mutableStateOf("") }
    var loading by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    ModalBottomSheet(onDismissRequest = { if (!loading) onDismiss() }) {
        Column(
            modifier = Modifier.fillMaxWidth().navigationBarsPadding().padding(horizontal = 20.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Text("Start a conversation", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilterChip(
                    selected = mode == ComposerMode.DIRECT,
                    onClick = { mode = ComposerMode.DIRECT; error = null },
                    label = { Text("Direct") },
                    modifier = Modifier.weight(1f)
                )
                FilterChip(
                    selected = mode == ComposerMode.GROUP,
                    onClick = { mode = ComposerMode.GROUP; error = null },
                    label = { Text("Group") },
                    modifier = Modifier.weight(1f)
                )
            }

            if (mode == ComposerMode.DIRECT) {
                OutlinedTextField(
                    value = username,
                    onValueChange = { username = it.trimStart().removePrefix("@"); error = null },
                    label = { Text("Username") },
                    leadingIcon = { Text("@") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            } else {
                OutlinedTextField(
                    value = groupTitle,
                    onValueChange = { groupTitle = it; error = null },
                    label = { Text("Group name") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = membersText,
                    onValueChange = { membersText = it; error = null },
                    label = { Text("Member usernames") },
                    supportingText = { Text("Separate usernames with commas") },
                    minLines = 2,
                    maxLines = 4,
                    modifier = Modifier.fillMaxWidth()
                )
            }

            error?.let { Text(it, color = MaterialTheme.colorScheme.error) }

            Button(
                onClick = {
                    scope.launch {
                        loading = true
                        error = null
                        val result = if (mode == ComposerMode.DIRECT) {
                            onOpenDirect(username.trim().removePrefix("@"))
                        } else {
                            val members = membersText.split(',', '\n', ' ')
                                .map { it.trim().removePrefix("@").lowercase() }
                                .filter { it.isNotBlank() }
                                .distinct()
                            onCreateGroup(groupTitle.trim(), members)
                        }
                        loading = false
                        result.onSuccess { onDismiss() }
                            .onFailure { error = it.message ?: "Could not create the conversation." }
                    }
                },
                enabled = !loading && if (mode == ComposerMode.DIRECT) username.trim().length >= 3 else groupTitle.isNotBlank(),
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = RoundedCornerShape(16.dp)
            ) {
                if (loading) CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp, color = MaterialTheme.colorScheme.onPrimary)
                else Text(if (mode == ComposerMode.DIRECT) "Open chat" else "Create group", fontWeight = FontWeight.Bold)
            }
            Spacer(Modifier.height(8.dp))
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProductionConversationScreen(
    conversation: Conversation,
    messages: List<Message>,
    currentUserId: String?,
    isLoading: Boolean,
    errorMessage: String?,
    onBack: () -> Unit,
    onRetry: () -> Unit,
    onSendText: (String) -> Unit
) {
    var input by remember(conversation.id) { mutableStateOf("") }
    val listState = rememberLazyListState()

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
                    IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, contentDescription = "Back") }
                },
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Avatar(conversation.title, conversation.avatarUrl, Modifier.size(40.dp))
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
                                if (conversation.type == ConversationType.GROUP) "${conversation.members.size} members" else "Direct message",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                },
                actions = {
                    IconButton(onClick = onRetry) { Icon(Icons.Default.Refresh, contentDescription = "Reload messages") }
                }
            )
        },
        bottomBar = {
            Surface(
                tonalElevation = 3.dp,
                modifier = Modifier.fillMaxWidth().imePadding().navigationBarsPadding()
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.Bottom,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
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
                isLoading && messages.isEmpty() -> {
                    CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
                }
                errorMessage != null && messages.isEmpty() -> {
                    Column(
                        modifier = Modifier.align(Alignment.Center).padding(32.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(Icons.Default.ErrorOutline, contentDescription = null, modifier = Modifier.size(36.dp), tint = MaterialTheme.colorScheme.error)
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
                        Text("Start the conversation.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                else -> {
                    LazyColumn(
                        state = listState,
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 12.dp, vertical = 12.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        items(messages, key = { it.id }) { message ->
                            MessageBubble(message = message, mine = message.senderId == currentUserId)
                        }
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
}

@Composable
private fun MessageBubble(message: Message, mine: Boolean) {
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
                .widthIn(max = 360.dp),
            shape = RoundedCornerShape(
                topStart = 20.dp,
                topEnd = 20.dp,
                bottomStart = if (mine) 20.dp else 5.dp,
                bottomEnd = if (mine) 5.dp else 20.dp
            ),
            color = if (mine) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceContainerHigh
        ) {
            Column(modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)) {
                if (!mine && message.senderName.isNotBlank()) {
                    Text(
                        message.senderName,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(Modifier.height(2.dp))
                }

                when (message.type) {
                    MessageType.VOICE -> Text("Voice message · ${message.voiceDurationSeconds}s")
                    MessageType.FILE -> Text(message.fileName ?: message.text)
                    MessageType.IMAGE, MessageType.VIEW_ONCE_IMAGE -> Text("Photo · ${message.text}")
                    MessageType.VIDEO, MessageType.VIEW_ONCE_VIDEO -> Text("Video · ${message.text}")
                    MessageType.LOCATION, MessageType.LIVE_LOCATION -> Text("Location · ${message.text}")
                    else -> Text(message.text, style = MaterialTheme.typography.bodyLarge)
                }

                Spacer(Modifier.height(3.dp))
                Row(
                    modifier = Modifier.align(Alignment.End),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        message.timestamp,
                        style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    if (mine) {
                        when (message.status) {
                            MessageStatus.SENDING, MessageStatus.QUEUED -> CircularProgressIndicator(modifier = Modifier.size(11.dp), strokeWidth = 1.5.dp)
                            MessageStatus.FAILED -> Icon(Icons.Default.ErrorOutline, contentDescription = "Failed", modifier = Modifier.size(14.dp), tint = MaterialTheme.colorScheme.error)
                            MessageStatus.SENT -> Icon(Icons.Default.Check, contentDescription = "Sent", modifier = Modifier.size(14.dp))
                            MessageStatus.DELIVERED, MessageStatus.READ -> Icon(Icons.Default.DoneAll, contentDescription = "Delivered", modifier = Modifier.size(14.dp), tint = MaterialTheme.colorScheme.primary)
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProductionSettingsScreen(
    user: User?,
    realtimeStatus: RealtimeStatus,
    onBack: () -> Unit,
    onLogout: () -> Unit
) {
    var confirmLogout by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Settings", fontWeight = FontWeight.Bold) },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, contentDescription = "Back") } }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Card(shape = RoundedCornerShape(20.dp)) {
                Row(modifier = Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Avatar(user?.displayName ?: "User", user?.avatarUrl, Modifier.size(58.dp))
                    Spacer(Modifier.width(14.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(user?.displayName ?: "Unknown user", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                        Text("@${user?.username.orEmpty()}", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }

            SettingsInfoCard(
                title = "Connection",
                body = when (realtimeStatus) {
                    RealtimeStatus.CONNECTED -> "Realtime connection is active."
                    RealtimeStatus.CONNECTING -> "Realtime is reconnecting."
                    RealtimeStatus.DISCONNECTED -> "Realtime is currently offline. REST actions may still work."
                }
            )

            SettingsInfoCard(
                title = "Server",
                body = BuildConfig.CHATNU_API_URL
            )

            SettingsInfoCard(
                title = "Security status",
                body = "Session tokens are protected by Android Keystore. The current message crypto layer is not yet audited Signal-compatible end-to-end encryption."
            )

            SettingsInfoCard(
                title = "App",
                body = "ChatNU ${BuildConfig.VERSION_NAME}"
            )

            Button(
                onClick = { confirmLogout = true },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.errorContainer,
                    contentColor = MaterialTheme.colorScheme.onErrorContainer
                ),
                shape = RoundedCornerShape(16.dp)
            ) {
                Icon(Icons.Default.Logout, contentDescription = null)
                Spacer(Modifier.width(8.dp))
                Text("Sign out", fontWeight = FontWeight.Bold)
            }
        }
    }

    if (confirmLogout) {
        AlertDialog(
            onDismissRequest = { confirmLogout = false },
            title = { Text("Sign out?") },
            text = { Text("This removes the local session from this device.") },
            confirmButton = {
                TextButton(onClick = { confirmLogout = false; onLogout() }) {
                    Text("Sign out", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = { TextButton(onClick = { confirmLogout = false }) { Text("Cancel") } }
        )
    }
}

@Composable
private fun SettingsInfoCard(title: String, body: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainer)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(title, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleSmall)
            Spacer(Modifier.height(5.dp))
            Text(body, color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodyMedium)
        }
    }
}
