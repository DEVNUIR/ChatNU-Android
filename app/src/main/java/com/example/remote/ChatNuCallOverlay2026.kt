package com.example.remote

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CallEnd
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.MicOff
import androidx.compose.material.icons.filled.SpeakerPhone
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material.icons.filled.VideocamOff
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.core.content.ContextCompat
import com.example.ui.chatnu2026.ChatNuAvatar
import com.example.ui.chatnu2026.ChatNuAvatarSize
import com.example.ui.chatnu2026.ChatNuGlassSurface
import com.example.ui.chatnu2026.ChatNuRadius
import com.example.ui.chatnu2026.ChatNuSemantic
import com.example.ui.chatnu2026.ChatNuSpacing
import org.webrtc.SurfaceViewRenderer

@Composable
internal fun ChatNuCallOverlay2026(
    state: CallUiState,
    manager: WebRtcCallManager
) {
    if (state.phase == CallPhase.IDLE || state.phase == CallPhase.ENDED) return
    val context = LocalContext.current
    var accepting by remember { mutableStateOf(false) }
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { grants ->
        val audioOk = grants[Manifest.permission.RECORD_AUDIO] == true ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        val cameraOk = !state.video || grants[Manifest.permission.CAMERA] == true ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
        if (audioOk && cameraOk) manager.acceptIncoming()
        accepting = false
    }

    fun acceptIncoming() {
        val missing = buildList {
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                add(Manifest.permission.RECORD_AUDIO)
            }
            if (state.video && ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                add(Manifest.permission.CAMERA)
            }
        }
        if (missing.isEmpty()) manager.acceptIncoming()
        else {
            accepting = true
            permissionLauncher.launch(missing.toTypedArray())
        }
    }

    Dialog(
        onDismissRequest = {},
        properties = DialogProperties(
            usePlatformDefaultWidth = false,
            dismissOnBackPress = false,
            dismissOnClickOutside = false
        )
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        listOf(
                            MaterialTheme.colorScheme.primary.copy(alpha = 0.26f),
                            MaterialTheme.colorScheme.background,
                            MaterialTheme.colorScheme.background
                        )
                    )
                )
        ) {
            if (state.video && state.phase == CallPhase.ACTIVE) {
                ChatNuWebRtcRenderer2026(
                    manager = manager,
                    local = false,
                    modifier = Modifier.fillMaxSize()
                )
                Surface(
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .statusBarsPadding()
                        .padding(16.dp)
                        .size(width = 112.dp, height = 164.dp),
                    shape = RoundedCornerShape(ChatNuRadius.lg),
                    shadowElevation = 12.dp
                ) {
                    if (state.cameraEnabled) {
                        ChatNuWebRtcRenderer2026(manager, local = true, modifier = Modifier.fillMaxSize())
                    } else {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(Icons.Default.VideocamOff, contentDescription = "Camera off")
                        }
                    }
                }
            } else {
                Column(
                    modifier = Modifier.align(Alignment.Center).padding(32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    ChatNuAvatar(
                        title = state.peerName.ifBlank { "ChatNU" },
                        url = null,
                        size = ChatNuAvatarSize.profile
                    )
                    Spacer(Modifier.height(18.dp))
                    Text(
                        state.peerName.ifBlank { "ChatNU call" },
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center
                    )
                    Spacer(Modifier.height(5.dp))
                    Text(
                        when (state.phase) {
                            CallPhase.INCOMING -> if (state.video) "Incoming video call" else "Incoming voice call"
                            CallPhase.CONNECTING -> "Connecting securely…"
                            CallPhase.ACTIVE -> if (state.video) "Video call" else "Voice call"
                            CallPhase.ERROR -> state.error ?: "Call failed"
                            else -> ""
                        },
                        color = if (state.phase == CallPhase.ERROR) ChatNuSemantic.Error else MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center
                    )
                    if (state.phase == CallPhase.CONNECTING) {
                        Spacer(Modifier.height(16.dp))
                        CircularProgressIndicator(modifier = Modifier.size(28.dp), strokeWidth = 2.dp)
                    }
                }
            }

            if (state.phase == CallPhase.INCOMING) {
                ChatNuGlassSurface(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .navigationBarsPadding()
                        .padding(24.dp),
                    shape = RoundedCornerShape(ChatNuRadius.floating),
                    contentPadding = PaddingValues(horizontal = 18.dp, vertical = 12.dp)
                ) {
                    Row(horizontalArrangement = Arrangement.spacedBy(22.dp), verticalAlignment = Alignment.CenterVertically) {
                        FilledIconButton(
                            onClick = manager::rejectIncoming,
                            modifier = Modifier.size(62.dp),
                            colors = androidx.compose.material3.IconButtonDefaults.filledIconButtonColors(
                                containerColor = ChatNuSemantic.Error,
                                contentColor = Color.White
                            )
                        ) {
                            Icon(Icons.Default.CallEnd, contentDescription = "Decline call")
                        }
                        TextButton(onClick = ::acceptIncoming, enabled = !accepting) {
                            Text(if (accepting) "Opening…" else "Accept", fontWeight = FontWeight.Bold)
                        }
                    }
                }
            } else {
                ChatNuGlassSurface(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .navigationBarsPadding()
                        .padding(20.dp),
                    shape = RoundedCornerShape(ChatNuRadius.floating),
                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 8.dp)
                ) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                        FilledIconButton(onClick = manager::toggleMute, modifier = Modifier.size(54.dp)) {
                            Icon(if (state.muted) Icons.Default.MicOff else Icons.Default.Mic, contentDescription = if (state.muted) "Unmute" else "Mute")
                        }
                        if (state.video) {
                            FilledIconButton(onClick = manager::toggleCamera, modifier = Modifier.size(54.dp)) {
                                Icon(if (state.cameraEnabled) Icons.Default.Videocam else Icons.Default.VideocamOff, contentDescription = "Toggle camera")
                            }
                        }
                        FilledIconButton(onClick = manager::toggleSpeaker, modifier = Modifier.size(54.dp)) {
                            Icon(Icons.Default.SpeakerPhone, contentDescription = "Toggle speaker")
                        }
                        FilledIconButton(
                            onClick = manager::endCall,
                            modifier = Modifier.size(58.dp),
                            colors = androidx.compose.material3.IconButtonDefaults.filledIconButtonColors(
                                containerColor = ChatNuSemantic.Error,
                                contentColor = Color.White
                            )
                        ) {
                            Icon(Icons.Default.CallEnd, contentDescription = "End call")
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ChatNuWebRtcRenderer2026(
    manager: WebRtcCallManager,
    local: Boolean,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val renderer = remember(context, local) { SurfaceViewRenderer(context) }
    DisposableEffect(renderer, manager, local) {
        if (local) manager.attachLocalRenderer(renderer) else manager.attachRemoteRenderer(renderer)
        onDispose {
            if (local) manager.detachLocalRenderer(renderer) else manager.detachRemoteRenderer(renderer)
        }
    }
    AndroidView(factory = { renderer }, modifier = modifier)
}
