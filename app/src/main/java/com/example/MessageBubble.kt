package com.example.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.*
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.model.Message
import com.example.model.MessageStatus
import com.example.model.MessageType
import com.example.ui.theme.*

@Composable
fun MessageBubble(
    message: Message,
    isOutgoing: Boolean,
    onViewOnceClick: () -> Unit = {},
    onReactionSelect: (String) -> Unit = {},
    onTogglePin: () -> Unit = {}
) {
    if (message.type == MessageType.SYSTEM_KEY_CHANGE) {
        SystemMessagePill(
            text = message.text,
            icon = Icons.Default.Lock,
            iconColor = ChatNuAccent,
            isSecurityEvent = true
        )
        return
    }

    val isDark = isAppInDarkTheme()
    var showReactionMenu by remember { mutableStateOf(false) }
    var isVoicePlaying by remember { mutableStateOf(false) }

    val bubbleShape = if (isOutgoing) {
        RoundedCornerShape(20.dp, 20.dp, 4.dp, 20.dp)
    } else {
        RoundedCornerShape(20.dp, 20.dp, 20.dp, 4.dp)
    }

    // Glassmorphism outgoing and incoming styling
    val activePreset = ThemeManager.currentPreset
    val outgoingBrush = Brush.linearGradient(
        colors = listOf(
            activePreset.glassStart,
            activePreset.glassEnd
        )
    )

    val incomingBgColor = if (isDark) Color(0xD91F2937) else Color(0xECFFFFFF)
    val incomingBorderColor = if (isDark) Color(0x26FFFFFF) else Color(0x336366F1)
    val outgoingBorderColor = Color(0x40FFFFFF)

    val textColor = if (isOutgoing) Color.White else (if (isDark) Color(0xFFF1F5F9) else Color(0xFF0F172A))
    val subTextColor = if (isOutgoing) Color.White.copy(alpha = 0.75f) else (if (isDark) Color(0xFF94A3B8) else Color(0xFF64748B))

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 3.dp),
        horizontalAlignment = if (isOutgoing) Alignment.End else Alignment.Start
    ) {
        Box(
            modifier = Modifier.widthIn(max = 300.dp)
        ) {
            Surface(
                shape = bubbleShape,
                color = if (isOutgoing) Color.Transparent else incomingBgColor,
                border = BorderStroke(1.dp, if (isOutgoing) outgoingBorderColor else incomingBorderColor),
                shadowElevation = if (isDark) 4.dp else 2.dp,
                modifier = Modifier
                    .clip(bubbleShape)
                    .then(
                        if (isOutgoing) Modifier.background(outgoingBrush) else Modifier
                    )
                    .clickable { showReactionMenu = !showReactionMenu }
            ) {
                Column(
                    modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp)
                ) {
                    if (!isOutgoing && message.senderName.isNotEmpty()) {
                        Text(
                            text = message.senderName,
                            style = MaterialTheme.typography.labelMedium.copy(
                                color = ChatNuAccentLight,
                                fontWeight = FontWeight.Bold,
                                fontSize = 11.sp
                            ),
                            modifier = Modifier.padding(bottom = 3.dp)
                        )
                    }

                    when (message.type) {
                        MessageType.TEXT -> {
                            Text(
                                text = message.text,
                                style = MaterialTheme.typography.bodyMedium.copy(
                                    color = textColor,
                                    lineHeight = 20.sp
                                )
                            )
                        }

                        MessageType.VOICE -> {
                            val infiniteTransition = rememberInfiniteTransition(label = "voice_anim")
                            val animatedWaveHeight by infiniteTransition.animateFloat(
                                initialValue = 0.3f,
                                targetValue = 1.0f,
                                animationSpec = infiniteRepeatable(
                                    animation = tween(600, easing = LinearEasing),
                                    repeatMode = RepeatMode.Reverse
                                ),
                                label = "wave"
                            )

                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(10.dp)
                            ) {
                                Surface(
                                    shape = CircleShape,
                                    color = if (isOutgoing) Color.White.copy(alpha = 0.25f) else ChatNuAccent.copy(alpha = 0.18f),
                                    border = BorderStroke(1.dp, Color.White.copy(alpha = 0.3f)),
                                    modifier = Modifier
                                        .size(40.dp)
                                        .clickable { isVoicePlaying = !isVoicePlaying }
                                ) {
                                    Icon(
                                        imageVector = if (isVoicePlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                                        contentDescription = "Play voice note",
                                        tint = if (isOutgoing) Color.White else ChatNuAccent,
                                        modifier = Modifier
                                            .padding(8.dp)
                                            .fillMaxSize()
                                    )
                                }

                                Column {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Icon(
                                            imageVector = Icons.Default.GraphicEq,
                                            contentDescription = null,
                                            tint = if (isOutgoing) Color.White.copy(alpha = 0.8f) else ChatNuAccent,
                                            modifier = Modifier.size(14.dp)
                                        )
                                        Spacer(modifier = Modifier.width(4.dp))
                                        Text(
                                            text = "Voice Note (${message.voiceDurationSeconds}s)",
                                            style = MaterialTheme.typography.labelSmall.copy(
                                                color = subTextColor,
                                                fontWeight = FontWeight.SemiBold
                                            )
                                        )
                                    }

                                    Spacer(modifier = Modifier.height(6.dp))

                                    Row(
                                        horizontalArrangement = Arrangement.spacedBy(3.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        val bars = message.voiceWaveform.ifEmpty {
                                            listOf(0.4f, 0.7f, 0.3f, 0.9f, 0.5f, 0.8f, 0.3f, 0.6f, 0.4f)
                                        }
                                        bars.forEachIndexed { idx, h ->
                                            val currentH = if (isVoicePlaying && idx % 2 == 0) (h * animatedWaveHeight).coerceIn(0.2f, 1f) else h
                                            Box(
                                                modifier = Modifier
                                                    .width(3.dp)
                                                    .height((18 * currentH).dp)
                                                    .background(
                                                        if (isOutgoing) Color.White.copy(alpha = 0.9f) else ChatNuAccent,
                                                        CircleShape
                                                    )
                                            )
                                        }
                                    }
                                }
                            }
                        }

                        MessageType.FILE -> {
                            var isFileDownloaded by remember { mutableStateOf(false) }
                            val ext = (message.fileExtension ?: message.fileName?.substringAfterLast('.', "doc") ?: "doc").lowercase()
                            val badgeColor = when (ext) {
                                "pdf" -> Color(0xFFEF4444)
                                "zip", "rar", "7z", "tar" -> Color(0xFFF59E0B)
                                "doc", "docx", "txt", "kt", "swift" -> Color(0xFF3B82F6)
                                "apk", "aab" -> Color(0xFF10B981)
                                else -> ChatNuAccent
                            }

                            Surface(
                                shape = RoundedCornerShape(16.dp),
                                color = if (isOutgoing) Color.White.copy(alpha = 0.15f) else badgeColor.copy(alpha = 0.12f),
                                border = BorderStroke(1.dp, if (isOutgoing) Color.White.copy(alpha = 0.35f) else badgeColor.copy(alpha = 0.35f)),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Row(
                                    modifier = Modifier.padding(10.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                                ) {
                                    // File Badge Icon
                                    Surface(
                                        shape = RoundedCornerShape(12.dp),
                                        color = badgeColor,
                                        modifier = Modifier.size(44.dp)
                                    ) {
                                        Box(contentAlignment = Alignment.Center) {
                                            Text(
                                                text = ext.take(4).uppercase(),
                                                style = MaterialTheme.typography.labelSmall.copy(
                                                    fontWeight = FontWeight.Black,
                                                    color = Color.White,
                                                    fontSize = 11.sp
                                                )
                                            )
                                        }
                                    }

                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(
                                            text = message.fileName ?: message.text,
                                            style = MaterialTheme.typography.bodyMedium.copy(
                                                color = textColor,
                                                fontWeight = FontWeight.Bold
                                            ),
                                            maxLines = 1
                                        )
                                        Text(
                                            text = "${message.fileSize ?: "3.5 MB"} • E2EE Encrypted File",
                                            style = MaterialTheme.typography.labelSmall.copy(
                                                color = subTextColor,
                                                fontSize = 10.sp
                                            )
                                        )
                                    }

                                    Surface(
                                        shape = CircleShape,
                                        color = if (isOutgoing) Color.White.copy(alpha = 0.25f) else badgeColor.copy(alpha = 0.2f),
                                        modifier = Modifier
                                            .size(36.dp)
                                            .clickable { isFileDownloaded = !isFileDownloaded }
                                    ) {
                                        Icon(
                                            imageVector = if (isFileDownloaded) Icons.Default.FolderOpen else Icons.Default.FileDownload,
                                            contentDescription = "Download file",
                                            tint = if (isOutgoing) Color.White else badgeColor,
                                            modifier = Modifier.padding(8.dp)
                                        )
                                    }
                                }
                            }
                        }

                        MessageType.VIEW_ONCE_IMAGE -> {
                            Surface(
                                shape = RoundedCornerShape(14.dp),
                                color = ChatNuViewOnceOrange.copy(alpha = 0.15f),
                                border = BorderStroke(1.dp, ChatNuViewOnceOrange.copy(alpha = 0.4f)),
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable { onViewOnceClick() }
                            ) {
                                Row(
                                    modifier = Modifier.padding(10.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                                ) {
                                    Surface(
                                        shape = CircleShape,
                                        color = ChatNuViewOnceOrange.copy(alpha = 0.2f),
                                        modifier = Modifier.size(34.dp)
                                    ) {
                                        Icon(
                                            imageVector = if (message.isViewOnceOpened) Icons.Default.Lock else Icons.Default.Visibility,
                                            contentDescription = "View Once",
                                            tint = ChatNuViewOnceOrange,
                                            modifier = Modifier.padding(6.dp)
                                        )
                                    }
                                    Column {
                                        Text(
                                            text = if (message.isViewOnceOpened) "View-once Opened" else "View-once Media",
                                            style = MaterialTheme.typography.bodySmall.copy(
                                                color = ChatNuViewOnceOrange,
                                                fontWeight = FontWeight.Bold
                                            )
                                        )
                                        Text(
                                            text = if (message.isViewOnceOpened) "Self-destructed" else "Tap to view (Protected)",
                                            style = MaterialTheme.typography.labelSmall.copy(
                                                color = ChatNuViewOnceOrange.copy(alpha = 0.8f),
                                                fontSize = 10.sp
                                            )
                                        )
                                    }
                                }
                            }
                        }

                        MessageType.LOCATION, MessageType.LIVE_LOCATION -> {
                            Surface(
                                shape = RoundedCornerShape(12.dp),
                                color = if (isOutgoing) Color.White.copy(alpha = 0.15f) else ChatNuEncryptedGreen.copy(alpha = 0.12f),
                                border = BorderStroke(1.dp, if (isOutgoing) Color.White.copy(alpha = 0.3f) else ChatNuEncryptedGreen.copy(alpha = 0.3f))
                            ) {
                                Row(
                                    modifier = Modifier.padding(8.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.LocationOn,
                                        contentDescription = "Location Pin",
                                        tint = if (isOutgoing) Color.White else ChatNuEncryptedGreen
                                    )
                                    Column {
                                        Text(
                                            text = if (message.type == MessageType.LIVE_LOCATION) "Live Location Beacon" else "Location Pin",
                                            style = MaterialTheme.typography.bodyMedium.copy(
                                                color = textColor,
                                                fontWeight = FontWeight.Bold
                                            )
                                        )
                                        Text(
                                            text = "35.6892° N, 51.3890° E (Tehran)",
                                            style = MaterialTheme.typography.labelSmall.copy(
                                                color = subTextColor,
                                                fontSize = 10.sp
                                            )
                                        )
                                    }
                                }
                            }
                        }

                        MessageType.IMAGE -> {
                            Column {
                                message.mediaUrl?.let { url ->
                                    AsyncImage(
                                        model = url,
                                        contentDescription = "Attached image",
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .height(180.dp)
                                            .clip(RoundedCornerShape(12.dp))
                                    )
                                    Spacer(modifier = Modifier.height(6.dp))
                                }
                                Text(
                                    text = message.text,
                                    style = MaterialTheme.typography.bodyMedium.copy(color = textColor)
                                )
                            }
                        }

                        else -> {
                            Text(
                                text = message.text,
                                style = MaterialTheme.typography.bodyMedium.copy(color = textColor)
                            )
                        }
                    }

                    // Timestamp and Read Receipts
                    Row(
                        modifier = Modifier
                            .align(Alignment.End)
                            .padding(top = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        if (message.isPinned) {
                            Icon(
                                imageVector = Icons.Default.PushPin,
                                contentDescription = "Pinned",
                                tint = ChatNuAccent,
                                modifier = Modifier.size(12.dp)
                            )
                        }
                        Text(
                            text = message.timestamp,
                            style = MaterialTheme.typography.labelSmall.copy(
                                color = subTextColor,
                                fontSize = 10.sp
                            )
                        )
                        if (isOutgoing) {
                            val statusIcon = when (message.status) {
                                MessageStatus.READ -> Icons.Default.DoneAll
                                MessageStatus.DELIVERED -> Icons.Default.DoneAll
                                MessageStatus.SENT -> Icons.Default.Done
                                else -> Icons.Default.Schedule
                            }
                            Icon(
                                imageVector = statusIcon,
                                contentDescription = "Delivery Status",
                                tint = if (message.status == MessageStatus.READ) Color(0xFF60A5FA) else Color.White.copy(alpha = 0.75f),
                                modifier = Modifier.size(13.dp)
                            )
                        }
                    }
                }
            }
        }

        // Active Reactions Pill
        if (message.reactions.isNotEmpty()) {
            Surface(
                shape = CircleShape,
                color = if (isDark) Color(0xEE1E293B) else Color(0xEEFFFFFF),
                border = BorderStroke(1.dp, if (isDark) Color(0x33FFFFFF) else Color(0x33000000)),
                shadowElevation = 3.dp,
                modifier = Modifier
                    .padding(top = 2.dp, start = 6.dp, end = 6.dp)
            ) {
                Text(
                    text = message.reactions.joinToString(" "),
                    style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
                )
            }
        }

        // Animated Glass Reaction Picker Popover
        AnimatedVisibility(
            visible = showReactionMenu,
            enter = fadeIn() + scaleIn(),
            exit = fadeOut() + scaleOut()
        ) {
            Surface(
                shape = RoundedCornerShape(20.dp),
                color = if (isDark) Color(0xFA111827) else Color(0xFAFFFFFF),
                border = BorderStroke(1.dp, ChatNuAccent.copy(alpha = 0.4f)),
                shadowElevation = 8.dp,
                modifier = Modifier
                    .padding(top = 6.dp)
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    listOf("❤️", "👍", "🔥", "😂", "🙏", "🔒").forEach { emoji ->
                        Text(
                            text = emoji,
                            fontSize = 20.sp,
                            modifier = Modifier
                                .clickable {
                                    onReactionSelect(emoji)
                                    showReactionMenu = false
                                }
                                .padding(2.dp)
                        )
                    }

                    Surface(
                        shape = CircleShape,
                        color = if (message.isPinned) ChatNuAccent else MaterialTheme.colorScheme.primary.copy(alpha = 0.15f),
                        modifier = Modifier
                            .size(28.dp)
                            .clickable {
                                onTogglePin()
                                showReactionMenu = false
                            }
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(
                                imageVector = Icons.Default.PushPin,
                                contentDescription = if (message.isPinned) "Unpin Message" else "Pin Message",
                                tint = if (message.isPinned) Color.White else MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    }
                }
            }
        }
    }
}
