package com.example.ui.chatnu2026

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.expandHorizontally
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkHorizontally
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChatBubbleOutline
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.DoneAll
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.NotificationsOff
import androidx.compose.material.icons.filled.PeopleOutline
import androidx.compose.material.icons.filled.PersonOutline
import androidx.compose.material.icons.filled.PushPin
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Badge
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.example.model.Conversation
import com.example.model.ConversationType
import com.example.model.MessageDeliveryState

@Composable
fun ChatNuAvatar(
    title: String,
    url: String?,
    modifier: Modifier = Modifier,
    size: androidx.compose.ui.unit.Dp = ChatNuAvatarSize.standard,
    online: Boolean = false,
    savedMessages: Boolean = false
) {
    Box(modifier = modifier.size(size)) {
        Surface(
            modifier = Modifier.matchParentSize(),
            shape = CircleShape,
            color = if (savedMessages) MaterialTheme.colorScheme.primaryContainer
            else MaterialTheme.colorScheme.secondaryContainer
        ) {
            if (!url.isNullOrBlank()) {
                AsyncImage(
                    model = url,
                    contentDescription = "$title avatar",
                    modifier = Modifier.clip(CircleShape)
                )
            } else {
                Box(contentAlignment = Alignment.Center) {
                    Text(
                        text = if (savedMessages) "✦" else title.trim().firstOrNull()?.uppercase() ?: "?",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = if (savedMessages) MaterialTheme.colorScheme.primary
                        else MaterialTheme.colorScheme.onSecondaryContainer
                    )
                }
            }
        }
        if (online) {
            Box(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .size(13.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.surface)
                    .padding(2.dp)
                    .clip(CircleShape)
                    .background(ChatNuSemantic.Online)
            )
        }
    }
}

enum class ChatNuFolder(val label: String) {
    ALL("All"),
    UNREAD("Unread"),
    PERSONAL("Personal"),
    GROUPS("Groups")
}

@Composable
fun ChatNuFolderTabs(
    selected: ChatNuFolder,
    unreadCount: Int,
    groupUnreadCount: Int,
    onSelect: (ChatNuFolder) -> Unit,
    modifier: Modifier = Modifier
) {
    val haptics = LocalHapticFeedback.current
    ChatNuGlassSurface(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(ChatNuRadius.floating),
        elevation = 4.dp,
        contentPadding = PaddingValues(ChatNuSpacing.xs)
    ) {
        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(ChatNuSpacing.xs),
            modifier = Modifier.fillMaxWidth()
        ) {
            items(ChatNuFolder.entries, key = { it.name }) { folder ->
                val active = selected == folder
                val background by animateColorAsState(
                    targetValue = if (active) MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.78f) else Color.Transparent,
                    animationSpec = tween(ChatNuMotion.quickMs),
                    label = "folder-color"
                )
                val horizontalPadding by animateDpAsState(
                    targetValue = if (active) 15.dp else 12.dp,
                    animationSpec = tween(ChatNuMotion.quickMs),
                    label = "folder-padding"
                )
                val scale by animateFloatAsState(
                    targetValue = if (active) 1f else 0.97f,
                    animationSpec = ChatNuMotion.responsiveSpring(),
                    label = "folder-scale"
                )
                val badge = when (folder) {
                    ChatNuFolder.UNREAD -> unreadCount
                    ChatNuFolder.GROUPS -> groupUnreadCount
                    else -> 0
                }
                Surface(
                    onClick = {
                        if (!active) haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                        onSelect(folder)
                    },
                    modifier = Modifier.scale(scale),
                    shape = RoundedCornerShape(ChatNuRadius.pill),
                    color = background,
                    contentColor = if (active) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurfaceVariant
                ) {
                    Row(
                        modifier = Modifier
                            .defaultMinSize(minHeight = 40.dp)
                            .padding(horizontal = horizontalPadding, vertical = 8.dp)
                            .animateContentSize(animationSpec = ChatNuMotion.responsiveSpring()),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Text(
                            folder.label,
                            style = MaterialTheme.typography.labelLarge,
                            fontWeight = if (active) FontWeight.Bold else FontWeight.Medium
                        )
                        AnimatedVisibility(
                            visible = badge > 0,
                            enter = fadeIn(tween(ChatNuMotion.quickMs)) + expandHorizontally(),
                            exit = fadeOut(tween(ChatNuMotion.quickMs)) + shrinkHorizontally()
                        ) {
                            Badge(containerColor = MaterialTheme.colorScheme.primary) {
                                Text(if (badge > 99) "99+" else badge.toString())
                            }
                        }
                    }
                }
            }
        }
    }
}

enum class ChatNuPrimaryDestination(val label: String) {
    CHATS("Chats"),
    CONTACTS("Contacts"),
    SETTINGS("Settings")
}

@Composable
fun ChatNuFloatingNav(
    selected: ChatNuPrimaryDestination,
    onSelect: (ChatNuPrimaryDestination) -> Unit,
    modifier: Modifier = Modifier
) {
    val haptics = LocalHapticFeedback.current
    ChatNuGlassSurface(
        modifier = modifier,
        shape = RoundedCornerShape(ChatNuRadius.floating),
        elevation = ChatNuDepth.overlay,
        contentPadding = PaddingValues(horizontal = 6.dp, vertical = 5.dp)
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
            ChatNuPrimaryDestination.entries.forEach { destination ->
                val active = selected == destination
                val tint by animateColorAsState(
                    if (active) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurfaceVariant,
                    animationSpec = tween(ChatNuMotion.quickMs),
                    label = "nav-tint"
                )
                val container by animateColorAsState(
                    if (active) MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.82f) else Color.Transparent,
                    animationSpec = tween(ChatNuMotion.quickMs),
                    label = "nav-container"
                )
                val scale by animateFloatAsState(
                    if (active) 1f else 0.96f,
                    animationSpec = ChatNuMotion.responsiveSpring(),
                    label = "nav-scale"
                )
                Surface(
                    onClick = {
                        if (!active) haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                        onSelect(destination)
                    },
                    modifier = Modifier.scale(scale),
                    color = container,
                    shape = RoundedCornerShape(ChatNuRadius.pill)
                ) {
                    Row(
                        modifier = Modifier
                            .defaultMinSize(minWidth = ChatNuTouchTarget.comfortable, minHeight = ChatNuTouchTarget.minimum)
                            .padding(horizontal = 12.dp)
                            .animateContentSize(animationSpec = ChatNuMotion.responsiveSpring()),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            imageVector = when (destination) {
                                ChatNuPrimaryDestination.CHATS -> Icons.Default.ChatBubbleOutline
                                ChatNuPrimaryDestination.CONTACTS -> Icons.Default.PeopleOutline
                                ChatNuPrimaryDestination.SETTINGS -> Icons.Default.Settings
                            },
                            contentDescription = destination.label,
                            tint = tint,
                            modifier = Modifier.size(ChatNuIconSize.standard)
                        )
                        AnimatedVisibility(
                            visible = active,
                            enter = fadeIn(tween(ChatNuMotion.quickMs)) + expandHorizontally(),
                            exit = fadeOut(tween(ChatNuMotion.quickMs)) + shrinkHorizontally()
                        ) {
                            Row {
                                Spacer(Modifier.width(7.dp))
                                Text(
                                    destination.label,
                                    color = tint,
                                    style = MaterialTheme.typography.labelMedium,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ChatNuConversationRow(
    conversation: Conversation,
    draft: String?,
    onClick: () -> Unit,
    onLongClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val haptics = LocalHapticFeedback.current
    val preview = draft?.takeIf { it.isNotBlank() } ?: conversation.lastMessageText.ifBlank { "No messages yet" }
    Row(
        modifier = modifier
            .fillMaxWidth()
            .combinedClickable(
                onClick = onClick,
                onLongClick = {
                    haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                    onLongClick()
                }
            )
            .padding(horizontal = ChatNuSpacing.lg, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        ChatNuAvatar(
            title = conversation.title,
            url = conversation.avatarUrl,
            size = ChatNuAvatarSize.conversation
        )
        Spacer(Modifier.width(ChatNuSpacing.md))
        Column(modifier = Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    conversation.title,
                    modifier = Modifier.weight(1f),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = if (conversation.unreadCount > 0) FontWeight.Bold else FontWeight.SemiBold
                )
                if (conversation.isPinned) {
                    Icon(
                        Icons.Default.PushPin,
                        contentDescription = "Pinned",
                        modifier = Modifier.size(14.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(Modifier.width(5.dp))
                }
                Text(
                    conversation.lastMessageTime,
                    style = MaterialTheme.typography.labelSmall,
                    color = if (conversation.unreadCount > 0) MaterialTheme.colorScheme.primary
                    else MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Spacer(Modifier.height(3.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (draft?.isNotBlank() == true) {
                    Text(
                        "Draft: ",
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                } else if (conversation.type == ConversationType.GROUP) {
                    Icon(
                        Icons.Default.Group,
                        contentDescription = "Group",
                        modifier = Modifier.size(15.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Spacer(Modifier.width(5.dp))
                } else {
                    Icon(
                        Icons.Default.PersonOutline,
                        contentDescription = "Personal chat",
                        modifier = Modifier.size(15.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(Modifier.width(5.dp))
                }
                Text(
                    preview,
                    modifier = Modifier.weight(1f),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                if (conversation.isMuted) {
                    Icon(
                        Icons.Default.NotificationsOff,
                        contentDescription = "Muted",
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                AnimatedVisibility(
                    visible = conversation.unreadCount > 0,
                    enter = fadeIn(tween(ChatNuMotion.quickMs)),
                    exit = fadeOut(tween(ChatNuMotion.quickMs))
                ) {
                    Row {
                        Spacer(Modifier.width(8.dp))
                        Badge(containerColor = MaterialTheme.colorScheme.primary) {
                            Text(if (conversation.unreadCount > 99) "99+" else conversation.unreadCount.toString())
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ChatNuDeliveryIndicator(
    state: MessageDeliveryState,
    modifier: Modifier = Modifier
) {
    when (state) {
        MessageDeliveryState.QUEUED_OFFLINE -> Icon(
            Icons.Default.Schedule,
            contentDescription = "Queued offline",
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = modifier.size(13.dp)
        )
        MessageDeliveryState.SENDING -> CircularProgressIndicator(
            modifier = modifier.size(12.dp),
            strokeWidth = 1.5.dp,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        MessageDeliveryState.SENT_TO_SERVER -> Icon(
            Icons.Default.Check,
            contentDescription = "Sent to server",
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = modifier.size(14.dp)
        )
        MessageDeliveryState.DELIVERED_TO_RECIPIENT_DEVICE -> Icon(
            Icons.Default.DoneAll,
            contentDescription = "Delivered to recipient device",
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = modifier.size(15.dp)
        )
        MessageDeliveryState.READ -> Icon(
            Icons.Default.DoneAll,
            contentDescription = "Read",
            tint = ChatNuSemantic.Read,
            modifier = modifier.size(15.dp)
        )
        MessageDeliveryState.FAILED -> Icon(
            Icons.Default.ErrorOutline,
            contentDescription = "Send failed",
            tint = ChatNuSemantic.Error,
            modifier = modifier.size(15.dp)
        )
    }
}
