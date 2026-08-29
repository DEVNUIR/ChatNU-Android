package com.example.remote

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Cloud
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.Key
import androidx.compose.material.icons.filled.LightMode
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Logout
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material.icons.filled.PhoneAndroid
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.SettingsBrightness
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.BuildConfig
import com.example.crypto.DeviceE2ee
import com.example.model.User
import com.example.ui.chatnu2026.ChatNuAvatar
import com.example.ui.chatnu2026.ChatNuAvatarSize
import com.example.ui.chatnu2026.ChatNuGlassSurface
import com.example.ui.chatnu2026.ChatNuRadius
import com.example.ui.chatnu2026.ChatNuSpacing
import com.example.ui.theme.ThemeManager
import com.example.ui.theme.ThemeMode
import com.example.ui.theme.ThemePreset

@Composable
fun EnhancedProductionSettingsScreen(
    user: User?,
    realtimeStatus: RealtimeStatus,
    onBack: () -> Unit,
    onLogout: () -> Unit
) {
    var confirmLogout by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .statusBarsPadding()
            .navigationBarsPadding()
    ) {
        ChatNuGlassSurface(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = ChatNuSpacing.sm, vertical = ChatNuSpacing.sm),
            shape = RoundedCornerShape(ChatNuRadius.floating),
            elevation = 8.dp,
            contentPadding = PaddingValues(horizontal = 4.dp, vertical = 3.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = onBack) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                }
                Text(
                    "Settings",
                    modifier = Modifier.weight(1f),
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = ChatNuSpacing.lg),
            verticalArrangement = Arrangement.spacedBy(ChatNuSpacing.lg)
        ) {
            AccountHeader2026(user)
            SettingsSectionTitle("Appearance")
            AppearanceSection2026()

            SettingsSectionTitle("Privacy & security")
            SettingsRows2026(
                rows = listOf(
                    SettingsRowData(
                        Icons.Default.Lock,
                        "End-to-end encryption",
                        "New messages and attachments use ${DeviceE2ee.PROTOCOL_VERSION}. Plaintext is encrypted on-device before upload and private identity keys remain in Android Keystore."
                    ),
                    SettingsRowData(
                        Icons.Default.Security,
                        "Security boundary",
                        "The current envelope is not Signal Protocol/Double Ratchet and is not independently audited. Forward secrecy, post-compromise security and safety-number verification remain protocol hardening work."
                    ),
                    SettingsRowData(
                        Icons.Default.Key,
                        "Device identities",
                        "Encryption is device-bound. Historical messages are not silently rewrapped for newly added devices."
                    ),
                    SettingsRowData(
                        Icons.Default.Notifications,
                        "Private push",
                        "Push contains routing IDs only; plaintext messages, media plaintext and attachment keys are excluded."
                    )
                )
            )

            SettingsSectionTitle("Connection & app")
            SettingsRows2026(
                rows = listOf(
                    SettingsRowData(
                        Icons.Default.Cloud,
                        "Connection",
                        "Realtime: ${realtimeStatus.name.lowercase()} · ${ServerEndpoint.hostLabel()}\nCalls use authenticated signaling and WebRTC DTLS-SRTP."
                    ),
                    SettingsRowData(
                        Icons.Default.PhoneAndroid,
                        "ChatNU",
                        "Version ${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})"
                    )
                )
            )

            Button(
                onClick = { confirmLogout = true },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = RoundedCornerShape(ChatNuRadius.lg),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.errorContainer,
                    contentColor = MaterialTheme.colorScheme.onErrorContainer
                )
            ) {
                Icon(Icons.Default.Logout, contentDescription = null, modifier = Modifier.size(20.dp))
                Spacer(Modifier.size(8.dp))
                Text("Log out", fontWeight = FontWeight.Bold)
            }
            Spacer(Modifier.height(ChatNuSpacing.xl))
        }
    }

    if (confirmLogout) {
        AlertDialog(
            onDismissRequest = { confirmLogout = false },
            title = { Text("Log out of this device?") },
            text = { Text("The current server session will be revoked and protected session tokens removed from this device.") },
            confirmButton = {
                TextButton(onClick = { confirmLogout = false; onLogout() }) {
                    Text("Log out", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = { TextButton(onClick = { confirmLogout = false }) { Text("Cancel") } }
        )
    }
}

@Composable
private fun AccountHeader2026(user: User?) {
    ChatNuGlassSurface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(ChatNuRadius.xl),
        elevation = 4.dp,
        contentPadding = PaddingValues(ChatNuSpacing.lg)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            ChatNuAvatar(
                title = user?.displayName ?: "ChatNU",
                url = user?.avatarUrl,
                size = ChatNuAvatarSize.conversation
            )
            Spacer(Modifier.size(ChatNuSpacing.md))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    user?.displayName ?: "ChatNU account",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    user?.username?.let { "@$it" } ?: "Signed in",
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }
    }
}

@Composable
private fun AppearanceSection2026() {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(ChatNuRadius.xl),
        color = MaterialTheme.colorScheme.surfaceContainerLow
    ) {
        Column(modifier = Modifier.fillMaxWidth().padding(ChatNuSpacing.lg)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.Palette, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                Spacer(Modifier.size(ChatNuSpacing.sm))
                Text("Theme", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            }
            Spacer(Modifier.height(ChatNuSpacing.md))
            Row(horizontalArrangement = Arrangement.spacedBy(ChatNuSpacing.sm)) {
                ThemeMode.entries.forEach { mode ->
                    val selected = ThemeManager.themeMode == mode
                    Surface(
                        shape = RoundedCornerShape(ChatNuRadius.pill),
                        color = if (selected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceContainerHighest,
                        modifier = Modifier.weight(1f).clickable { ThemeManager.setMode(mode) }
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 11.dp),
                            horizontalArrangement = Arrangement.Center,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = when (mode) {
                                    ThemeMode.SYSTEM -> Icons.Default.SettingsBrightness
                                    ThemeMode.LIGHT -> Icons.Default.LightMode
                                    ThemeMode.DARK -> Icons.Default.DarkMode
                                },
                                contentDescription = mode.name,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(Modifier.size(5.dp))
                            Text(
                                mode.name.lowercase().replaceFirstChar { it.uppercase() },
                                style = MaterialTheme.typography.labelMedium,
                                fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium
                            )
                        }
                    }
                }
            }
            Spacer(Modifier.height(ChatNuSpacing.md))
            ThemePreset.entries.forEach { preset ->
                val selected = ThemeManager.currentPreset == preset
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { ThemeManager.setPreset(preset) }
                        .padding(vertical = 9.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(shape = CircleShape, color = preset.primary, modifier = Modifier.size(30.dp)) {}
                    Spacer(Modifier.size(ChatNuSpacing.md))
                    Text(
                        preset.title,
                        modifier = Modifier.weight(1f),
                        fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium
                    )
                    if (selected) Text("✓", color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Black)
                }
            }
        }
    }
}

@Composable
private fun SettingsSectionTitle(text: String) {
    Text(
        text,
        style = MaterialTheme.typography.labelLarge,
        color = MaterialTheme.colorScheme.primary,
        fontWeight = FontWeight.Bold,
        modifier = Modifier.padding(start = 4.dp)
    )
}

private data class SettingsRowData(
    val icon: ImageVector,
    val title: String,
    val body: String
)

@Composable
private fun SettingsRows2026(rows: List<SettingsRowData>) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(ChatNuRadius.xl),
        color = MaterialTheme.colorScheme.surfaceContainerLow
    ) {
        Column(modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp)) {
            rows.forEach { row ->
                Row(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = ChatNuSpacing.lg, vertical = 13.dp),
                    verticalAlignment = Alignment.Top
                ) {
                    Surface(
                        shape = CircleShape,
                        color = MaterialTheme.colorScheme.primary.copy(alpha = 0.10f),
                        contentColor = MaterialTheme.colorScheme.primary
                    ) {
                        Icon(row.icon, contentDescription = null, modifier = Modifier.padding(9.dp).size(19.dp))
                    }
                    Spacer(Modifier.size(ChatNuSpacing.md))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(row.title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
                        Spacer(Modifier.height(3.dp))
                        Text(row.body, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
        }
    }
}
