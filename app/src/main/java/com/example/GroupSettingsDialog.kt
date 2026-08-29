package com.example.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
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
import coil.compose.AsyncImage
import com.example.data.MockBackend
import com.example.model.Conversation
import com.example.model.User
import com.example.ui.theme.ChatNuDestructiveRed
import com.example.ui.theme.ChatNuEncryptedGreen

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GroupSettingsDialog(
    conversation: Conversation,
    onDismiss: () -> Unit,
    onUpdateGroupInfo: (title: String, avatarUrl: String) -> Unit,
    onAddMember: (User) -> Unit,
    onRemoveMember: (String) -> Unit,
    onToggleEncryption: () -> Unit,
    onLeaveGroup: () -> Unit
) {
    var title by remember(conversation) { mutableStateOf(conversation.title) }
    var avatarUrl by remember(conversation) { mutableStateOf(conversation.avatarUrl ?: "") }
    var isEncrypted by remember(conversation) { mutableStateOf(conversation.isEncrypted) }
    var showAddMemberDialog by remember { mutableStateOf(false) }

    val presetAvatars = listOf(
        "https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=150",
        "https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=150",
        "https://images.unsplash.com/photo-1511632765486-a01980e01a18?w=150"
    )

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Default.Groups,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.width(10.dp))
                Text("Group Settings & Permissions", fontWeight = FontWeight.Bold)
            }
        },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                    Surface(
                        shape = CircleShape,
                        modifier = Modifier.size(72.dp),
                        border = BorderStroke(2.dp, MaterialTheme.colorScheme.primary)
                    ) {
                        AsyncImage(
                            model = avatarUrl,
                            contentDescription = "Group Icon",
                            modifier = Modifier.fillMaxSize()
                        )
                    }

                    Spacer(modifier = Modifier.height(6.dp))
                    Text("Change Group Photo", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary)

                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.padding(top = 4.dp)
                    ) {
                        presetAvatars.forEach { preset ->
                            Surface(
                                shape = CircleShape,
                                border = if (preset == avatarUrl) BorderStroke(2.dp, MaterialTheme.colorScheme.primary) else null,
                                modifier = Modifier
                                    .size(36.dp)
                                    .clickable { avatarUrl = preset }
                            ) {
                                AsyncImage(model = preset, contentDescription = null, modifier = Modifier.fillMaxSize())
                            }
                        }
                    }
                }

                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Group Title") },
                    leadingIcon = { Icon(Icons.Default.Group, contentDescription = null) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp)
                )

                Divider()

                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.08f),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                imageVector = if (isEncrypted) Icons.Default.Lock else Icons.Default.LockOpen,
                                contentDescription = null,
                                tint = if (isEncrypted) ChatNuEncryptedGreen else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.width(10.dp))
                            Column {
                                Text("End-to-End Encryption", style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold))
                                Text(
                                    text = if (isEncrypted) "Encryption enabled" else "Disabled for this channel",
                                    style = MaterialTheme.typography.labelSmall
                                )
                            }
                        }
                        Switch(
                            checked = isEncrypted,
                            onCheckedChange = {
                                isEncrypted = it
                                onToggleEncryption()
                            }
                        )
                    }
                }

                Divider()

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Members (${conversation.members.size})",
                        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold),
                        color = MaterialTheme.colorScheme.primary
                    )
                    TextButton(onClick = { showAddMemberDialog = true }) {
                        Icon(Icons.Default.PersonAdd, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Add Member")
                    }
                }

                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    conversation.members.forEach { member ->
                        Surface(
                            shape = RoundedCornerShape(10.dp),
                            color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier.padding(8.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Surface(shape = CircleShape, modifier = Modifier.size(32.dp)) {
                                        AsyncImage(model = member.avatarUrl, contentDescription = member.displayName, modifier = Modifier.fillMaxSize())
                                    }
                                    Spacer(modifier = Modifier.width(10.dp))
                                    Column {
                                        Text(member.displayName, style = MaterialTheme.typography.bodySmall.copy(fontWeight = FontWeight.Bold))
                                        Text("@${member.username}", style = MaterialTheme.typography.labelSmall)
                                    }
                                }

                                if (conversation.members.size > 1) {
                                    IconButton(
                                        onClick = { onRemoveMember(member.id) },
                                        modifier = Modifier.size(28.dp)
                                    ) {
                                        Icon(
                                            imageVector = Icons.Default.PersonRemove,
                                            contentDescription = "Remove",
                                            tint = ChatNuDestructiveRed,
                                            modifier = Modifier.size(16.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }

                Divider()

                TextButton(
                    onClick = onLeaveGroup,
                    colors = ButtonDefaults.textButtonColors(contentColor = ChatNuDestructiveRed),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(Icons.Default.ExitToApp, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Leave and Delete Group Chat", fontWeight = FontWeight.Bold)
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    onUpdateGroupInfo(title, avatarUrl)
                    onDismiss()
                }
            ) {
                Icon(Icons.Default.Save, contentDescription = null)
                Spacer(modifier = Modifier.width(6.dp))
                Text("Save Changes")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Close")
            }
        }
    )

    if (showAddMemberDialog) {
        val availableUsers = MockBackend.mockUsers.filter { user ->
            conversation.members.none { it.id == user.id }
        }

        AlertDialog(
            onDismissRequest = { showAddMemberDialog = false },
            title = { Text("Add Member to Group", fontWeight = FontWeight.Bold) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (availableUsers.isEmpty()) {
                        Text("All contacts are already in this group.", style = MaterialTheme.typography.bodySmall)
                    } else {
                        availableUsers.forEach { user ->
                            Surface(
                                shape = RoundedCornerShape(10.dp),
                                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable {
                                        onAddMember(user)
                                        showAddMemberDialog = false
                                    }
                            ) {
                                Row(
                                    modifier = Modifier.padding(10.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Surface(shape = CircleShape, modifier = Modifier.size(36.dp)) {
                                        AsyncImage(model = user.avatarUrl, contentDescription = user.displayName, modifier = Modifier.fillMaxSize())
                                    }
                                    Spacer(modifier = Modifier.width(10.dp))
                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(user.displayName, style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold))
                                        Text("@${user.username}", style = MaterialTheme.typography.labelSmall)
                                    }
                                    Icon(Icons.Default.Add, contentDescription = "Add", tint = MaterialTheme.colorScheme.primary)
                                }
                            }
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showAddMemberDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}