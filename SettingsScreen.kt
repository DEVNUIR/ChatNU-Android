package com.example.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.data.AccountManager
import com.example.data.MockBackend
import com.example.model.User
import com.example.ui.components.MultiAccountRelaySheet
import com.example.ui.components.ProfileEditorDialog
import com.example.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    user: User?,
    onBackClick: () -> Unit,
    onLogoutClick: () -> Unit
) {
    val isDark = isAppInDarkTheme()
    val activeAccount = AccountManager.activeAccount

    // Interactive Toggles
    var showProfileEditorDialog by remember { mutableStateOf(false) }
    var showMultiAccountSheet by remember { mutableStateOf(false) }
    var isAppLockEnabled by remember { mutableStateOf(true) }
    var isScreenshotBlocked by remember { mutableStateOf(true) }
    var isReadReceiptsEnabled by remember { mutableStateOf(true) }
    var autoClearCacheDays by remember { mutableStateOf(7) }
    var showQrVerificationModal by remember { mutableStateOf(false) }
    var showRekeySuccessSnackbar by remember { mutableStateOf(false) }
    var cacheClearedMessage by remember { mutableStateOf(false) }

    val glassCardBg = if (isDark) Color(0x1AFFFFFF) else Color(0x0D000000)
    val glassCardBorder = if (isDark) Color(0x26FFFFFF) else Color(0x1F000000)

    Scaffold(
        topBar = {
            TopAppBar(
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                title = {
                    Column {
                        Text(
                            text = "Settings & Security Center",
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Black)
                        )
                        Text(
                            text = "api.devnu.ir • E2EE Security Center",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                },
                actions = {
                    IconButton(onClick = {
                        ThemeManager.themeMode = when (ThemeManager.themeMode) {
                            ThemeMode.DARK -> ThemeMode.LIGHT
                            ThemeMode.LIGHT -> ThemeMode.DARK
                            ThemeMode.SYSTEM -> if (isDark) ThemeMode.LIGHT else ThemeMode.DARK
                        }
                    }) {
                        Icon(
                            imageVector = if (isDark) Icons.Default.LightMode else Icons.Default.DarkMode,
                            contentDescription = "Toggle Light/Dark Theme",
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            )
        }
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .padding(innerPadding)
                .fillMaxSize(),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // 1. Futuristic Profile & Signal Security Fingerprint Header
            item {
                Surface(
                    shape = RoundedCornerShape(24.dp),
                    color = glassCardBg,
                    border = BorderStroke(1.dp, glassCardBorder),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(18.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box {
                                Surface(
                                    shape = CircleShape,
                                    modifier = Modifier.size(68.dp),
                                    border = BorderStroke(2.dp, MaterialTheme.colorScheme.primary)
                                ) {
                                    AsyncImage(
                                        model = user?.avatarUrl,
                                        contentDescription = user?.displayName,
                                        modifier = Modifier.fillMaxSize()
                                    )
                                }
                                Box(
                                    modifier = Modifier
                                        .size(16.dp)
                                        .clip(CircleShape)
                                        .background(ChatNuEncryptedGreen)
                                        .align(Alignment.BottomEnd)
                                )
                            }

                            Spacer(modifier = Modifier.width(16.dp))

                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = activeAccount.displayName,
                                    style = MaterialTheme.typography.titleLarge.copy(
                                        fontWeight = FontWeight.Bold,
                                        letterSpacing = (-0.5).sp
                                    )
                                )
                                Text(
                                    text = "@${activeAccount.username}",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.primary,
                                    fontWeight = FontWeight.SemiBold
                                )
                                Text(
                                    text = activeAccount.bio,
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )

                                Spacer(modifier = Modifier.height(6.dp))

                                Button(
                                    onClick = { showProfileEditorDialog = true },
                                    shape = RoundedCornerShape(10.dp),
                                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                                    modifier = Modifier.height(32.dp)
                                ) {
                                    Icon(Icons.Default.Edit, contentDescription = null, modifier = Modifier.size(14.dp))
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text("Edit Profile & Bio", style = MaterialTheme.typography.labelSmall)
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(14.dp))

                        Surface(
                            shape = RoundedCornerShape(14.dp),
                            color = if (isDark) Color(0x26000000) else Color(0x0A000000),
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { showQrVerificationModal = true }
                        ) {
                            Row(
                                modifier = Modifier.padding(12.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column {
                                    Text(
                                        text = "Safety Key Fingerprint",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                    Text(
                                        text = user?.identityKeyFingerprint ?: "0x8F2D...9A4B",
                                        style = MaterialTheme.typography.bodySmall.copy(fontWeight = FontWeight.Medium)
                                    )
                                }
                                Icon(
                                    imageVector = Icons.Default.QrCodeScanner,
                                    contentDescription = "QR Verify",
                                    tint = MaterialTheme.colorScheme.primary
                                )
                            }
                        }
                    }
                }
            }

            // 2. Theme & Appearance Studio
            item {
                Text(
                    text = "Theme & Color Customization",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                    color = MaterialTheme.colorScheme.primary
                )
            }

            item {
                Surface(
                    shape = RoundedCornerShape(20.dp),
                    color = glassCardBg,
                    border = BorderStroke(1.dp, glassCardBorder),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text(
                            text = "Appearance Mode",
                            style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.SemiBold)
                        )
                        Spacer(modifier = Modifier.height(10.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            ThemeMode.values().forEach { mode ->
                                val isSelected = ThemeManager.themeMode == mode
                                FilterChip(
                                    selected = isSelected,
                                    onClick = { ThemeManager.themeMode = mode },
                                    leadingIcon = {
                                        Icon(
                                            imageVector = when (mode) {
                                                ThemeMode.DARK -> Icons.Default.DarkMode
                                                ThemeMode.LIGHT -> Icons.Default.LightMode
                                                ThemeMode.SYSTEM -> Icons.Default.SettingsSuggest
                                            },
                                            contentDescription = null,
                                            modifier = Modifier.size(16.dp)
                                        )
                                    },
                                    label = {
                                        Text(
                                            when (mode) {
                                                ThemeMode.DARK -> "Dark"
                                                ThemeMode.LIGHT -> "Light"
                                                ThemeMode.SYSTEM -> "System"
                                            }
                                        )
                                    },
                                    modifier = Modifier.weight(1f)
                                )
                            }
                        }

                        Divider(modifier = Modifier.padding(vertical = 14.dp))

                        Text(
                            text = "Glass Accent Palette Preset",
                            style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.SemiBold)
                        )
                        Spacer(modifier = Modifier.height(12.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            ThemePreset.values().forEach { preset ->
                                val isSelected = ThemeManager.currentPreset == preset
                                Column(
                                    horizontalAlignment = Alignment.CenterHorizontally,
                                    modifier = Modifier.clickable {
                                        ThemeManager.currentPreset = preset
                                    }
                                ) {
                                    Surface(
                                        shape = CircleShape,
                                        color = preset.primary,
                                        border = if (isSelected) BorderStroke(3.dp, Color.White) else null,
                                        shadowElevation = if (isSelected) 6.dp else 2.dp,
                                        modifier = Modifier.size(44.dp)
                                    ) {
                                        if (isSelected) {
                                            Box(contentAlignment = Alignment.Center) {
                                                Icon(
                                                    imageVector = Icons.Default.Check,
                                                    contentDescription = "Selected",
                                                    tint = Color.White,
                                                    modifier = Modifier.size(20.dp)
                                                )
                                            }
                                        }
                                    }
                                    Spacer(modifier = Modifier.height(6.dp))
                                    Text(
                                        text = preset.title.split(" ").last(),
                                        style = MaterialTheme.typography.labelSmall,
                                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                                    )
                                }
                            }
                        }
                    }
                }
            }

            // 2.5 Multi-Account & Decentralized Relays (Up to 10 accounts)
            item {
                Text(
                    text = "Decentralized Relays & Multi-Account",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                    color = MaterialTheme.colorScheme.primary
                )
            }

            item {
                val accounts by AccountManager.accounts.collectAsState()
                val activeAccount = AccountManager.activeAccount

                Surface(
                    shape = RoundedCornerShape(20.dp),
                    color = glassCardBg,
                    border = BorderStroke(1.dp, glassCardBorder),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text(
                                    text = "Active Account: @${activeAccount.username}",
                                    style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold)
                                )
                                Text(
                                    text = "Relay: ${activeAccount.relayServerUrl} (${activeAccount.relayLatencyMs}ms)",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.primary
                                )
                            }
                            Surface(
                                shape = CircleShape,
                                color = ChatNuEncryptedGreen.copy(alpha = 0.2f)
                            ) {
                                Text(
                                    text = "${accounts.size}/10 Accounts",
                                    color = ChatNuEncryptedGreen,
                                    style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        Button(
                            onClick = { showMultiAccountSheet = true },
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Icon(Icons.Default.SwitchAccount, contentDescription = null)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Manage Accounts & Custom Relay Nodes", fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }

            // 3. Privacy & Biometric Guard Vault
            item {
                Text(
                    text = "Biometric & Privacy Protection",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                    color = MaterialTheme.colorScheme.primary
                )
            }

            item {
                Surface(
                    shape = RoundedCornerShape(20.dp),
                    color = glassCardBg,
                    border = BorderStroke(1.dp, glassCardBorder),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.Fingerprint, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                                Spacer(modifier = Modifier.width(12.dp))
                                Column {
                                    Text("Biometric App Lock", fontWeight = FontWeight.SemiBold)
                                    Text("Require Face ID / Fingerprint to open ChatNU", style = MaterialTheme.typography.labelSmall)
                                }
                            }
                            Switch(
                                checked = isAppLockEnabled,
                                onCheckedChange = { isAppLockEnabled = it }
                            )
                        }

                        Divider(modifier = Modifier.padding(vertical = 12.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.Security, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                                Spacer(modifier = Modifier.width(12.dp))
                                Column {
                                    Text("Block Screenshots & Recents", fontWeight = FontWeight.SemiBold)
                                    Text("Prevent screen recording and blur task switcher", style = MaterialTheme.typography.labelSmall)
                                }
                            }
                            Switch(
                                checked = isScreenshotBlocked,
                                onCheckedChange = { isScreenshotBlocked = it }
                            )
                        }

                        Divider(modifier = Modifier.padding(vertical = 12.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.DoneAll, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                                Spacer(modifier = Modifier.width(12.dp))
                                Column {
                                    Text("Read Receipts & Online Badge", fontWeight = FontWeight.SemiBold)
                                    Text("Share double blue tick when messages are read", style = MaterialTheme.typography.labelSmall)
                                }
                            }
                            Switch(
                                checked = isReadReceiptsEnabled,
                                onCheckedChange = { isReadReceiptsEnabled = it }
                            )
                        }
                    }
                }
            }

            // 4. Storage & Glass Cache Cleaner
            item {
                Text(
                    text = "Storage & Glass Cache Center",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                    color = MaterialTheme.colorScheme.primary
                )
            }

            item {
                Surface(
                    shape = RoundedCornerShape(20.dp),
                    color = glassCardBg,
                    border = BorderStroke(1.dp, glassCardBorder),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text("Media & Glass Cache Size", fontWeight = FontWeight.Bold)
                                Text("142.8 MB stored locally", style = MaterialTheme.typography.bodySmall)
                            }
                            Button(
                                onClick = { cacheClearedMessage = true },
                                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f), contentColor = MaterialTheme.colorScheme.primary),
                                shape = RoundedCornerShape(12.dp)
                            ) {
                                Text("Clear Cache")
                            }
                        }

                        AnimatedVisibility(visible = cacheClearedMessage) {
                            Surface(
                                shape = RoundedCornerShape(10.dp),
                                color = ChatNuEncryptedGreen.copy(alpha = 0.15f),
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(top = 10.dp)
                            ) {
                                Text(
                                    text = "✓ Glass Cache purged successfully! 0 MB remaining.",
                                    style = MaterialTheme.typography.labelSmall.copy(color = ChatNuEncryptedGreen),
                                    modifier = Modifier.padding(10.dp)
                                )
                            }
                        }
                    }
                }
            }

            // 5. Active E2EE Sessions & Node Infrastructure
            item {
                Text(
                    text = "Active Encrypted Sessions & Nodes",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                    color = MaterialTheme.colorScheme.primary
                )
            }

            item {
                Surface(
                    shape = RoundedCornerShape(20.dp),
                    color = glassCardBg,
                    border = BorderStroke(1.dp, glassCardBorder),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        MockBackend.mockActiveSessions.forEach { session ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 6.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(Icons.Default.Devices, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                                    Spacer(modifier = Modifier.width(12.dp))
                                    Column {
                                        Text(text = session.deviceName, fontWeight = FontWeight.Bold)
                                        Text(text = session.locationRegion, style = MaterialTheme.typography.labelSmall)
                                    }
                                }
                                if (session.isCurrentDevice) {
                                    Surface(
                                        shape = CircleShape,
                                        color = ChatNuEncryptedGreen.copy(alpha = 0.2f)
                                    ) {
                                        Text(
                                            text = "This Device",
                                            color = ChatNuEncryptedGreen,
                                            style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                                        )
                                    }
                                }
                            }
                        }

                        Divider(modifier = Modifier.padding(vertical = 12.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text("devnu.ir REST Node", style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold))
                                Text("https://api.devnu.ir (18ms)", style = MaterialTheme.typography.labelSmall)
                            }
                            Button(
                                onClick = { showRekeySuccessSnackbar = true },
                                shape = RoundedCornerShape(10.dp)
                            ) {
                                Text("Rekey Signal Engine")
                            }
                        }

                        AnimatedVisibility(visible = showRekeySuccessSnackbar) {
                            Surface(
                                shape = RoundedCornerShape(10.dp),
                                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.15f),
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(top = 10.dp)
                            ) {
                                Text(
                                    text = "🔑 Double Ratchet prekeys regenerated and synced with devnu.ir!",
                                    style = MaterialTheme.typography.labelSmall.copy(color = MaterialTheme.colorScheme.primary),
                                    modifier = Modifier.padding(10.dp)
                                )
                            }
                        }
                    }
                }
            }

            // 6. Destructive Session Logout Button
            item {
                Button(
                    onClick = onLogoutClick,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = ChatNuDestructiveRed),
                    shape = RoundedCornerShape(16.dp)
                ) {
                    Icon(Icons.Default.Logout, contentDescription = "Logout")
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Logout & Destroy Local Encryption Keys", fontWeight = FontWeight.Bold)
                }
            }
        }
    }

    // Profile Editor Dialog Modal
    if (showProfileEditorDialog) {
        ProfileEditorDialog(
            onDismiss = { showProfileEditorDialog = false }
        )
    }

    // Multi-Account & Relay Sheet Modal
    if (showMultiAccountSheet) {
        MultiAccountRelaySheet(
            onDismiss = { showMultiAccountSheet = false },
            onAccountSwitched = { newAcc ->
                showMultiAccountSheet = false
            }
        )
    }

    // QR Verification Modal
    if (showQrVerificationModal) {
        AlertDialog(
            onDismissRequest = { showQrVerificationModal = false },
            title = { Text("E2EE Safety Number Verification", fontWeight = FontWeight.Bold) },
            text = {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(
                        imageVector = Icons.Default.QrCode,
                        contentDescription = "QR Code",
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(120.dp)
                    )
                    Text(
                        text = "Scan this safety number with your contact's camera to verify end-to-end security on devnu.ir.",
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            },
            confirmButton = {
                Button(onClick = { showQrVerificationModal = false }) {
                    Text("Done")
                }
            }
        )
    }
}
