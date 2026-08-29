package com.example.remote

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
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
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.BuildConfig
import com.example.crypto.DeviceE2ee
import com.example.model.User
import com.example.ui.theme.ThemeManager
import com.example.ui.theme.ThemeMode
import com.example.ui.theme.ThemePreset

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EnhancedProductionSettingsScreen(
    user: User?,
    realtimeStatus: RealtimeStatus,
    onBack: () -> Unit,
    onLogout: () -> Unit
) {
    var confirmLogout by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                title = { Text("Settings", fontWeight = FontWeight.Bold) }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            SettingsCard(
                icon = { Icon(Icons.Default.PhoneAndroid, contentDescription = null) },
                title = user?.displayName ?: "ChatNU account",
                body = user?.username?.let { "@$it" } ?: "Signed in"
            )

            ThemeSettingsCard()

            SettingsCard(
                icon = { Icon(Icons.Default.Lock, contentDescription = null) },
                title = "End-to-end encryption",
                body = "New messages and attachments use ${DeviceE2ee.PROTOCOL_VERSION}. Plaintext is encrypted on the phone before upload and private identity keys stay in Android Keystore."
            )

            SettingsCard(
                icon = { Icon(Icons.Default.Security, contentDescription = null) },
                title = "Security boundary",
                body = "The current envelope protects message content from passive network sniffing and a database dump, but it is not Signal Protocol/Double Ratchet and is not independently audited. Forward secrecy, post-compromise security and safety-number verification are P0 work."
            )

            SettingsCard(
                icon = { Icon(Icons.Default.Key, contentDescription = null) },
                title = "Device identities",
                body = "Encryption is device-bound. Historical messages are not silently rewrapped for newly-added devices. Unexpected verified identity changes will become a blocking warning in the hardened protocol milestone."
            )

            SettingsCard(
                icon = { Icon(Icons.Default.Notifications, contentDescription = null) },
                title = "Private push",
                body = "Push contains routing IDs only. Message plaintext, media plaintext and attachment keys are not put in notification payloads."
            )

            SettingsCard(
                icon = { Icon(Icons.Default.Cloud, contentDescription = null) },
                title = "Connection",
                body = "Realtime: ${realtimeStatus.name.lowercase()}\nServer: ${ServerEndpoint.hostLabel()}\nCalls use authenticated signaling plus WebRTC DTLS-SRTP. TURN relays encrypted media but can still observe network metadata."
            )

            SettingsCard(
                icon = { Icon(Icons.Default.PhoneAndroid, contentDescription = null) },
                title = "App",
                body = "ChatNU ${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})"
            )

            Spacer(Modifier.height(4.dp))
            Button(
                onClick = { confirmLogout = true },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.errorContainer,
                    contentColor = MaterialTheme.colorScheme.onErrorContainer
                )
            ) {
                Icon(Icons.Default.Logout, contentDescription = null, modifier = Modifier.size(20.dp))
                Spacer(Modifier.size(8.dp))
                Text("Log out", fontWeight = FontWeight.Bold)
            }
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
private fun ThemeSettingsCard() {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainer)
    ) {
        Column(modifier = Modifier.fillMaxWidth().padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Icon(Icons.Default.Palette, contentDescription = null)
                Column {
                    Text("Appearance", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Text("Instant theme switching", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            Spacer(Modifier.height(14.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                ThemeMode.entries.forEach { mode ->
                    val selected = ThemeManager.themeMode == mode
                    Surface(
                        shape = RoundedCornerShape(14.dp),
                        color = if (selected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceContainerHighest,
                        modifier = Modifier.weight(1f).clickable { ThemeManager.setMode(mode) }
                    ) {
                        Column(
                            modifier = Modifier.padding(vertical = 11.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(
                                imageVector = when (mode) {
                                    ThemeMode.SYSTEM -> Icons.Default.SettingsBrightness
                                    ThemeMode.LIGHT -> Icons.Default.LightMode
                                    ThemeMode.DARK -> Icons.Default.DarkMode
                                },
                                contentDescription = null,
                                modifier = Modifier.size(19.dp)
                            )
                            Text(mode.name.lowercase().replaceFirstChar { it.uppercase() }, style = MaterialTheme.typography.labelSmall)
                        }
                    }
                }
            }
            Spacer(Modifier.height(14.dp))
            ThemePreset.entries.forEach { preset ->
                val selected = ThemeManager.currentPreset == preset
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { ThemeManager.setPreset(preset) }
                        .padding(vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(shape = CircleShape, color = preset.primary, modifier = Modifier.size(28.dp)) {}
                    Spacer(Modifier.size(12.dp))
                    Text(preset.title, modifier = Modifier.weight(1f), fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal)
                    if (selected) Text("✓", color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

@Composable
private fun SettingsCard(
    icon: @Composable () -> Unit,
    title: String,
    body: String
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainer)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(16.dp),
            verticalAlignment = Alignment.Top,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            icon()
            Column(modifier = Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Spacer(Modifier.height(4.dp))
                Text(body, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}
