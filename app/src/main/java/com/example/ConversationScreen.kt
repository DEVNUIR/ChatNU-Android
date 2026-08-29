package com.example.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import coil.compose.AsyncImage
import com.example.model.Conversation
import com.example.model.ConversationType
import com.example.model.Message
import com.example.model.MessageType
import com.example.model.User
import com.example.ui.components.ChatMessageList
import com.example.ui.components.ChatWallpaperCanvas
import com.example.ui.components.GroupSettingsDialog
import com.example.ui.components.VoiceRecorderBar
import com.example.ui.theme.ChatNuAccent
import com.example.ui.theme.ChatNuDarkBg
import com.example.ui.theme.ChatNuEncryptedGreen
import com.example.ui.theme.ChatNuViewOnceOrange

import com.example.ui.theme.ThemeManager
import com.example.ui.theme.ThemePreset
import com.example.ui.theme.isAppInDarkTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ConversationScreen(
    conversation: Conversation,
    messages: List<Message>,
    onBackClick: () -> Unit,
    onSendMessage: (text: String, type: MessageType) -> Unit,
    onSendVoice: (durationSeconds: Int) -> Unit,
    onSendFile: (fileName: String, fileSize: String, fileExtension: String) -> Unit = { _, _, _ -> },
    onStartVoiceCall: () -> Unit,
    onStartVideoCall: () -> Unit,
    onMarkViewOnceOpened: (messageId: String) -> Unit,
    onAddReaction: (messageId: String, emoji: String) -> Unit,
    onTogglePinMessage: (messageId: String) -> Unit = {},
    onUpdateGroupInfo: (title: String, avatarUrl: String) -> Unit = { _, _ -> },
    onAddGroupMember: (User) -> Unit = {},
    onRemoveGroupMember: (String) -> Unit = {},
    onToggleGroupEncryption: () -> Unit = {},
    onLeaveGroup: () -> Unit = {}
) {
    val isDark = isAppInDarkTheme()
    var inputText by remember { mutableStateOf("") }
    var showAttachmentSheet by remember { mutableStateOf(false) }
    var activeViewOnceUrl by remember { mutableStateOf<String?>(null) }
    var isVoiceMode by remember { mutableStateOf(false) }
    var showFilePickerDialog by remember { mutableStateOf(false) }
    var showThemePalettePicker by remember { mutableStateOf(false) }
    var showGroupSettings by remember { mutableStateOf(false) }

    val topBarGlassBg = if (isDark) Color(0xD90F172A) else Color(0xD9FFFFFF)
    val bottomBarGlassBg = if (isDark) Color(0xE6111827) else Color(0xE6FFFFFF)
    val glassBorderColor = if (isDark) Color(0x26FFFFFF) else Color(0x26000000)

    Box(modifier = Modifier.fillMaxSize()) {
        // Aesthetic Ambient Wallaper Canvas
        ChatWallpaperCanvas(isDark = isDark)

        Scaffold(
            containerColor = Color.Transparent,
            topBar = {
                Surface(
                    color = topBarGlassBg,
                    border = BorderStroke(1.dp, glassBorderColor),
                    shadowElevation = 4.dp,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier
                            .statusBarsPadding()
                            .padding(horizontal = 8.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        IconButton(onClick = onBackClick) {
                            Icon(
                                imageVector = Icons.Default.ArrowBack,
                                contentDescription = "Back",
                                tint = if (isDark) Color.White else Color(0xFF0F172A)
                            )
                        }

                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .weight(1f)
                                .clickable {
                                    if (conversation.type == ConversationType.GROUP) {
                                        showGroupSettings = true
                                    }
                                }
                        ) {
                            Surface(
                                shape = CircleShape,
                                border = BorderStroke(1.dp, ChatNuAccent.copy(alpha = 0.5f)),
                                modifier = Modifier.size(40.dp)
                            ) {
                                AsyncImage(
                                    model = conversation.avatarUrl,
                                    contentDescription = conversation.title,
                                    modifier = Modifier.fillMaxSize()
                                )
                            }

                            Spacer(modifier = Modifier.width(10.dp))

                            Column {
                                Text(
                                    text = conversation.title,
                                    style = MaterialTheme.typography.titleMedium.copy(
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 16.sp
                                    ),
                                    color = if (isDark) Color.White else Color(0xFF0F172A)
                                )
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Surface(
                                        shape = CircleShape,
                                        color = ChatNuEncryptedGreen,
                                        modifier = Modifier.size(6.dp)
                                    ) {}
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text(
                                        text = if (conversation.type == ConversationType.GROUP) "${conversation.members.size} members • Encrypted" else "Online • Encrypted",
                                        style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                                        color = ChatNuEncryptedGreen
                                    )
                                }
                            }
                        }

                        if (conversation.type == ConversationType.GROUP) {
                            Surface(
                                shape = CircleShape,
                                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.12f),
                                modifier = Modifier.size(38.dp)
                            ) {
                                IconButton(onClick = { showGroupSettings = true }) {
                                    Icon(
                                        imageVector = Icons.Default.Group,
                                        contentDescription = "Group Settings",
                                        tint = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                            }
                            Spacer(modifier = Modifier.width(6.dp))
                        }

                        Surface(
                            shape = CircleShape,
                            color = MaterialTheme.colorScheme.primary.copy(alpha = 0.12f),
                            modifier = Modifier.size(38.dp)
                        ) {
                            IconButton(onClick = onStartVoiceCall) {
                                Icon(
                                    imageVector = Icons.Default.Phone,
                                    contentDescription = "Voice Call",
                                    tint = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.width(6.dp))

                        Surface(
                            shape = CircleShape,
                            color = MaterialTheme.colorScheme.primary.copy(alpha = 0.12f),
                            modifier = Modifier.size(38.dp)
                        ) {
                            IconButton(onClick = onStartVideoCall) {
                                Icon(
                                    imageVector = Icons.Default.Videocam,
                                    contentDescription = "Video Call",
                                    tint = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        }
                    }
                }
            },
            bottomBar = {
                Surface(
                    color = bottomBarGlassBg,
                    border = BorderStroke(1.dp, glassBorderColor),
                    shadowElevation = 8.dp,
                    modifier = Modifier
                        .navigationBarsPadding()
                        .fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 8.dp)
                    ) {
                        AnimatedVisibility(
                            visible = isVoiceMode,
                            enter = expandVertically(),
                            exit = shrinkVertically()
                        ) {
                            VoiceRecorderBar(
                                onSendVoice = { duration ->
                                    onSendVoice(duration)
                                    isVoiceMode = false
                                },
                                onCancelVoice = { isVoiceMode = false }
                            )
                        }

                        if (!isVoiceMode) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Surface(
                                    shape = CircleShape,
                                    color = ChatNuAccent.copy(alpha = 0.12f),
                                    modifier = Modifier.size(42.dp)
                                ) {
                                    IconButton(onClick = { showAttachmentSheet = true }) {
                                        Icon(
                                            imageVector = Icons.Default.AttachFile,
                                            contentDescription = "Attach media",
                                            tint = ChatNuAccent
                                        )
                                    }
                                }

                                OutlinedTextField(
                                    value = inputText,
                                    onValueChange = { inputText = it },
                                    placeholder = {
                                        Text(
                                            text = "Encrypted message…",
                                            style = MaterialTheme.typography.bodyMedium.copy(fontSize = 14.sp)
                                        )
                                    },
                                    modifier = Modifier.weight(1f),
                                    shape = RoundedCornerShape(24.dp),
                                    colors = OutlinedTextFieldDefaults.colors(
                                        focusedBorderColor = ChatNuAccent,
                                        unfocusedBorderColor = glassBorderColor,
                                        focusedContainerColor = if (isDark) Color(0x33000000) else Color(0x33FFFFFF),
                                        unfocusedContainerColor = if (isDark) Color(0x22000000) else Color(0x22FFFFFF)
                                    ),
                                    maxLines = 4
                                )

                                Surface(
                                    shape = CircleShape,
                                    color = ChatNuAccent,
                                    shadowElevation = 4.dp,
                                    modifier = Modifier.size(44.dp)
                                ) {
                                    if (inputText.isBlank()) {
                                        IconButton(onClick = { isVoiceMode = true }) {
                                            Icon(
                                                imageVector = Icons.Default.Mic,
                                                contentDescription = "Record Voice Note",
                                                tint = Color.White
                                            )
                                        }
                                    } else {
                                        IconButton(onClick = {
                                            onSendMessage(inputText, MessageType.TEXT)
                                            inputText = ""
                                        }) {
                                            Icon(
                                                imageVector = Icons.Default.Send,
                                                contentDescription = "Send Message",
                                                tint = Color.White
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        ) { innerPadding ->
            Column(
                modifier = Modifier
                    .padding(innerPadding)
                    .fillMaxSize()
            ) {
                // Pinned Messages Glass Bar
                val pinnedMessages = remember(messages) { messages.filter { it.isPinned } }
                if (pinnedMessages.isNotEmpty()) {
                    val latestPinned = pinnedMessages.last()
                    Surface(
                        color = if (isDark) Color(0xD91E293B) else Color(0xF0F1F5F9),
                        border = BorderStroke(0.5.dp, ChatNuAccent.copy(alpha = 0.3f)),
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onTogglePinMessage(latestPinned.id) }
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Default.PushPin,
                                contentDescription = "Pinned Message",
                                tint = ChatNuAccent,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(10.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = "Pinned Message (${pinnedMessages.size})",
                                    style = MaterialTheme.typography.labelSmall.copy(
                                        fontWeight = FontWeight.Bold,
                                        color = ChatNuAccent
                                    )
                                )
                                Text(
                                    text = latestPinned.text,
                                    style = MaterialTheme.typography.bodySmall,
                                    maxLines = 1
                                )
                            }
                            IconButton(
                                onClick = { onTogglePinMessage(latestPinned.id) },
                                modifier = Modifier.size(24.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Close,
                                    contentDescription = "Unpin",
                                    modifier = Modifier.size(14.dp)
                                )
                            }
                        }
                    }
                }

                Box(modifier = Modifier.weight(1f)) {
                    // Main Chat Message List supporting text & system messages
                    ChatMessageList(
                        messages = messages,
                        onViewOnceClick = { msg ->
                            if (!msg.isViewOnceOpened && msg.mediaUrl != null) {
                                activeViewOnceUrl = msg.mediaUrl
                                onMarkViewOnceOpened(msg.id)
                            }
                        },
                        onReactionSelect = { msgId, emoji ->
                            onAddReaction(msgId, emoji)
                        },
                        onTogglePin = { msgId ->
                            onTogglePinMessage(msgId)
                        }
                    )
                }
            }
        }
    }

    // Glassmorphism Protected View-Once Dialog
    if (activeViewOnceUrl != null) {
        Dialog(onDismissRequest = { activeViewOnceUrl = null }) {
            Surface(
                shape = RoundedCornerShape(24.dp),
                color = if (isDark) Color(0xFA111827) else Color(0xFAFFFFFF),
                border = BorderStroke(1.dp, ChatNuViewOnceOrange.copy(alpha = 0.5f)),
                shadowElevation = 16.dp,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Surface(
                        shape = CircleShape,
                        color = ChatNuViewOnceOrange.copy(alpha = 0.15f),
                        border = BorderStroke(1.dp, ChatNuViewOnceOrange.copy(alpha = 0.4f))
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 14.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Default.Lock,
                                contentDescription = null,
                                tint = ChatNuViewOnceOrange,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "View-Once Self-Destructing Media",
                                style = MaterialTheme.typography.labelSmall.copy(
                                    fontWeight = FontWeight.Bold,
                                    color = ChatNuViewOnceOrange
                                )
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    AsyncImage(
                        model = activeViewOnceUrl,
                        contentDescription = "View-Once Media",
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(300.dp)
                            .clip(RoundedCornerShape(16.dp))
                    )

                    Spacer(modifier = Modifier.height(20.dp))

                    Button(
                        onClick = { activeViewOnceUrl = null },
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(containerColor = ChatNuViewOnceOrange),
                        shape = RoundedCornerShape(14.dp)
                    ) {
                        Icon(Icons.Default.VisibilityOff, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Close & Self-Destruct Media", fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }

    // Attachment Modal Bottom Sheet
    if (showAttachmentSheet) {
        ModalBottomSheet(onDismissRequest = { showAttachmentSheet = false }) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text(
                    text = "Encrypted Media & Attachments",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceAround
                ) {
                    AttachmentOptionItem(icon = Icons.Default.InsertDriveFile, label = "Document / File") {
                        showAttachmentSheet = false
                        showFilePickerDialog = true
                    }
                    AttachmentOptionItem(icon = Icons.Default.Image, label = "Photo / Video") {
                        onSendMessage("📷 Encrypted image attachment", MessageType.IMAGE)
                        showAttachmentSheet = false
                    }
                    AttachmentOptionItem(icon = Icons.Default.Visibility, label = "View-Once") {
                        onSendMessage("📷 Confidential View-Once Photo", MessageType.VIEW_ONCE_IMAGE)
                        showAttachmentSheet = false
                    }
                    AttachmentOptionItem(icon = Icons.Default.LocationOn, label = "Live Location") {
                        onSendMessage("📍 Live location sharing initialized", MessageType.LIVE_LOCATION)
                        showAttachmentSheet = false
                    }
                }
            }
        }
    }

    // Interactive File Picker Dialog ("بشه فایل فرستاد")
    if (showFilePickerDialog) {
        var customFileName by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = { showFilePickerDialog = false },
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.InsertDriveFile, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Send Encrypted File", fontWeight = FontWeight.Bold)
                }
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text(
                        text = "Choose a preset document or enter a custom file name:",
                        style = MaterialTheme.typography.bodySmall
                    )

                    // Quick choices
                    val quickFiles = listOf(
                        Triple("DevNu_API_Spec.pdf", "3.2 MB", "pdf"),
                        Triple("E2EE_Source_Archive.zip", "14.8 MB", "zip"),
                        Triple("iOS_Glassmorphic_Design.key", "8.5 MB", "key"),
                        Triple("SignalDoubleRatchet.kt", "128 KB", "kt"),
                        Triple("Release_Build_v2.apk", "24.1 MB", "apk")
                    )

                    quickFiles.forEach { (name, size, ext) ->
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                            border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)),
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    onSendFile(name, size, ext)
                                    showFilePickerDialog = false
                                }
                        ) {
                            Row(
                                modifier = Modifier.padding(12.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    imageVector = Icons.Default.InsertDriveFile,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.size(24.dp)
                                )
                                Spacer(modifier = Modifier.width(10.dp))
                                Column {
                                    Text(text = name, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.bodyMedium)
                                    Text(text = "$size • Click to send", style = MaterialTheme.typography.labelSmall)
                                }
                            }
                        }
                    }

                    OutlinedTextField(
                        value = customFileName,
                        onValueChange = { customFileName = it },
                        placeholder = { Text("Custom File Name (e.g. MyDoc.pdf)") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp)
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (customFileName.isNotBlank()) {
                            val ext = customFileName.substringAfterLast('.', "doc")
                            onSendFile(customFileName, "4.0 MB", ext)
                            showFilePickerDialog = false
                        }
                    },
                    enabled = customFileName.isNotBlank()
                ) {
                    Text("Send File")
                }
            },
            dismissButton = {
                TextButton(onClick = { showFilePickerDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Interactive iOS Theme Color Switcher Dialog ("بشه رنگ تم رو عوض کرد")
    if (showThemePalettePicker) {
        AlertDialog(
            onDismissRequest = { showThemePalettePicker = false },
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Palette, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("iOS Glass Theme Accent", fontWeight = FontWeight.Bold)
                }
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text(text = "Tap any iOS glass palette to change theme dynamically:", style = MaterialTheme.typography.bodySmall)
                    ThemePreset.values().forEach { preset ->
                        val isSelected = ThemeManager.currentPreset == preset
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = preset.primary.copy(alpha = 0.15f),
                            border = BorderStroke(if (isSelected) 2.dp else 1.dp, preset.primary),
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    ThemeManager.currentPreset = preset
                                    showThemePalettePicker = false
                                }
                        ) {
                            Row(
                                modifier = Modifier.padding(12.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Surface(
                                        shape = CircleShape,
                                        color = preset.primary,
                                        modifier = Modifier.size(28.dp)
                                    ) {}
                                    Spacer(modifier = Modifier.width(12.dp))
                                    Text(text = preset.title, fontWeight = FontWeight.Bold, color = preset.primary)
                                }
                                if (isSelected) {
                                    Icon(Icons.Default.Check, contentDescription = "Active", tint = preset.primary)
                                }
                            }
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showThemePalettePicker = false }) {
                    Text("Close")
                }
            }
        )
    }

    if (showGroupSettings && conversation.type == ConversationType.GROUP) {
        GroupSettingsDialog(
            conversation = conversation,
            onDismiss = { showGroupSettings = false },
            onUpdateGroupInfo = onUpdateGroupInfo,
            onAddMember = onAddGroupMember,
            onRemoveMember = onRemoveGroupMember,
            onToggleEncryption = onToggleGroupEncryption,
            onLeaveGroup = {
                showGroupSettings = false
                onLeaveGroup()
                onBackClick()
            }
        )
    }
}

@Composable
fun AttachmentOptionItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.clickable { onClick() }
    ) {
        Surface(
            shape = CircleShape,
            color = ChatNuAccent.copy(alpha = 0.15f),
            border = BorderStroke(1.dp, ChatNuAccent.copy(alpha = 0.3f)),
            modifier = Modifier.size(56.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = ChatNuAccent,
                modifier = Modifier.padding(14.dp)
            )
        }
        Spacer(modifier = Modifier.height(6.dp))
        Text(text = label, style = MaterialTheme.typography.labelMedium)
    }
}
