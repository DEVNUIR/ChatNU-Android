package com.example.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.ui.theme.ChatNuAccent
import com.example.ui.theme.ChatNuDestructiveRed
import kotlinx.coroutines.delay

@Composable
fun VoiceRecorderBar(
    onSendVoice: (durationSeconds: Int) -> Unit,
    onCancelVoice: () -> Unit
) {
    var isRecording by remember { mutableStateOf(false) }
    var secondsElapsed by remember { mutableStateOf(0) }

    LaunchedEffect(isRecording) {
        if (isRecording) {
            secondsElapsed = 0
            while (isRecording) {
                delay(1000)
                secondsElapsed++
            }
        }
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .padding(horizontal = 12.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        if (isRecording) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                IconButton(onClick = {
                    isRecording = false
                    onCancelVoice()
                }) {
                    Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = "Cancel recording",
                        tint = ChatNuDestructiveRed
                    )
                }

                Surface(
                    shape = CircleShape,
                    color = ChatNuDestructiveRed,
                    modifier = Modifier.size(10.dp)
                ) {}

                Text(
                    text = String.format("%02d:%02d", secondsElapsed / 60, secondsElapsed % 60),
                    style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold),
                    color = ChatNuDestructiveRed
                )
            }

            IconButton(onClick = {
                isRecording = false
                onSendVoice(secondsElapsed.coerceAtLeast(1))
            }) {
                Icon(
                    imageVector = Icons.Default.Send,
                    contentDescription = "Send recording",
                    tint = ChatNuAccent
                )
            }
        } else {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = "Hold microphone to record audio...",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.weight(1f)
                )

                Surface(
                    shape = CircleShape,
                    color = ChatNuAccent,
                    modifier = Modifier
                        .size(44.dp)
                        .pointerInput(Unit) {
                            detectTapGestures(
                                onPress = {
                                    isRecording = true
                                    tryAwaitRelease()
                                    if (isRecording) {
                                        isRecording = false
                                        onSendVoice(secondsElapsed.coerceAtLeast(1))
                                    }
                                }
                            )
                        }
                ) {
                    Icon(
                        imageVector = Icons.Default.Mic,
                        contentDescription = "Record Voice",
                        tint = Color.White,
                        modifier = Modifier
                            .padding(10.dp)
                            .fillMaxSize()
                    )
                }
            }
        }
    }
}
