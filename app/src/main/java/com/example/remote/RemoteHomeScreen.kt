package com.example.remote

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddComment
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.OutlinedTextField
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
import androidx.compose.ui.unit.dp
import com.example.model.Conversation
import com.example.ui.screens.HomeScreen
import kotlinx.coroutines.launch

@Composable
fun RemoteHomeScreen(
    conversations: List<Conversation>,
    onSelectConversation: (Conversation) -> Unit,
    onCreateGroup: (String, String) -> Unit,
    onTogglePinConversation: (String) -> Unit,
    onOpenSettings: () -> Unit,
    onSimulateCall: () -> Unit,
    onOpenDirect: suspend (String) -> Result<Unit>
) {
    var showDirectDialog by remember { mutableStateOf(false) }
    var username by remember { mutableStateOf("") }
    var error by remember { mutableStateOf<String?>(null) }
    var loading by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    Box(modifier = Modifier.fillMaxSize()) {
        HomeScreen(
            conversations = conversations,
            onSelectConversation = onSelectConversation,
            onCreateGroup = onCreateGroup,
            onTogglePinConversation = onTogglePinConversation,
            onOpenSettings = onOpenSettings,
            onSimulateCall = onSimulateCall
        )

        ExtendedFloatingActionButton(
            onClick = { showDirectDialog = true },
            icon = { androidx.compose.material3.Icon(Icons.Default.AddComment, contentDescription = null) },
            text = { Text("New chat") },
            modifier = Modifier.align(Alignment.BottomStart).padding(18.dp)
        )
    }

    if (showDirectDialog) {
        AlertDialog(
            onDismissRequest = { if (!loading) showDirectDialog = false },
            title = { Text("Start direct chat") },
            text = {
                androidx.compose.foundation.layout.Column {
                    Text("نام کاربری طرف را وارد کن.")
                    OutlinedTextField(
                        value = username,
                        onValueChange = { username = it; error = null },
                        label = { Text("@username") },
                        singleLine = true
                    )
                    error?.let { Text(it, color = androidx.compose.material3.MaterialTheme.colorScheme.error) }
                }
            },
            confirmButton = {
                TextButton(
                    enabled = !loading && username.trim().length >= 3,
                    onClick = {
                        scope.launch {
                            loading = true
                            val result = onOpenDirect(username.trim().removePrefix("@"))
                            loading = false
                            result.onSuccess {
                                username = ""
                                showDirectDialog = false
                            }.onFailure {
                                error = it.message ?: "کاربر پیدا نشد یا سرور پاسخ نداد."
                            }
                        }
                    }
                ) { Text(if (loading) "..." else "Open") }
            },
            dismissButton = {
                TextButton(onClick = { showDirectDialog = false }) { Text("Cancel") }
            }
        )
    }
}
