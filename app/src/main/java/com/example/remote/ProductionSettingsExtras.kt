package com.example.remote

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Cloud
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
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
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
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
    var securityExpanded by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .statusBarsPadding()
            .navigationBarsPadding()
    ) {
        ChatNuGlassSurface(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = ChatNuSpacing.sm, vertical = ChatNuSpacing.sm),
            shape = RoundedCornerShape(ChatNuRadius.floating),
            elevation = 7.dp,
            contentPadding = PaddingValues(horizontal = 4.dp, vertical = 3.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = onBack) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                }
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        "Settings",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        "Appearance, privacy and this device",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
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
                        "Encrypted messaging",
                        "New message text and attachments are encrypted on this device before upload."
                    ),
                    SettingsRowData(
                        Icons.Default.Notifications,
                        "Private notifications",
                        "Push payloads carry routing identifiers, not message plaintext or attachment keys."
                    )
                )
            )

            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { securityExpanded = !securityExpanded },
                shape = RoundedCornerShape(ChatNuRadius.lg),
                color = MaterialTheme.colorScheme.surfaceContainerLow
            ) {
                Column(modifier = Modifier.fillMaxWidth().padding(ChatNuSpacing.lg)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Surface(
                            shape = CircleShape,
                            color = MaterialTheme.colorScheme.tertiaryContainer,
                            contentColor = MaterialTheme.colorScheme.tertiary
                        ) {
                            Icon(Icons.Default.Security, contentDescription = null, modifier = Modifier.padding(9.dp).size(19.dp))
                        }
                        Spacer(Modifier.size(ChatNuSpacing.md))
                        Column(modifier = Modifier.weight(1f)) {
                            Text("Protocol details", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
                            Text(
                                "What the current E2EE design does and does not guarantee",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        Icon(
                            if (securityExpanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                            contentDescription = if (securityExpanded) "Collapse" else "Expand"
                        )
                    }
                    AnimatedVisibility(visible = securityExpanded) {
                        Column(modifier = Modifier.padding(top = ChatNuSpacing.md), verticalArrangement = Arrangement.spacedBy(ChatNuSpacing.sm)) {
                            SecurityDetail(
                                Icons.Default.Security,
                                "Security boundary",
                                "The current envelope is ${DeviceE2ee.PROTOCOL_VERSION}; it is not Signal Protocol/Double Ratchet and has not been independently audited. Forward secrecy, post-compromise security and safety-number verification remain protocol hardening work."
                            )
                            SecurityDetail(
                                Icons.Default.Key,
                                "Device identities",
                                "Private identity keys stay in Android Keystore. Encryption is device-bound, and historical messages are not silently rewrapped for newly added devices."
                            )
                        }
                    }
                }
            }

            SettingsSectionTitle("Connection & app")
            SettingsRows2026(
                rows = listOf(
                    SettingsRowData(
                        Icons.Default.Cloud,
                        "Server",
                        "${ServerEndpoint.hostLabel()} · ${realtimeStatus.name.lowercase()}"
                    ),
                    SettingsRowData(
                        Icons.Default.PhoneAndroid,
                        "ChatNU for Android",
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
                Column {
                    Text("Theme", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Text("Mode and accent are applied across the complete color system.", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            Spacer(Modifier.height(ChatNuSpacing.md))

            Row(horizontalArrangement = Arrangement.spacedBy(ChatNuSpacing.sm)) {
                ThemeMode.entries.forEach { mode ->
                    val selected = ThemeManager.themeMode == mode
                    val scale by animateFloatAsState(if (selected) 1f else 0.97f, label = "theme-mode-scale")
                    val container by animateColorAsState(
                        if (selected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceContainerHighest,
                        label = "theme-mode-color"
                    )
                    Surface(
                        onClick = { ThemeManager.setMode(mode) },
                        shape = RoundedCornerShape(ChatNuRadius.pill),
                        color = container,
                        contentColor = if (selected) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.weight(1f).scale(scale)
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 11.dp),
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

            Spacer(Modifier.height(ChatNuSpacing.lg))
            Text("Accent", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(Modifier.height(ChatNuSpacing.sm))
            Row(
                modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                ThemePreset.entries.forEach { preset ->
                    val selected = ThemeManager.currentPreset == preset
                    val scale by animateFloatAsState(if (selected) 1.08f else 1f, label = "preset-scale")
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier
                            .clickable { ThemeManager.setPreset(preset) }
                            .padding(vertical = 4.dp)
                    ) {
                        Surface(
                            shape = CircleShape,
                            color = preset.primary,
                            modifier = Modifier.size(42.dp).scale(scale),
                            shadowElevation = if (selected) 5.dp else 0.dp
                        ) {
                            if (selected) {
                                Icon(Icons.Default.Check, contentDescription = "Selected", tint = Color.White, modifier = Modifier.padding(10.dp))
                            }
                        }
                        Spacer(Modifier.height(6.dp))
                        Text(preset.title, style = MaterialTheme.typography.labelSmall, maxLines = 1)
                    }
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
                        color = MaterialTheme.colorScheme.primaryContainer,
                        contentColor = MaterialTheme.colorScheme.onPrimaryContainer
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

@Composable
private fun SecurityDetail(icon: ImageVector, title: String, body: String) {
    Row(verticalAlignment = Alignment.Top) {
        Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(18.dp))
        Spacer(Modifier.size(ChatNuSpacing.sm))
        Column {
            Text(title, style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.SemiBold)
            Text(body, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
