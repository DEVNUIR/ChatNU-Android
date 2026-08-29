package com.example.ui.screens

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.expandHorizontally
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkHorizontally
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.data.AccountManager
import com.example.model.Conversation
import com.example.model.ConversationType
import com.example.ui.components.MultiAccountRelaySheet
import com.example.ui.components.ProfileEditorDialog
import com.example.ui.theme.*
import kotlinx.coroutines.launch

data class ChatFolder(
    val id: String,
    val name: String,
    val icon: ImageVector,
    val isCustom: Boolean = false
)

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun HomeScreen(
    conversations: List<Conversation>,
    onSelectConversation: (Conversation) -> Unit,
    onCreateGroup: (title: String, description: String) -> Unit = { _, _ -> },
    onTogglePinConversation: (String) -> Unit = {},
    onOpenSettings: () -> Unit,
    onSimulateCall: () -> Unit
) {
    val isDark = isAppInDarkTheme()
    var searchQuery by remember { mutableStateOf("") }
    var isSearchActive by remember { mutableStateOf(false) }

    // Custom Folders State
    var folders by remember {
        mutableStateOf(
            listOf(
                ChatFolder("all", "All Chats", Icons.Default.ChatBubble),
                ChatFolder("personal", "Personal", Icons.Default.Person),
                ChatFolder("work", "Work", Icons.Default.Work),
                ChatFolder("secret", "Secret E2EE", Icons.Default.Key)
            )
        )
    }

    var selectedFolderId by remember { mutableStateOf("all") }
    var isFabExpanded by remember { mutableStateOf(false) }
    var showAddFriendDialog by remember { mutableStateOf(false) }
    var showCreateGroupDialog by remember { mutableStateOf(false) }
    var showAddFolderDialog by remember { mutableStateOf(false) }
    var showNewChatDialog by remember { mutableStateOf(false) }
    var showManageFolderDialog by remember { mutableStateOf<ChatFolder?>(null) }
    var conversationForFolderAssign by remember { mutableStateOf<Conversation?>(null) }
    var conversationForLongClickAction by remember { mutableStateOf<Conversation?>(null) }
    var showMultiAccountSheet by remember { mutableStateOf(false) }
    var showProfileEditorDialog by remember { mutableStateOf(false) }

    var isAccountsExpanded by remember { mutableStateOf(false) }
    var isProfileSettingsExpanded by remember { mutableStateOf(false) }
    var isGroupSettingsExpanded by remember { mutableStateOf(false) }

    val activeAccount = AccountManager.activeAccount
    val accounts by AccountManager.accounts.collectAsState()
    val drawerState = rememberDrawerState(initialValue = DrawerValue.Closed)
    val coroutineScope = rememberCoroutineScope()

    // Map conversationId -> folderIds
    var conversationFolders by remember {
        mutableStateOf(
            mutableMapOf(
                "conv_ali" to mutableSetOf("personal", "all"),
                "conv_sara" to mutableSetOf("work", "all"),
                "conv_group" to mutableSetOf("work", "secret", "all")
            )
        )
    }

    // Filter conversations based on selected folder and search query, and sort pinned chats to top
    val filteredConversations = remember(conversations, selectedFolderId, searchQuery, conversationFolders) {
        conversations.filter { conv ->
            val matchesFolder = when (selectedFolderId) {
                "all" -> true
                else -> conversationFolders[conv.id]?.contains(selectedFolderId) == true
            }
            val matchesSearch = searchQuery.isEmpty() || conv.title.contains(searchQuery, ignoreCase = true)
            matchesFolder && matchesSearch
        }.sortedWith(compareByDescending<Conversation> { it.isPinned }.thenByDescending { it.lastMessageTime })
    }

    ModalNavigationDrawer(
        drawerState = drawerState,
        drawerContent = {
            ModalDrawerSheet(
                drawerContainerColor = if (isDark) Color(0xF20F172A) else Color(0xF7FFFFFF),
                drawerTonalElevation = 8.dp,
                modifier = Modifier.width(320.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(18.dp),
                    verticalArrangement = Arrangement.SpaceBetween
                ) {
                    Column(
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        // 1. Collapsible Accounts Header (Telegram Style)
                        val accountsArrowRotation by animateFloatAsState(
                            targetValue = if (isAccountsExpanded) 180f else 0f,
                            label = "accountsArrow"
                        )

                        Surface(
                            shape = RoundedCornerShape(20.dp),
                            color = MaterialTheme.colorScheme.primary.copy(alpha = 0.12f),
                            border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.3f)),
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { isAccountsExpanded = !isAccountsExpanded }
                        ) {
                            Column(
                                modifier = Modifier
                                    .padding(14.dp)
                                    .animateContentSize()
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Box {
                                        Surface(
                                            shape = CircleShape,
                                            modifier = Modifier.size(50.dp)
                                        ) {
                                            AsyncImage(
                                                model = activeAccount.avatarUrl,
                                                contentDescription = activeAccount.displayName,
                                                modifier = Modifier.fillMaxSize()
                                            )
                                        }
                                        Box(
                                            modifier = Modifier
                                                .size(12.dp)
                                                .clip(CircleShape)
                                                .background(ChatNuEncryptedGreen)
                                                .align(Alignment.BottomEnd)
                                        )
                                    }

                                    Spacer(modifier = Modifier.width(12.dp))

                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(
                                            text = activeAccount.displayName,
                                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                            maxLines = 1
                                        )
                                        Text(
                                            text = "@${activeAccount.username}",
                                            style = MaterialTheme.typography.labelSmall,
                                            color = MaterialTheme.colorScheme.primary
                                        )
                                    }

                                    Icon(
                                        imageVector = Icons.Default.KeyboardArrowDown,
                                        contentDescription = "Expand accounts list",
                                        tint = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.rotate(accountsArrowRotation)
                                    )
                                }

                                // Collapsible Accounts List
                                AnimatedVisibility(
                                    visible = isAccountsExpanded,
                                    enter = expandVertically() + fadeIn(),
                                    exit = shrinkVertically() + fadeOut()
                                ) {
                                    Column(
                                        modifier = Modifier.padding(top = 12.dp),
                                        verticalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        Divider(color = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f))
                                        Text(
                                            text = "Active Accounts (${accounts.size}/10)",
                                            style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                                            color = MaterialTheme.colorScheme.primary
                                        )
                                        accounts.forEach { acc ->
                                            val isSelected = acc.id == activeAccount.id
                                            Surface(
                                                shape = RoundedCornerShape(12.dp),
                                                color = if (isSelected) MaterialTheme.colorScheme.primary.copy(alpha = 0.2f) else (if (isDark) Color(0x1AFFFFFF) else Color(0x0A000000)),
                                                border = BorderStroke(
                                                    1.dp,
                                                    if (isSelected) MaterialTheme.colorScheme.primary else Color.Transparent
                                                ),
                                                modifier = Modifier
                                                    .fillMaxWidth()
                                                    .clickable {
                                                        AccountManager.switchAccount(acc.id)
                                                    }
                                            ) {
                                                Row(
                                                    modifier = Modifier.padding(8.dp),
                                                    verticalAlignment = Alignment.CenterVertically
                                                ) {
                                                    Surface(
                                                        shape = CircleShape,
                                                        modifier = Modifier.size(32.dp)
                                                    ) {
                                                        AsyncImage(
                                                            model = acc.avatarUrl,
                                                            contentDescription = acc.displayName,
                                                            modifier = Modifier.fillMaxSize()
                                                        )
                                                    }
                                                    Spacer(modifier = Modifier.width(10.dp))
                                                    Column(modifier = Modifier.weight(1f)) {
                                                        Text(
                                                            text = acc.displayName,
                                                            style = MaterialTheme.typography.bodySmall.copy(fontWeight = FontWeight.Bold),
                                                            maxLines = 1
                                                        )
                                                        Text(
                                                            text = "@${acc.username}",
                                                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 9.sp),
                                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                                        )
                                                    }
                                                    if (isSelected) {
                                                        Icon(
                                                            imageVector = Icons.Default.Check,
                                                            contentDescription = "Active",
                                                            tint = MaterialTheme.colorScheme.primary,
                                                            modifier = Modifier.size(16.dp)
                                                        )
                                                    }
                                                }
                                            }
                                        }

                                        TextButton(
                                            onClick = { showMultiAccountSheet = true },
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(18.dp))
                                            Spacer(modifier = Modifier.width(6.dp))
                                            Text("Add Account (Up to 10)", style = MaterialTheme.typography.labelMedium)
                                        }
                                    }
                                }
                            }
                        }

                        Divider(modifier = Modifier.padding(vertical = 4.dp))

                        // 2. Collapsible Profile & Account Settings
                        val profileArrowRotation by animateFloatAsState(
                            targetValue = if (isProfileSettingsExpanded) 180f else 0f,
                            label = "profileArrow"
                        )
                        Column(modifier = Modifier.animateContentSize()) {
                            NavigationDrawerItem(
                                icon = { Icon(Icons.Default.Person, contentDescription = null) },
                                label = { Text("Profile & Security") },
                                badge = {
                                    Icon(
                                        imageVector = Icons.Default.KeyboardArrowDown,
                                        contentDescription = null,
                                        modifier = Modifier.rotate(profileArrowRotation)
                                    )
                                },
                                selected = false,
                                onClick = { isProfileSettingsExpanded = !isProfileSettingsExpanded }
                            )
                            AnimatedVisibility(
                                visible = isProfileSettingsExpanded,
                                enter = expandVertically() + fadeIn(),
                                exit = shrinkVertically() + fadeOut()
                            ) {
                                Column(
                                    modifier = Modifier.padding(start = 24.dp, top = 2.dp, bottom = 4.dp),
                                    verticalArrangement = Arrangement.spacedBy(2.dp)
                                ) {
                                    TextButton(
                                        onClick = {
                                            coroutineScope.launch { drawerState.close() }
                                            showProfileEditorDialog = true
                                        },
                                        modifier = Modifier.fillMaxWidth()
                                    ) {
                                        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Icon(Icons.Default.Edit, contentDescription = null, modifier = Modifier.size(16.dp))
                                            Spacer(modifier = Modifier.width(8.dp))
                                            Text("Edit Profile Info", style = MaterialTheme.typography.bodySmall)
                                        }
                                    }
                                    TextButton(
                                        onClick = {
                                            coroutineScope.launch { drawerState.close() }
                                            onOpenSettings()
                                        },
                                        modifier = Modifier.fillMaxWidth()
                                    ) {
                                        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Icon(Icons.Default.Key, contentDescription = null, modifier = Modifier.size(16.dp))
                                            Spacer(modifier = Modifier.width(8.dp))
                                            Text("E2EE Encryption Keys Vault", style = MaterialTheme.typography.bodySmall)
                                        }
                                    }
                                }
                            }
                        }

                        // 3. Collapsible Group & Community Settings
                        val groupArrowRotation by animateFloatAsState(
                            targetValue = if (isGroupSettingsExpanded) 180f else 0f,
                            label = "groupArrow"
                        )
                        Column(modifier = Modifier.animateContentSize()) {
                            NavigationDrawerItem(
                                icon = { Icon(Icons.Default.Group, contentDescription = null) },
                                label = { Text("Groups & Communities") },
                                badge = {
                                    Icon(
                                        imageVector = Icons.Default.KeyboardArrowDown,
                                        contentDescription = null,
                                        modifier = Modifier.rotate(groupArrowRotation)
                                    )
                                },
                                selected = false,
                                onClick = { isGroupSettingsExpanded = !isGroupSettingsExpanded }
                            )
                            AnimatedVisibility(
                                visible = isGroupSettingsExpanded,
                                enter = expandVertically() + fadeIn(),
                                exit = shrinkVertically() + fadeOut()
                            ) {
                                Column(
                                    modifier = Modifier.padding(start = 24.dp, top = 2.dp, bottom = 4.dp),
                                    verticalArrangement = Arrangement.spacedBy(2.dp)
                                ) {
                                    TextButton(
                                        onClick = {
                                            coroutineScope.launch { drawerState.close() }
                                            showCreateGroupDialog = true
                                        },
                                        modifier = Modifier.fillMaxWidth()
                                    ) {
                                        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Icon(Icons.Default.GroupAdd, contentDescription = null, modifier = Modifier.size(16.dp))
                                            Spacer(modifier = Modifier.width(8.dp))
                                            Text("Create New Group", style = MaterialTheme.typography.bodySmall)
                                        }
                                    }
                                }
                            }
                        }

                        // 4. Primary Drawer Navigation Shortcuts
                        NavigationDrawerItem(
                            icon = { Icon(Icons.Default.Settings, contentDescription = null) },
                            label = { Text("Settings & Vault") },
                            selected = false,
                            onClick = {
                                coroutineScope.launch { drawerState.close() }
                                onOpenSettings()
                            }
                        )

                        NavigationDrawerItem(
                            icon = { Icon(if (isDark) Icons.Default.LightMode else Icons.Default.DarkMode, contentDescription = null) },
                            label = { Text(if (isDark) "Switch to Light Mode" else "Switch to Dark Mode") },
                            selected = false,
                            onClick = {
                                ThemeManager.themeMode = if (isDark) ThemeMode.LIGHT else ThemeMode.DARK
                            }
                        )

                        NavigationDrawerItem(
                            icon = { Icon(Icons.Default.PhoneCallback, contentDescription = null) },
                            label = { Text("Simulate Incoming Call") },
                            selected = false,
                            onClick = {
                                coroutineScope.launch { drawerState.close() }
                                onSimulateCall()
                            }
                        )
                    }

                    // Footer Relay Node Status
                    Surface(
                        shape = RoundedCornerShape(12.dp),
                        color = ChatNuEncryptedGreen.copy(alpha = 0.12f),
                        border = BorderStroke(0.5.dp, ChatNuEncryptedGreen.copy(alpha = 0.3f)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier.padding(10.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(Icons.Default.Shield, contentDescription = null, tint = ChatNuEncryptedGreen, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Decentralized Relay Active • E2EE",
                                style = MaterialTheme.typography.labelSmall.copy(color = ChatNuEncryptedGreen, fontWeight = FontWeight.Bold)
                            )
                        }
                    }
                }
            }
        }
    ) {
    Scaffold(
        topBar = {
            TopAppBar(
                navigationIcon = {
                    if (isSearchActive) {
                        IconButton(onClick = {
                            isSearchActive = false
                            searchQuery = ""
                        }) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Close Search")
                        }
                    } else {
                        IconButton(onClick = { coroutineScope.launch { drawerState.open() } }) {
                            Icon(Icons.Default.Menu, contentDescription = "Account Sidebar Drawer")
                        }
                    }
                },
                title = {
                    AnimatedContent(
                        targetState = isSearchActive,
                        label = "topBarTitleAnim"
                    ) { active ->
                        if (active) {
                            OutlinedTextField(
                                value = searchQuery,
                                onValueChange = { searchQuery = it },
                                placeholder = { Text("Search chats, @username, or ID...", style = MaterialTheme.typography.bodyMedium) },
                                singleLine = true,
                                colors = OutlinedTextFieldDefaults.colors(
                                    focusedBorderColor = Color.Transparent,
                                    unfocusedBorderColor = Color.Transparent,
                                    focusedContainerColor = Color.Transparent,
                                    unfocusedContainerColor = Color.Transparent
                                ),
                                modifier = Modifier.fillMaxWidth()
                            )
                        } else {
                            Column {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text(
                                        text = "Welcome, ${activeAccount.displayName} 👋",
                                        style = MaterialTheme.typography.titleMedium.copy(
                                            fontWeight = FontWeight.Bold,
                                            letterSpacing = (-0.3).sp
                                        ),
                                        maxLines = 1
                                    )
                                }
                                Text(
                                    text = "@${activeAccount.username} • ID: #${activeAccount.id}",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.primary
                                )
                            }
                        }
                    }
                },
                actions = {
                    if (isSearchActive) {
                        if (searchQuery.isNotEmpty()) {
                            IconButton(onClick = { searchQuery = "" }) {
                                Icon(Icons.Default.Close, contentDescription = "Clear search")
                            }
                        }
                    } else {
                        // Light / Dark Theme Mode Quick Switcher
                        IconButton(onClick = {
                            ThemeManager.themeMode = when (ThemeManager.themeMode) {
                                ThemeMode.DARK -> ThemeMode.LIGHT
                                ThemeMode.LIGHT -> ThemeMode.DARK
                                ThemeMode.SYSTEM -> if (isDark) ThemeMode.LIGHT else ThemeMode.DARK
                            }
                        }) {
                            Icon(
                                imageVector = if (isDark) Icons.Default.LightMode else Icons.Default.DarkMode,
                                contentDescription = "Toggle Light/Dark Mode",
                                tint = MaterialTheme.colorScheme.primary
                            )
                        }

                        IconButton(onClick = onSimulateCall) {
                            Icon(
                                imageVector = Icons.Default.PhoneCallback,
                                contentDescription = "Simulate Incoming Call",
                                tint = MaterialTheme.colorScheme.primary
                            )
                        }

                        // Search Icon
                        IconButton(onClick = { isSearchActive = true }) {
                            Icon(
                                imageVector = Icons.Default.Search,
                                contentDescription = "Search",
                                tint = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                }
            )
        },
        floatingActionButton = {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                AnimatedVisibility(
                    visible = isFabExpanded,
                    enter = fadeIn() + expandHorizontally(),
                    exit = fadeOut() + shrinkHorizontally()
                ) {
                    Surface(
                        shape = CircleShape,
                        color = if (isDark) Color(0xF21E293B) else Color(0xFAFFFFFF),
                        border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.4f)),
                        shadowElevation = 8.dp
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            // Add Friend Option ("افزودن فرند هم باشه براش")
                            // New Group Option ("بشه گروه زد")
                            Surface(
                                shape = CircleShape,
                                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.15f),
                                modifier = Modifier
                                    .size(42.dp)
                                    .clickable {
                                        isFabExpanded = false
                                        showCreateGroupDialog = true
                                    }
                            ) {
                                Box(contentAlignment = Alignment.Center) {
                                    Icon(
                                        imageVector = Icons.Default.GroupAdd,
                                        contentDescription = "New Group",
                                        tint = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                            }

                            // Add Friend Option
                            Surface(
                                shape = CircleShape,
                                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.15f),
                                modifier = Modifier
                                    .size(42.dp)
                                    .clickable {
                                        isFabExpanded = false
                                        showAddFriendDialog = true
                                    }
                            ) {
                                Box(contentAlignment = Alignment.Center) {
                                    Icon(
                                        imageVector = Icons.Default.PersonAdd,
                                        contentDescription = "Add Friend",
                                        tint = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                            }

                            // New Direct Chat Option
                            Surface(
                                shape = CircleShape,
                                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.15f),
                                modifier = Modifier
                                    .size(42.dp)
                                    .clickable {
                                        isFabExpanded = false
                                        showNewChatDialog = true
                                    }
                            ) {
                                Box(contentAlignment = Alignment.Center) {
                                    Icon(
                                        imageVector = Icons.Default.Chat,
                                        contentDescription = "New Chat",
                                        tint = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                            }

                            // Custom Folder Option
                            Surface(
                                shape = CircleShape,
                                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.15f),
                                modifier = Modifier
                                    .size(42.dp)
                                    .clickable {
                                        isFabExpanded = false
                                        showAddFolderDialog = true
                                    }
                            ) {
                                Box(contentAlignment = Alignment.Center) {
                                    Icon(
                                        imageVector = Icons.Default.CreateNewFolder,
                                        contentDescription = "New Folder",
                                        tint = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                            }
                        }
                    }
                }

                // Main FAB Button
                FloatingActionButton(
                    onClick = { isFabExpanded = !isFabExpanded },
                    containerColor = MaterialTheme.colorScheme.primary,
                    contentColor = Color.White,
                    shape = CircleShape
                ) {
                    Icon(
                        imageVector = if (isFabExpanded) Icons.Default.Close else Icons.Default.Add,
                        contentDescription = "Expand Actions",
                        modifier = Modifier.size(26.dp)
                    )
                }
            }
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .padding(innerPadding)
                .fillMaxSize()
        ) {
            // Customizable Folder Tabs Row ("فولدر ها قابل کاستومایز باشه")
            LazyRow(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                contentPadding = PaddingValues(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                items(folders) { folder ->
                    val isSelected = selectedFolderId == folder.id
                    val chipBg = if (isSelected) MaterialTheme.colorScheme.primary else (if (isDark) Color(0x1FFFFFFF) else Color(0x0F000000))
                    val chipText = if (isSelected) Color.White else MaterialTheme.colorScheme.onSurface

                    Surface(
                        shape = RoundedCornerShape(14.dp),
                        color = chipBg,
                        border = BorderStroke(
                            1.dp,
                            if (isSelected) MaterialTheme.colorScheme.primary else (if (isDark) Color(0x26FFFFFF) else Color(0x1A000000))
                        ),
                        modifier = Modifier.clickable {
                            selectedFolderId = folder.id
                        }
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = folder.icon,
                                contentDescription = folder.name,
                                tint = chipText,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = folder.name,
                                style = MaterialTheme.typography.labelMedium.copy(
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                    color = chipText
                                )
                            )

                            if (folder.isCustom) {
                                Spacer(modifier = Modifier.width(4.dp))
                                Icon(
                                    imageVector = Icons.Default.MoreVert,
                                    contentDescription = "Manage Folder",
                                    tint = chipText.copy(alpha = 0.7f),
                                    modifier = Modifier
                                        .size(16.dp)
                                        .clickable { showManageFolderDialog = folder }
                                )
                            }
                        }
                    }
                }

                // Plus button to quickly add new custom folder
                item {
                    Surface(
                        shape = CircleShape,
                        color = MaterialTheme.colorScheme.primary.copy(alpha = 0.15f),
                        border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.3f)),
                        modifier = Modifier
                            .size(36.dp)
                            .clickable { showAddFolderDialog = true }
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(
                                imageVector = Icons.Default.Add,
                                contentDescription = "Add Custom Folder",
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(20.dp)
                            )
                        }
                    }
                }
            }

            // Conversations List
            if (filteredConversations.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Default.FolderOpen,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.size(48.dp)
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = "No chats in this folder",
                            style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.SemiBold)
                        )
                        Text(
                            text = "Tap + to add chats to custom folders",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(vertical = 4.dp)
                ) {
                    items(filteredConversations) { conv ->
                        ConversationItemRow(
                            conversation = conv,
                            onClick = { onSelectConversation(conv) },
                            onLongClick = { conversationForLongClickAction = conv }
                        )
                    }
                }
            }
        }
    }

    // Add Custom Folder Dialog
    if (showAddFolderDialog) {
        var newFolderName by remember { mutableStateOf("") }
        var selectedIconIndex by remember { mutableIntStateOf(0) }
        val iconOptions = listOf(
            Icons.Default.Folder,
            Icons.Default.Star,
            Icons.Default.Work,
            Icons.Default.Key,
            Icons.Default.Person,
            Icons.Default.Bookmark,
            Icons.Default.Group,
            Icons.Default.Label
        )

        AlertDialog(
            onDismissRequest = { showAddFolderDialog = false },
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.CreateNewFolder, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Create Custom Folder", fontWeight = FontWeight.Bold)
                }
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("Organize chats by topic, work, family or custom labels:")
                    OutlinedTextField(
                        value = newFolderName,
                        onValueChange = { newFolderName = it },
                        placeholder = { Text("e.g. Crypto, VIP, Family") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp)
                    )

                    Text("Select Folder Icon:", style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold))
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        items(iconOptions.size) { index ->
                            val icon = iconOptions[index]
                            val isSelected = selectedIconIndex == index
                            Surface(
                                shape = CircleShape,
                                color = if (isSelected) MaterialTheme.colorScheme.primary else (if (isDark) Color(0x1FFFFFFF) else Color(0x0F000000)),
                                border = BorderStroke(1.dp, if (isSelected) MaterialTheme.colorScheme.primary else Color.Transparent),
                                modifier = Modifier
                                    .size(40.dp)
                                    .clickable { selectedIconIndex = index }
                            ) {
                                Box(contentAlignment = Alignment.Center) {
                                    Icon(
                                        imageVector = icon,
                                        contentDescription = null,
                                        tint = if (isSelected) Color.White else MaterialTheme.colorScheme.onSurface,
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (newFolderName.isNotBlank()) {
                            val id = "custom_${System.currentTimeMillis()}"
                            val chosenIcon = iconOptions.getOrElse(selectedIconIndex) { Icons.Default.Folder }
                            folders = folders + ChatFolder(id, newFolderName.trim(), chosenIcon, isCustom = true)
                            selectedFolderId = id
                            showAddFolderDialog = false
                        }
                    },
                    enabled = newFolderName.isNotBlank()
                ) {
                    Text("Create Folder")
                }
            },
            dismissButton = {
                TextButton(onClick = { showAddFolderDialog = false }) { Text("Cancel") }
            }
        )
    }

    // Add Encrypted Friend Dialog ("افزودن فرند هم باشه براش")
    if (showAddFriendDialog) {
        var friendHandle by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = { showAddFriendDialog = false },
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.PersonAdd,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Add Friend (E2EE)", fontWeight = FontWeight.Bold)
                }
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("Enter devnu.ir username, email, or Signal Identity Fingerprint:")
                    OutlinedTextField(
                        value = friendHandle,
                        onValueChange = { friendHandle = it },
                        placeholder = { Text("e.g. @parsa or 0x8F2D...") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp)
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (friendHandle.isNotBlank()) {
                            showAddFriendDialog = false
                            onSelectConversation(conversations.first())
                        }
                    },
                    enabled = friendHandle.isNotBlank()
                ) {
                    Text("Send Friend Request")
                }
            },
            dismissButton = {
                TextButton(onClick = { showAddFriendDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Create Group Dialog ("بشه گروه زد")
    if (showCreateGroupDialog) {
        var groupTitle by remember { mutableStateOf("") }
        var groupDesc by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = { showCreateGroupDialog = false },
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.GroupAdd,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Create Encrypted Group", fontWeight = FontWeight.Bold)
                }
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("Enter group title and description for decentralized members:")
                    OutlinedTextField(
                        value = groupTitle,
                        onValueChange = { groupTitle = it },
                        placeholder = { Text("Group Name (e.g. DevNU Core)") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp)
                    )
                    OutlinedTextField(
                        value = groupDesc,
                        onValueChange = { groupDesc = it },
                        placeholder = { Text("Description (Optional)") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp)
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (groupTitle.isNotBlank()) {
                            onCreateGroup(groupTitle.trim(), groupDesc.trim())
                            showCreateGroupDialog = false
                        }
                    },
                    enabled = groupTitle.isNotBlank()
                ) {
                    Text("Create Group")
                }
            },
            dismissButton = {
                TextButton(onClick = { showCreateGroupDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Profile Editor Dialog Modal
    if (showProfileEditorDialog) {
        ProfileEditorDialog(
            onDismiss = { showProfileEditorDialog = false }
        )
    }

    // Manage Custom Folder Dialog (Delete / Rename)
    showManageFolderDialog?.let { folder ->
        var editedFolderName by remember(folder) { mutableStateOf(folder.name) }
        AlertDialog(
            onDismissRequest = { showManageFolderDialog = null },
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Edit, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Manage Custom Folder", fontWeight = FontWeight.Bold)
                }
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("Rename folder:")
                    OutlinedTextField(
                        value = editedFolderName,
                        onValueChange = { editedFolderName = it },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp)
                    )
                }
            },
            confirmButton = {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    TextButton(
                        onClick = {
                            folders = folders.filterNot { it.id == folder.id }
                            if (selectedFolderId == folder.id) selectedFolderId = "all"
                            showManageFolderDialog = null
                        },
                        colors = ButtonDefaults.textButtonColors(contentColor = ChatNuDestructiveRed)
                    ) {
                        Text("Delete")
                    }
                    Button(
                        onClick = {
                            if (editedFolderName.isNotBlank()) {
                                folders = folders.map {
                                    if (it.id == folder.id) it.copy(name = editedFolderName.trim()) else it
                                }
                                showManageFolderDialog = null
                            }
                        }
                    ) {
                        Text("Save")
                    }
                }
            },
            dismissButton = {
                TextButton(onClick = { showManageFolderDialog = null }) { Text("Cancel") }
            }
        )
    }

    // Long Press Chat Thread Action Dialog (Pin / Folders / Mute)
    conversationForLongClickAction?.let { conv ->
        AlertDialog(
            onDismissRequest = { conversationForLongClickAction = null },
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = if (conv.isPinned) Icons.Default.PushPin else Icons.Default.Folder,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(conv.title, fontWeight = FontWeight.Bold, maxLines = 1)
                }
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    // Option 1: Pin / Unpin
                    Surface(
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                onTogglePinConversation(conv.id)
                                conversationForLongClickAction = null
                            }
                    ) {
                        Row(
                            modifier = Modifier.padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Default.PushPin,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(
                                text = if (conv.isPinned) "Unpin from Top" else "Pin Chat to Top",
                                style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.SemiBold)
                            )
                        }
                    }

                    // Option 2: Organize into Custom Folders
                    Surface(
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                conversationForFolderAssign = conv
                                conversationForLongClickAction = null
                            }
                    ) {
                        Row(
                            modifier = Modifier.padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Default.CreateNewFolder,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(
                                text = "Organize into Custom Folders",
                                style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.SemiBold)
                            )
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { conversationForLongClickAction = null }) {
                    Text("Close")
                }
            }
        )
    }

    // Multi-Account & Decentralized Relay Sheet Modal
    if (showMultiAccountSheet) {
        MultiAccountRelaySheet(
            onDismiss = { showMultiAccountSheet = false },
            onAccountSwitched = { newAcc ->
                showMultiAccountSheet = false
            }
        )
    }

    // Assign Folder to Conversation Dialog
    conversationForFolderAssign?.let { conv ->
        val currentAssigned = conversationFolders[conv.id] ?: mutableSetOf("all")
        AlertDialog(
            onDismissRequest = { conversationForFolderAssign = null },
            title = { Text("Assign Folders for ${conv.title}", fontWeight = FontWeight.Bold) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    folders.filter { it.id != "all" }.forEach { folder ->
                        val isChecked = currentAssigned.contains(folder.id)
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    val updated = conversationFolders.toMutableMap()
                                    val set = (updated[conv.id] ?: mutableSetOf("all")).toMutableSet()
                                    if (isChecked) set.remove(folder.id) else set.add(folder.id)
                                    set.add("all")
                                    updated[conv.id] = set
                                    conversationFolders = updated
                                }
                                .padding(vertical = 4.dp)
                        ) {
                            Checkbox(
                                checked = isChecked,
                                onCheckedChange = { checked ->
                                    val updated = conversationFolders.toMutableMap()
                                    val set = (updated[conv.id] ?: mutableSetOf("all")).toMutableSet()
                                    if (!checked) set.remove(folder.id) else set.add(folder.id)
                                    set.add("all")
                                    updated[conv.id] = set
                                    conversationFolders = updated
                                }
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(folder.name, fontWeight = FontWeight.Medium)
                        }
                    }
                }
            },
            confirmButton = {
                Button(onClick = { conversationForFolderAssign = null }) {
                    Text("Done")
                }
            }
        )
    }

    // New Direct Chat Dialog
    if (showNewChatDialog) {
        var contactHandle by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = { showNewChatDialog = false },
            title = { Text("New Encrypted Direct Chat", fontWeight = FontWeight.Bold) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("Enter user handle or email on devnu.ir:")
                    OutlinedTextField(
                        value = contactHandle,
                        onValueChange = { contactHandle = it },
                        placeholder = { Text("e.g. @reza or reza@devnu.ir") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp)
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (contactHandle.isNotBlank()) {
                            showNewChatDialog = false
                            // Select existing or open
                            onSelectConversation(conversations.first())
                        }
                    },
                    enabled = contactHandle.isNotBlank()
                ) {
                    Text("Start E2EE Chat")
                }
            },
            dismissButton = {
                TextButton(onClick = { showNewChatDialog = false }) { Text("Cancel") }
            }
        )
    }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ConversationItemRow(
    conversation: Conversation,
    onClick: () -> Unit,
    onLongClick: () -> Unit = {}
) {
    val isDark = isSystemInDarkTheme()

    Surface(
        shape = RoundedCornerShape(16.dp),
        color = if (conversation.isPinned) {
            if (isDark) Color(0x1F3B82F6) else Color(0x103B82F6)
        } else {
            if (isDark) Color(0x0DFFFFFF) else Color(0x05000000)
        },
        border = BorderStroke(
            if (conversation.isPinned) 1.dp else 0.5.dp,
            if (conversation.isPinned) MaterialTheme.colorScheme.primary.copy(alpha = 0.5f)
            else if (isDark) Color(0x1FFFFFFF) else Color(0x0F000000)
        ),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 4.dp)
            .combinedClickable(
                onClick = onClick,
                onLongClick = onLongClick
            )
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box {
                Surface(
                    shape = CircleShape,
                    modifier = Modifier.size(52.dp),
                    color = MaterialTheme.colorScheme.surfaceVariant
                ) {
                    AsyncImage(
                        model = conversation.avatarUrl,
                        contentDescription = conversation.title,
                        modifier = Modifier.fillMaxSize()
                    )
                }

                if (conversation.type == ConversationType.DIRECT) {
                    Box(
                        modifier = Modifier
                            .size(13.dp)
                            .clip(CircleShape)
                            .background(ChatNuEncryptedGreen)
                            .align(Alignment.BottomEnd)
                    )
                }
            }

            Spacer(modifier = Modifier.width(14.dp))

            Column(modifier = Modifier.weight(1f)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.weight(1f, fill = false)
                    ) {
                        if (conversation.isPinned) {
                            Icon(
                                imageVector = Icons.Default.PushPin,
                                contentDescription = "Pinned",
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier
                                    .size(14.dp)
                                    .padding(end = 4.dp)
                            )
                        }
                        Text(
                            text = conversation.title,
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                            maxLines = 1
                        )
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = conversation.lastMessageTime,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                Spacer(modifier = Modifier.height(3.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = conversation.lastMessageText,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        modifier = Modifier.weight(1f)
                    )

                    Row(verticalAlignment = Alignment.CenterVertically) {
                        IconButton(
                            onClick = onLongClick,
                            modifier = Modifier.size(24.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.MoreVert,
                                contentDescription = "Thread options",
                                tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.6f),
                                modifier = Modifier.size(16.dp)
                            )
                        }

                        if (conversation.unreadCount > 0) {
                            Spacer(modifier = Modifier.width(4.dp))
                            Surface(
                                shape = CircleShape,
                                color = MaterialTheme.colorScheme.primary
                            ) {
                                Text(
                                    text = conversation.unreadCount.toString(),
                                    style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                                    color = Color.White,
                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
