package com.example.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.data.AccountManager
import com.example.ui.theme.ChatNuEncryptedGreen
import com.example.ui.theme.ThemeManager
import com.example.ui.theme.ThemePreset
import com.example.ui.theme.isAppInDarkTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileEditorDialog(
    onDismiss: () -> Unit
) {
    val activeAccount = AccountManager.activeAccount
    val currentLang by AccountManager.selectedLanguage.collectAsState()
    val isDark = isAppInDarkTheme()

    var displayName by remember(activeAccount) { mutableStateOf(activeAccount.displayName) }
    var username by remember(activeAccount) { mutableStateOf(activeAccount.username) }
    var bio by remember(activeAccount) { mutableStateOf(activeAccount.bio) }
    var avatarUrl by remember(activeAccount) { mutableStateOf(activeAccount.avatarUrl) }
    var relayServerUrl by remember(activeAccount) { mutableStateOf(activeAccount.relayServerUrl) }
    var selectedLanguage by remember { mutableStateOf(currentLang) }
    var savedMessage by remember { mutableStateOf(false) }

    val presetAvatars = listOf(
        "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150",
        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
        "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150",
        "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150",
        "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150",
        "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=150"
    )

    val availableLanguages = listOf(
        "English",
        "Persian (فارسی)",
        "Español",
        "Deutsch",
        "Français"
    )

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Default.ManageAccounts,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.width(10.dp))
                Text("Edit Profile & Account Preferences", fontWeight = FontWeight.Bold)
            }
        },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                // Avatar Preview & Presets
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                    Box {
                        Surface(
                            shape = CircleShape,
                            modifier = Modifier.size(76.dp),
                            border = BorderStroke(2.dp, MaterialTheme.colorScheme.primary)
                        ) {
                            AsyncImage(
                                model = avatarUrl,
                                contentDescription = "Avatar Preview",
                                modifier = Modifier.fillMaxSize()
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Choose Avatar Preset",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(modifier = Modifier.height(6.dp))

                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        items(presetAvatars) { preset ->
                            val isSelected = preset == avatarUrl
                            Surface(
                                shape = CircleShape,
                                border = if (isSelected) BorderStroke(2.dp, MaterialTheme.colorScheme.primary) else null,
                                modifier = Modifier
                                    .size(42.dp)
                                    .clickable { avatarUrl = preset }
                            ) {
                                AsyncImage(
                                    model = preset,
                                    contentDescription = null,
                                    modifier = Modifier.fillMaxSize()
                                )
                            }
                        }
                    }
                }

                Divider()

                // Display Name
                OutlinedTextField(
                    value = displayName,
                    onValueChange = { displayName = it },
                    label = { Text("Display Name") },
                    leadingIcon = { Icon(Icons.Default.Badge, contentDescription = null) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp)
                )

                // Username (@username)
                OutlinedTextField(
                    value = username,
                    onValueChange = { username = it },
                    label = { Text("Username (@handle)") },
                    leadingIcon = { Icon(Icons.Default.AlternateEmail, contentDescription = null) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp)
                )

                // Bio / Status
                OutlinedTextField(
                    value = bio,
                    onValueChange = { bio = it },
                    label = { Text("Bio / Status Message") },
                    leadingIcon = { Icon(Icons.Default.Info, contentDescription = null) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp)
                )

                // Relay Server URL
                OutlinedTextField(
                    value = relayServerUrl,
                    onValueChange = { relayServerUrl = it },
                    label = { Text("E2EE Relay Node Server URL") },
                    leadingIcon = { Icon(Icons.Default.Dns, contentDescription = null) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp)
                )

                Divider()

                // Language Selector
                Text(
                    text = "Application Language",
                    style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold),
                    color = MaterialTheme.colorScheme.primary
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    availableLanguages.take(3).forEach { lang ->
                        val isSelected = selectedLanguage == lang
                        FilterChip(
                            selected = isSelected,
                            onClick = { selectedLanguage = lang },
                            label = { Text(lang, style = MaterialTheme.typography.labelSmall) },
                            leadingIcon = { Icon(Icons.Default.Language, contentDescription = null, modifier = Modifier.size(14.dp)) }
                        )
                    }
                }
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    availableLanguages.drop(3).forEach { lang ->
                        val isSelected = selectedLanguage == lang
                        FilterChip(
                            selected = isSelected,
                            onClick = { selectedLanguage = lang },
                            label = { Text(lang, style = MaterialTheme.typography.labelSmall) },
                            leadingIcon = { Icon(Icons.Default.Language, contentDescription = null, modifier = Modifier.size(14.dp)) }
                        )
                    }
                }

                Divider()

                // Theme & Appearance Shortcut
                Text(
                    text = "Theme Accent Preset",
                    style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold),
                    color = MaterialTheme.colorScheme.primary
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    ThemePreset.values().forEach { preset ->
                        val isSelected = ThemeManager.currentPreset == preset
                        Surface(
                            shape = CircleShape,
                            color = preset.primary,
                            border = if (isSelected) BorderStroke(3.dp, MaterialTheme.colorScheme.onBackground) else null,
                            modifier = Modifier
                                .size(36.dp)
                                .clickable { ThemeManager.currentPreset = preset }
                        ) {
                            if (isSelected) {
                                Box(contentAlignment = Alignment.Center) {
                                    Icon(Icons.Default.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
                                }
                            }
                        }
                    }
                }

                AnimatedVisibility(visible = savedMessage) {
                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = ChatNuEncryptedGreen.copy(alpha = 0.2f),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier.padding(10.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(Icons.Default.CheckCircle, contentDescription = null, tint = ChatNuEncryptedGreen)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Profile updated successfully!",
                                style = MaterialTheme.typography.labelMedium.copy(color = ChatNuEncryptedGreen, fontWeight = FontWeight.Bold)
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    AccountManager.updateActiveAccountProfile(
                        displayName = displayName,
                        username = username,
                        bio = bio,
                        avatarUrl = avatarUrl,
                        relayServerUrl = relayServerUrl
                    )
                    AccountManager.setLanguage(selectedLanguage)
                    savedMessage = true
                    onDismiss()
                }
            ) {
                Icon(Icons.Default.Save, contentDescription = null)
                Spacer(modifier = Modifier.width(6.dp))
                Text("Save Profile")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}
