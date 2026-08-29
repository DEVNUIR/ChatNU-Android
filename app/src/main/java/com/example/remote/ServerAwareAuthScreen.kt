package com.example.remote

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Dns
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun ServerAwareAuthScreen(
    initialServerUrl: String,
    onChangeServer: (String) -> Result<String>,
    onLogin: suspend (String, String) -> AuthResult,
    onRegister: suspend (String, String, String) -> AuthResult,
    onAuthSuccess: () -> Unit
) {
    var serverUrl by remember(initialServerUrl) { mutableStateOf(initialServerUrl) }
    var draftServer by remember(initialServerUrl) { mutableStateOf(ServerEndpoint.enrollmentValue()) }
    var showServerDialog by remember { mutableStateOf(false) }
    var serverError by remember { mutableStateOf<String?>(null) }

    Box(modifier = Modifier.fillMaxSize()) {
        ChatNuAuthScreen2026(
            onLogin = onLogin,
            onRegister = onRegister,
            onAuthSuccess = onAuthSuccess
        )

        TextButton(
            onClick = {
                draftServer = ServerEndpoint.enrollmentValue()
                serverError = null
                showServerDialog = true
            },
            modifier = Modifier
                .align(Alignment.TopEnd)
                .statusBarsPadding()
                .padding(horizontal = 8.dp, vertical = 4.dp)
        ) {
            Icon(Icons.Default.Dns, contentDescription = "Change server")
            Text("  ${ServerEndpoint.hostLabel()}")
        }
    }

    if (showServerDialog) {
        AlertDialog(
            onDismissRequest = { showServerDialog = false },
            title = { Text("Choose ChatNU server") },
            text = {
                Column {
                    Text(
                        "Paste your HTTPS server address. During an Internet blackout, you can paste the full emergency enrollment link produced by the ChatNU server tooling. ChatNU pins that server's local CA instead of disabling TLS verification."
                    )
                    OutlinedTextField(
                        value = draftServer,
                        onValueChange = {
                            draftServer = it
                            serverError = null
                        },
                        label = { Text("https://chat.example.com") },
                        singleLine = true,
                        modifier = Modifier.padding(top = 12.dp)
                    )
                    if (ServerEndpoint.isEmergencyTls()) {
                        Text(
                            "Emergency CA pin is active for this server.",
                            color = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.padding(top = 8.dp)
                        )
                    }
                    serverError?.let {
                        Text(
                            it,
                            color = MaterialTheme.colorScheme.error,
                            modifier = Modifier.padding(top = 8.dp)
                        )
                    }
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        onChangeServer(draftServer)
                            .onSuccess { normalized ->
                                serverUrl = normalized
                                draftServer = ServerEndpoint.enrollmentValue()
                                showServerDialog = false
                            }
                            .onFailure { serverError = it.message ?: "Invalid server address." }
                    }
                ) { Text("Use server") }
            },
            dismissButton = {
                TextButton(onClick = { showServerDialog = false }) { Text("Cancel") }
            }
        )
    }
}
