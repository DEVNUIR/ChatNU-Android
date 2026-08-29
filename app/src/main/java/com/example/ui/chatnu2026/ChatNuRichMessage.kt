package com.example.ui.chatnu2026

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.FilledTonalIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil.compose.SubcomposeAsyncImage
import com.example.model.Message
import com.example.model.MessageType
import com.example.model.toDeliveryState
import kotlin.math.PI
import kotlin.math.floor
import kotlin.math.ln
import kotlin.math.pow
import kotlin.math.tan

internal enum class MessageGroupPosition { SINGLE, FIRST, MIDDLE, LAST }

@Composable
internal fun ChatNuRichMessageBubble(
    message: Message,
    mine: Boolean,
    groupPosition: MessageGroupPosition,
    showSender: Boolean,
    playing: Boolean,
    onPlayVoice: () -> Unit,
    onOpenAttachment: () -> Unit,
    onOpenLocation: (Double, Double, Boolean) -> Unit,
    onRetryFailed: (() -> Unit)?,
    modifier: Modifier = Modifier
) {
    if (message.type == MessageType.SYSTEM_KEY_CHANGE) {
        Row(modifier = modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
            Surface(
                shape = RoundedCornerShape(ChatNuRadius.pill),
                color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.80f)
            ) {
                Text(
                    message.text,
                    modifier = Modifier.padding(horizontal = ChatNuSpacing.md, vertical = 6.dp),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        return
    }

    val shape = messageShape(mine, groupPosition)
    val bubbleColor = if (mine) {
        MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.96f)
    } else {
        MaterialTheme.colorScheme.surface.copy(alpha = 0.98f)
    }
    val location = if (message.type == MessageType.LOCATION || message.type == MessageType.LIVE_LOCATION) {
        message.latitude?.let { lat -> message.longitude?.let { lon -> lat to lon } } ?: parseCoordinates(message.text)
    } else null

    Box(modifier = modifier.fillMaxWidth()) {
        Surface(
            modifier = Modifier
                .align(if (mine) Alignment.CenterEnd else Alignment.CenterStart)
                .widthIn(max = 340.dp),
            shape = shape,
            color = bubbleColor,
            tonalElevation = if (mine) 0.dp else 1.dp,
            shadowElevation = 1.dp
        ) {
            Column(modifier = Modifier.padding(horizontal = 10.dp, vertical = 8.dp)) {
                if (showSender && !mine && message.senderName.isNotBlank()) {
                    Text(
                        message.senderName,
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(Modifier.height(3.dp))
                }

                message.replyToText?.takeIf { it.isNotBlank() }?.let { reply ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(ChatNuRadius.sm))
                            .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.08f))
                            .padding(8.dp)
                    ) {
                        Box(
                            Modifier
                                .width(3.dp)
                                .height(32.dp)
                                .clip(CircleShape)
                                .background(MaterialTheme.colorScheme.primary)
                        )
                        Spacer(Modifier.width(7.dp))
                        Text(
                            reply,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Spacer(Modifier.height(6.dp))
                }

                when {
                    location != null -> ChatNuLocationPreview(
                        latitude = location.first,
                        longitude = location.second,
                        live = message.type == MessageType.LIVE_LOCATION,
                        onClick = { onOpenLocation(location.first, location.second, message.type == MessageType.LIVE_LOCATION) }
                    )
                    message.type == MessageType.IMAGE || message.type == MessageType.VIEW_ONCE_IMAGE -> ChatNuImageMessage(
                        message = message,
                        onClick = onOpenAttachment
                    )
                    message.type == MessageType.VIDEO || message.type == MessageType.VIEW_ONCE_VIDEO -> ChatNuVideoMessage(
                        message = message,
                        onClick = onOpenAttachment
                    )
                    message.type == MessageType.VOICE -> ChatNuVoiceMessage(
                        message = message,
                        playing = playing,
                        onPlay = onPlayVoice
                    )
                    message.type == MessageType.FILE || message.attachmentId != null -> ChatNuFileMessage(
                        message = message,
                        onClick = onOpenAttachment
                    )
                    else -> Text(message.text, style = MaterialTheme.typography.bodyLarge)
                }

                Spacer(Modifier.height(4.dp))
                Row(
                    modifier = Modifier.align(Alignment.End),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        message.timestamp,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    if (mine) {
                        val delivery = message.status.toDeliveryState()
                        Box(
                            modifier = if (delivery == com.example.model.MessageDeliveryState.FAILED && onRetryFailed != null) {
                                Modifier.clickable(onClick = onRetryFailed)
                            } else Modifier
                        ) {
                            ChatNuDeliveryIndicator(delivery)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ChatNuImageMessage(message: Message, onClick: () -> Unit) {
    val source = message.localUri ?: message.mediaUrl
    if (!source.isNullOrBlank()) {
        SubcomposeAsyncImage(
            model = source,
            contentDescription = message.fileName ?: "Image message",
            contentScale = ContentScale.Crop,
            modifier = Modifier
                .widthIn(min = 180.dp, max = 300.dp)
                .aspectRatio(4f / 3f)
                .clip(RoundedCornerShape(ChatNuRadius.md))
                .clickable(onClick = onClick),
            loading = {
                Box(Modifier.fillMaxWidth().aspectRatio(4f / 3f), contentAlignment = Alignment.Center) {
                    Icon(Icons.Default.Image, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            },
            error = { ChatNuMediaPlaceholder(Icons.Default.Image, message.fileName ?: "Encrypted image", onClick) }
        )
    } else {
        ChatNuMediaPlaceholder(
            icon = if (message.type == MessageType.VIEW_ONCE_IMAGE) Icons.Default.VisibilityOff else Icons.Default.Image,
            title = message.fileName ?: if (message.type == MessageType.VIEW_ONCE_IMAGE) "View-once image" else "Encrypted image",
            onClick = onClick
        )
    }
}

@Composable
private fun ChatNuVideoMessage(message: Message, onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        modifier = Modifier.widthIn(min = 220.dp, max = 300.dp).aspectRatio(16f / 9f),
        shape = RoundedCornerShape(ChatNuRadius.md),
        color = MaterialTheme.colorScheme.surfaceVariant
    ) {
        Box(contentAlignment = Alignment.Center) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Surface(shape = CircleShape, color = MaterialTheme.colorScheme.surface.copy(alpha = 0.86f)) {
                    Icon(Icons.Default.PlayArrow, contentDescription = "Play video", modifier = Modifier.padding(12.dp))
                }
                Spacer(Modifier.height(8.dp))
                Text(
                    message.fileName ?: if (message.type == MessageType.VIEW_ONCE_VIDEO) "View-once video" else "Encrypted video",
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    style = MaterialTheme.typography.labelMedium
                )
            }
            Icon(
                if (message.type == MessageType.VIEW_ONCE_VIDEO) Icons.Default.VisibilityOff else Icons.Default.Videocam,
                contentDescription = null,
                modifier = Modifier.align(Alignment.TopEnd).padding(8.dp).size(18.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun ChatNuVoiceMessage(message: Message, playing: Boolean, onPlay: () -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.widthIn(min = 210.dp, max = 290.dp)) {
        FilledTonalIconButton(onClick = onPlay, modifier = Modifier.size(42.dp)) {
            Icon(if (playing) Icons.Default.Pause else Icons.Default.PlayArrow, contentDescription = if (playing) "Pause voice message" else "Play voice message")
        }
        Spacer(Modifier.width(8.dp))
        Column(modifier = Modifier.weight(1f)) {
            if (message.voiceWaveform.isNotEmpty()) {
                VoiceWaveform(message.voiceWaveform)
            } else {
                Canvas(modifier = Modifier.fillMaxWidth().height(18.dp)) {
                    drawLine(
                        color = Color.Gray.copy(alpha = 0.45f),
                        start = Offset(0f, size.height / 2f),
                        end = Offset(size.width, size.height / 2f),
                        strokeWidth = 3.dp.toPx(),
                        cap = StrokeCap.Round
                    )
                }
            }
            Text(
                if (message.voiceDurationSeconds > 0) formatSeconds(message.voiceDurationSeconds) else "Voice message",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun VoiceWaveform(samples: List<Float>) {
    Canvas(modifier = Modifier.fillMaxWidth().height(28.dp)) {
        val normalized = samples.take(48)
        if (normalized.isEmpty()) return@Canvas
        val gap = 2.dp.toPx()
        val barWidth = ((size.width - gap * (normalized.size - 1)) / normalized.size).coerceAtLeast(1.dp.toPx())
        normalized.forEachIndexed { index, value ->
            val fraction = value.coerceIn(0.08f, 1f)
            val barHeight = size.height * fraction
            val x = index * (barWidth + gap) + barWidth / 2f
            drawLine(
                color = Color.Gray.copy(alpha = 0.72f),
                start = Offset(x, (size.height - barHeight) / 2f),
                end = Offset(x, (size.height + barHeight) / 2f),
                strokeWidth = barWidth,
                cap = StrokeCap.Round
            )
        }
    }
}

@Composable
private fun ChatNuFileMessage(message: Message, onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(ChatNuRadius.md),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.65f)
    ) {
        Row(modifier = Modifier.padding(10.dp), verticalAlignment = Alignment.CenterVertically) {
            Surface(shape = RoundedCornerShape(ChatNuRadius.sm), color = MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)) {
                Icon(Icons.Default.Description, contentDescription = null, modifier = Modifier.padding(10.dp), tint = MaterialTheme.colorScheme.primary)
            }
            Spacer(Modifier.width(9.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(message.fileName ?: message.text.ifBlank { "Attachment" }, maxLines = 2, overflow = TextOverflow.Ellipsis, fontWeight = FontWeight.SemiBold)
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    message.fileSize?.let { Text(it, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant) }
                    message.fileExtension?.let { Text(it.uppercase(), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary) }
                }
            }
            Icon(Icons.Default.Download, contentDescription = "Open file", modifier = Modifier.size(20.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun ChatNuMediaPlaceholder(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    onClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        modifier = Modifier.widthIn(min = 210.dp, max = 300.dp).aspectRatio(4f / 3f),
        shape = RoundedCornerShape(ChatNuRadius.md),
        color = MaterialTheme.colorScheme.surfaceVariant
    ) {
        Box(contentAlignment = Alignment.Center) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(icon, contentDescription = null, modifier = Modifier.size(32.dp), tint = MaterialTheme.colorScheme.primary)
                Spacer(Modifier.height(7.dp))
                Text(title, maxLines = 2, overflow = TextOverflow.Ellipsis, style = MaterialTheme.typography.labelMedium)
                Text("Tap to decrypt", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
internal fun ChatNuLocationPreview(
    latitude: Double,
    longitude: Double,
    live: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val tile = osmTile(latitude, longitude, zoom = 15)
    Surface(
        onClick = onClick,
        modifier = modifier.width(260.dp),
        shape = RoundedCornerShape(ChatNuRadius.md),
        color = MaterialTheme.colorScheme.surfaceVariant
    ) {
        Column {
            Box(modifier = Modifier.size(260.dp)) {
                SubcomposeAsyncImage(
                    model = tile.url,
                    contentDescription = if (live) "Live location map preview" else "Location map preview",
                    contentScale = ContentScale.FillBounds,
                    modifier = Modifier.matchParentSize(),
                    loading = { MapFallback(live) },
                    error = { MapFallback(live) }
                )
                Icon(
                    if (live) Icons.Default.MyLocation else Icons.Default.LocationOn,
                    contentDescription = null,
                    tint = if (live) ChatNuSemantic.Error else MaterialTheme.colorScheme.primary,
                    modifier = Modifier
                        .offset(
                            x = (tile.xFraction * 260f).dp - 14.dp,
                            y = (tile.yFraction * 260f).dp - 28.dp
                        )
                        .size(28.dp)
                )
                Surface(
                    modifier = Modifier.align(Alignment.BottomEnd).padding(5.dp),
                    color = Color.Black.copy(alpha = 0.62f),
                    shape = RoundedCornerShape(5.dp)
                ) {
                    Text("© OpenStreetMap contributors", color = Color.White, style = MaterialTheme.typography.labelSmall, modifier = Modifier.padding(horizontal = 5.dp, vertical = 2.dp))
                }
            }
            Row(modifier = Modifier.padding(10.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(if (live) Icons.Default.MyLocation else Icons.Default.LocationOn, contentDescription = null, tint = if (live) ChatNuSemantic.Error else MaterialTheme.colorScheme.primary)
                Spacer(Modifier.width(7.dp))
                Column {
                    Text(if (live) "Live location update" else "Location", fontWeight = FontWeight.SemiBold)
                    Text("Tap to view map", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}

@Composable
private fun MapFallback(live: Boolean) {
    Box(modifier = Modifier.fillMaxWidth().aspectRatio(1f).background(MaterialTheme.colorScheme.surfaceVariant), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(if (live) Icons.Default.MyLocation else Icons.Default.LocationOn, contentDescription = null, modifier = Modifier.size(34.dp), tint = MaterialTheme.colorScheme.primary)
            Spacer(Modifier.height(6.dp))
            Text("Map unavailable", style = MaterialTheme.typography.labelMedium)
        }
    }
}

private data class OsmTile(
    val url: String,
    val xFraction: Float,
    val yFraction: Float
)

private fun osmTile(latitude: Double, longitude: Double, zoom: Int): OsmTile {
    val lat = latitude.coerceIn(-85.05112878, 85.05112878)
    val lon = longitude.coerceIn(-180.0, 180.0)
    val n = 2.0.pow(zoom.toDouble())
    val x = (lon + 180.0) / 360.0 * n
    val latRad = lat * PI / 180.0
    val y = (1.0 - ln(tan(latRad) + 1.0 / kotlin.math.cos(latRad)) / PI) / 2.0 * n
    val tileX = floor(x).toInt().coerceIn(0, n.toInt() - 1)
    val tileY = floor(y).toInt().coerceIn(0, n.toInt() - 1)
    return OsmTile(
        url = "https://tile.openstreetmap.org/$zoom/$tileX/$tileY.png",
        xFraction = (x - floor(x)).toFloat().coerceIn(0f, 1f),
        yFraction = (y - floor(y)).toFloat().coerceIn(0f, 1f)
    )
}

internal fun parseCoordinates(text: String): Pair<Double, Double>? {
    val match = Regex("(-?\\d{1,3}\\.\\d+),\\s*(-?\\d{1,3}\\.\\d+)").find(text) ?: return null
    val lat = match.groupValues[1].toDoubleOrNull() ?: return null
    val lon = match.groupValues[2].toDoubleOrNull() ?: return null
    if (lat !in -90.0..90.0 || lon !in -180.0..180.0) return null
    return lat to lon
}

private fun messageShape(mine: Boolean, position: MessageGroupPosition): RoundedCornerShape {
    val large = ChatNuRadius.md
    val small = 6.dp
    return if (mine) {
        when (position) {
            MessageGroupPosition.SINGLE -> RoundedCornerShape(large, large, small, large)
            MessageGroupPosition.FIRST -> RoundedCornerShape(large, large, small, large)
            MessageGroupPosition.MIDDLE -> RoundedCornerShape(large, small, small, large)
            MessageGroupPosition.LAST -> RoundedCornerShape(large, small, small, large)
        }
    } else {
        when (position) {
            MessageGroupPosition.SINGLE -> RoundedCornerShape(large, large, large, small)
            MessageGroupPosition.FIRST -> RoundedCornerShape(large, large, large, small)
            MessageGroupPosition.MIDDLE -> RoundedCornerShape(small, large, large, small)
            MessageGroupPosition.LAST -> RoundedCornerShape(small, large, large, small)
        }
    }
}

private fun formatSeconds(total: Int): String = "%d:%02d".format(total / 60, total % 60)
