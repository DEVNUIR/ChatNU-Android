package com.example.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.example.model.CallSession
import com.example.model.CallStatus
import com.example.model.CallType
import com.example.ui.theme.ChatNuAccent
import com.example.ui.theme.ChatNuDarkBg
import com.example.ui.theme.ChatNuDestructiveRed
import com.example.ui.theme.ChatNuEncryptedGreen

@Composable
fun CallOverlayView(
    callSession: CallSession,
    onAcceptCall: () -> Unit,
    onEndCall: () -> Unit,
    onToggleMute: () -> Unit,
    onToggleCamera: () -> Unit,
    onToggleSpeaker: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(ChatNuDarkBg)
            .padding(24.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.TopCenter),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(48.dp))

            Surface(
                shape = CircleShape,
                color = ChatNuEncryptedGreen.copy(alpha = 0.2f),
                modifier = Modifier.padding(bottom = 12.dp)
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Lock,
                        contentDescription = "E2EE",
                        tint = ChatNuEncryptedGreen,
                        modifier = Modifier.size(16.dp)
                    )
                    Text(
                        text = "End-to-End Encrypted RTC Call (rtc.devnu.ir)",
                        style = MaterialTheme.typography.labelMedium,
                        color = ChatNuEncryptedGreen
                    )
                }
            }

            Surface(
                shape = CircleShape,
                modifier = Modifier.size(120.dp)
            ) {
                AsyncImage(
                    model = callSession.peerAvatar,
                    contentDescription = callSession.peerName,
                    modifier = Modifier.fillMaxSize()
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = callSession.peerName,
                style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.Bold),
                color = Color.White
            )

            Text(
                text = when (callSession.status) {
                    CallStatus.INCOMING -> "Incoming ${callSession.callType} Call..."
                    CallStatus.OUTGOING -> "Calling..."
                    CallStatus.CONNECTED -> "Connected • 02:45"
                    else -> "Ended"
                },
                style = MaterialTheme.typography.bodyLarge,
                color = Color.White.copy(alpha = 0.7f)
            )
        }

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.BottomCenter)
                .padding(bottom = 36.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (callSession.status == CallStatus.INCOMING) {
                FloatingActionButton(
                    onClick = onAcceptCall,
                    containerColor = ChatNuEncryptedGreen,
                    contentColor = Color.White,
                    shape = CircleShape
                ) {
                    Icon(Icons.Default.Call, contentDescription = "Accept Call")
                }

                FloatingActionButton(
                    onClick = onEndCall,
                    containerColor = ChatNuDestructiveRed,
                    contentColor = Color.White,
                    shape = CircleShape
                ) {
                    Icon(Icons.Default.CallEnd, contentDescription = "Decline Call")
                }
            } else {
                IconButton(
                    onClick = onToggleMute,
                    modifier = Modifier
                        .size(56.dp)
                        .clip(CircleShape)
                        .background(if (callSession.isMuted) ChatNuDestructiveRed else Color.White.copy(alpha = 0.2f))
                ) {
                    Icon(
                        imageVector = if (callSession.isMuted) Icons.Default.MicOff else Icons.Default.Mic,
                        contentDescription = "Mute",
                        tint = Color.White
                    )
                }

                if (callSession.callType == CallType.VIDEO) {
                    IconButton(
                        onClick = onToggleCamera,
                        modifier = Modifier
                            .size(56.dp)
                            .clip(CircleShape)
                            .background(if (!callSession.isCameraOn) ChatNuDestructiveRed else Color.White.copy(alpha = 0.2f))
                    ) {
                        Icon(
                            imageVector = if (callSession.isCameraOn) Icons.Default.Videocam else Icons.Default.VideocamOff,
                            contentDescription = "Camera",
                            tint = Color.White
                        )
                    }
                }

                IconButton(
                    onClick = onToggleSpeaker,
                    modifier = Modifier
                        .size(56.dp)
                        .clip(CircleShape)
                        .background(if (callSession.isSpeakerOn) ChatNuAccent else Color.White.copy(alpha = 0.2f))
                ) {
                    Icon(
                        imageVector = Icons.Default.VolumeUp,
                        contentDescription = "Speaker",
                        tint = Color.White
                    )
                }

                FloatingActionButton(
                    onClick = onEndCall,
                    containerColor = ChatNuDestructiveRed,
                    contentColor = Color.White,
                    shape = CircleShape
                ) {
                    Icon(Icons.Default.CallEnd, contentDescription = "End Call")
                }
            }
        }
    }
}
