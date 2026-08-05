package com.devnu.chatnu.feature.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.ArrowBackIosNew
import androidx.compose.material.icons.rounded.Backup
import androidx.compose.material.icons.rounded.ColorLens
import androidx.compose.material.icons.rounded.Fingerprint
import androidx.compose.material.icons.rounded.Key
import androidx.compose.material.icons.rounded.Language
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material.icons.rounded.Notifications
import androidx.compose.material.icons.rounded.Person
import androidx.compose.material.icons.rounded.Storage
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.devnu.chatnu.ui.components.AmbientBackdrop
import com.devnu.chatnu.ui.components.GlassSurface
import com.devnu.chatnu.ui.components.GradientAvatar
import com.devnu.chatnu.ui.theme.ElectricViolet

@Composable
fun SettingsScreen(onBack: () -> Unit) {
    var notifications by remember { mutableStateOf(true) }
    var previews by remember { mutableStateOf(false) }
    AmbientBackdrop {
        LazyColumn(Modifier.fillMaxSize(), contentPadding = androidx.compose.foundation.layout.PaddingValues(top = 48.dp, bottom = 40.dp)) {
            item {
                Row(Modifier.fillMaxWidth().padding(horizontal = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    IconButton(onClick = onBack) { Icon(Icons.Rounded.ArrowBackIosNew, "Back") }
                    Text("Settings", style = MaterialTheme.typography.headlineMedium)
                }
                ProfileCard()
                SectionTitle("Identity & security")
                SettingsGroup {
                    SettingsRow(Icons.Rounded.Fingerprint, "Identity fingerprint", "7F8B · 9C0D · 1E2F · 3A4B")
                    SettingsRow(Icons.Rounded.Key, "Linked devices", "2 active devices")
                    SettingsRow(Icons.Rounded.Backup, "Recovery phrase", "Stored offline")
                    SettingsRow(Icons.Rounded.Lock, "App lock", "Face or fingerprint")
                }
                SectionTitle("Experience")
                SettingsGroup {
                    ToggleRow(Icons.Rounded.Notifications, "Notifications", notifications) { notifications = it }
                    ToggleRow(Icons.Rounded.Person, "Message previews", previews) { previews = it }
                    SettingsRow(Icons.Rounded.ColorLens, "Appearance", "Midnight glass")
                    SettingsRow(Icons.Rounded.Language, "Language", "English")
                }
                SectionTitle("Data")
                SettingsGroup {
                    SettingsRow(Icons.Rounded.Storage, "Local storage", "468 MB encrypted")
                }
            }
        }
    }
}

@Composable
private fun ProfileCard() {
    GlassSurface(Modifier.padding(20.dp).fillMaxWidth(), RoundedCornerShape(28.dp)) {
        Row(Modifier.padding(18.dp), verticalAlignment = Alignment.CenterVertically) {
            GradientAvatar("Amir", 4, Modifier.size(62.dp), true)
            Column(Modifier.weight(1f).padding(horizontal = 14.dp)) {
                Text("Amir", style = MaterialTheme.typography.titleLarge)
                Text("@amir.devnu", color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text("Identity stored on this device", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary)
            }
            Box(Modifier.size(38.dp).clip(CircleShape).background(ElectricViolet.copy(alpha = .18f)), contentAlignment = Alignment.Center) {
                Icon(Icons.Rounded.Person, null, tint = ElectricViolet)
            }
        }
    }
}

@Composable
private fun SectionTitle(text: String) {
    Text(text, style = MaterialTheme.typography.titleMedium, modifier = Modifier.padding(horizontal = 20.dp, vertical = 10.dp), color = MaterialTheme.colorScheme.onSurfaceVariant)
}

@Composable
private fun SettingsGroup(content: @Composable ColumnScope.() -> Unit) {
    GlassSurface(Modifier.padding(horizontal = 20.dp).fillMaxWidth(), RoundedCornerShape(24.dp)) {
        Column(Modifier.padding(vertical = 6.dp), content = content)
    }
}

@Composable
private fun SettingsRow(icon: ImageVector, title: String, value: String) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 13.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(38.dp).clip(CircleShape).background(Color.White.copy(alpha = .06f)), contentAlignment = Alignment.Center) { Icon(icon, null, tint = MaterialTheme.colorScheme.primary) }
        Column(Modifier.weight(1f).padding(horizontal = 12.dp)) {
            Text(title, style = MaterialTheme.typography.titleMedium)
            Text(value, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun ToggleRow(icon: ImageVector, title: String, checked: Boolean, onCheckedChange: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(38.dp).clip(CircleShape).background(Color.White.copy(alpha = .06f)), contentAlignment = Alignment.Center) { Icon(icon, null, tint = MaterialTheme.colorScheme.primary) }
        Text(title, style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f).padding(horizontal = 12.dp))
        Switch(checked = checked, onCheckedChange = onCheckedChange)
    }
}
