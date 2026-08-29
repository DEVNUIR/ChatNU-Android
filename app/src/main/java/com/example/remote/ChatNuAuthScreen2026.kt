package com.example.remote

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.example.ui.chatnu2026.ChatNuGlassSurface
import com.example.ui.chatnu2026.ChatNuRadius
import com.example.ui.chatnu2026.ChatNuSemantic
import com.example.ui.chatnu2026.ChatNuSpacing
import kotlinx.coroutines.launch

private enum class ChatNuAuthMode2026 { LOGIN, REGISTER }

@Composable
fun ChatNuAuthScreen2026(
    onLogin: suspend (String, String) -> AuthResult,
    onRegister: suspend (String, String, String) -> AuthResult,
    onAuthSuccess: () -> Unit,
    modifier: Modifier = Modifier
) {
    var mode by remember { mutableStateOf(ChatNuAuthMode2026.LOGIN) }
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var displayName by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }
    var loading by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var recoveryCode by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val clipboard = LocalClipboardManager.current

    fun submit() {
        if (loading) return
        val cleanUsername = username.trim().removePrefix("@")
        if (cleanUsername.isBlank() || password.isBlank()) {
            error = "Enter your username and password."
            return
        }
        if (mode == ChatNuAuthMode2026.REGISTER && displayName.trim().isBlank()) {
            error = "Enter a display name."
            return
        }
        scope.launch {
            loading = true
            error = null
            val result = if (mode == ChatNuAuthMode2026.REGISTER) {
                onRegister(cleanUsername, password, displayName.trim())
            } else {
                onLogin(cleanUsername, password)
            }
            loading = false
            when {
                !result.success -> error = result.error ?: "Could not connect to the server."
                !result.recoveryCode.isNullOrBlank() -> recoveryCode = result.recoveryCode
                else -> onAuthSuccess()
            }
        }
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(
                        MaterialTheme.colorScheme.primary.copy(alpha = 0.10f),
                        MaterialTheme.colorScheme.background,
                        MaterialTheme.colorScheme.background
                    )
                )
            )
            .statusBarsPadding()
            .navigationBarsPadding()
            .imePadding()
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = ChatNuSpacing.xxl, vertical = 34.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Surface(
                modifier = Modifier.size(70.dp),
                shape = RoundedCornerShape(ChatNuRadius.xl),
                color = MaterialTheme.colorScheme.primary,
                shadowElevation = 10.dp
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text(
                        "NU",
                        color = MaterialTheme.colorScheme.onPrimary,
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Black
                    )
                }
            }
            Spacer(Modifier.size(ChatNuSpacing.lg))
            Text("ChatNU", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Black)
            Text(
                "Private messaging, designed for your server.",
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            Spacer(Modifier.size(ChatNuSpacing.xxl))

            ChatNuGlassSurface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(ChatNuRadius.xl),
                elevation = 10.dp,
                contentPadding = PaddingValues(ChatNuSpacing.lg)
            ) {
                AnimatedContent(
                    targetState = recoveryCode != null,
                    transitionSpec = { fadeIn() togetherWith fadeOut() },
                    label = "auth-state"
                ) { showingRecovery ->
                    if (showingRecovery) {
                        Column(verticalArrangement = Arrangement.spacedBy(ChatNuSpacing.md)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Surface(
                                    modifier = Modifier.size(42.dp),
                                    shape = CircleShape,
                                    color = MaterialTheme.colorScheme.tertiaryContainer
                                ) {
                                    Box(contentAlignment = Alignment.Center) {
                                        Icon(Icons.Default.Lock, contentDescription = null, tint = MaterialTheme.colorScheme.tertiary)
                                    }
                                }
                                Spacer(Modifier.size(ChatNuSpacing.md))
                                Column(modifier = Modifier.weight(1f)) {
                                    Text("Save your recovery code", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                                    Text("This is shown once.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                                }
                            }
                            Surface(
                                modifier = Modifier.fillMaxWidth(),
                                shape = RoundedCornerShape(ChatNuRadius.lg),
                                color = MaterialTheme.colorScheme.secondaryContainer
                            ) {
                                Row(
                                    modifier = Modifier.padding(ChatNuSpacing.lg),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        recoveryCode.orEmpty(),
                                        modifier = Modifier.weight(1f),
                                        style = MaterialTheme.typography.titleMedium,
                                        fontWeight = FontWeight.Bold
                                    )
                                    IconButton(onClick = { clipboard.setText(AnnotatedString(recoveryCode.orEmpty())) }) {
                                        Icon(Icons.Default.ContentCopy, contentDescription = "Copy recovery code")
                                    }
                                }
                            }
                            Text(
                                "Keep it somewhere you can still reach if this phone is lost.",
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                style = MaterialTheme.typography.bodySmall
                            )
                            Button(onClick = onAuthSuccess, modifier = Modifier.fillMaxWidth()) {
                                Text("I saved it")
                            }
                        }
                    } else {
                        Column(verticalArrangement = Arrangement.spacedBy(ChatNuSpacing.md)) {
                            Surface(
                                modifier = Modifier.fillMaxWidth(),
                                shape = RoundedCornerShape(ChatNuRadius.pill),
                                color = MaterialTheme.colorScheme.surfaceContainerHighest.copy(alpha = 0.70f)
                            ) {
                                Row(modifier = Modifier.padding(4.dp)) {
                                    ChatNuAuthMode2026.entries.forEach { item ->
                                        val selected = item == mode
                                        Surface(
                                            modifier = Modifier.weight(1f),
                                            onClick = {
                                                mode = item
                                                error = null
                                            },
                                            shape = RoundedCornerShape(ChatNuRadius.pill),
                                            color = if (selected) MaterialTheme.colorScheme.primaryContainer else androidx.compose.ui.graphics.Color.Transparent
                                        ) {
                                            Text(
                                                if (item == ChatNuAuthMode2026.LOGIN) "Log in" else "Create account",
                                                modifier = Modifier.padding(vertical = 10.dp),
                                                textAlign = TextAlign.Center,
                                                fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium,
                                                color = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                                            )
                                        }
                                    }
                                }
                            }

                            if (mode == ChatNuAuthMode2026.REGISTER) {
                                OutlinedTextField(
                                    value = displayName,
                                    onValueChange = { displayName = it; error = null },
                                    label = { Text("Display name") },
                                    singleLine = true,
                                    shape = RoundedCornerShape(ChatNuRadius.lg),
                                    modifier = Modifier.fillMaxWidth()
                                )
                            }
                            OutlinedTextField(
                                value = username,
                                onValueChange = { username = it; error = null },
                                label = { Text("Username") },
                                prefix = { Text("@") },
                                singleLine = true,
                                shape = RoundedCornerShape(ChatNuRadius.lg),
                                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next),
                                modifier = Modifier.fillMaxWidth()
                            )
                            OutlinedTextField(
                                value = password,
                                onValueChange = { password = it; error = null },
                                label = { Text("Password") },
                                singleLine = true,
                                visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                                trailingIcon = {
                                    IconButton(onClick = { passwordVisible = !passwordVisible }) {
                                        Icon(
                                            if (passwordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                            contentDescription = if (passwordVisible) "Hide password" else "Show password"
                                        )
                                    }
                                },
                                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                                keyboardActions = KeyboardActions(onDone = { submit() }),
                                shape = RoundedCornerShape(ChatNuRadius.lg),
                                modifier = Modifier.fillMaxWidth()
                            )
                            error?.let {
                                Text(
                                    it,
                                    color = ChatNuSemantic.Error,
                                    style = MaterialTheme.typography.bodySmall
                                )
                            }
                            Button(
                                onClick = ::submit,
                                enabled = !loading,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                if (loading) {
                                    CircularProgressIndicator(
                                        modifier = Modifier.size(18.dp),
                                        strokeWidth = 2.dp,
                                        color = MaterialTheme.colorScheme.onPrimary
                                    )
                                    Spacer(Modifier.size(8.dp))
                                }
                                Text(if (mode == ChatNuAuthMode2026.LOGIN) "Log in" else "Create account", fontWeight = FontWeight.Bold)
                            }
                            TextButton(
                                onClick = {
                                    mode = if (mode == ChatNuAuthMode2026.LOGIN) ChatNuAuthMode2026.REGISTER else ChatNuAuthMode2026.LOGIN
                                    error = null
                                },
                                modifier = Modifier.align(Alignment.CenterHorizontally)
                            ) {
                                Text(if (mode == ChatNuAuthMode2026.LOGIN) "New here? Create an account" else "Already have an account? Log in")
                            }
                        }
                    }
                }
            }
        }
    }
}
