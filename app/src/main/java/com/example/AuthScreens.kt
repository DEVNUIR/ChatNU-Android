package com.example.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.example.ui.theme.ChatNuAccent
import com.example.ui.theme.ChatNuEncryptedGreen

@Composable
fun AuthScreen(
    onAuthSuccess: () -> Unit
) {
    var isRegisterState by remember { mutableStateOf(false) }
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var displayName by remember { mutableStateOf("") }
    var generatedRecoveryCode by remember { mutableStateOf<String?>(null) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(24.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Surface(
                shape = RoundedCornerShape(20.dp),
                color = ChatNuAccent,
                modifier = Modifier.size(72.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Shield,
                    contentDescription = "ChatNU Logo",
                    tint = Color.White,
                    modifier = Modifier.padding(16.dp)
                )
            }

            Text(
                text = "ChatNU",
                style = MaterialTheme.typography.headlineLarge.copy(fontWeight = FontWeight.Bold),
                color = MaterialTheme.colorScheme.onBackground
            )

            Text(
                text = "E2EE Native Messenger • devnu.ir",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f)
            )

            Spacer(modifier = Modifier.height(12.dp))

            OutlinedTextField(
                value = username,
                onValueChange = { username = it },
                label = { Text("Username") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )

            if (isRegisterState) {
                OutlinedTextField(
                    value = displayName,
                    onValueChange = { displayName = it },
                    label = { Text("Display Name") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            }

            OutlinedTextField(
                value = password,
                onValueChange = { password = it },
                label = { Text("Password") },
                visualTransformation = PasswordVisualTransformation(),
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )

            if (generatedRecoveryCode != null) {
                Card(
                    colors = CardDefaults.cardColors(containerColor = ChatNuEncryptedGreen.copy(alpha = 0.15f)),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Security, contentDescription = null, tint = ChatNuEncryptedGreen)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Save Emergency Recovery Code", fontWeight = FontWeight.Bold, color = ChatNuEncryptedGreen)
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = generatedRecoveryCode!!,
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                            color = MaterialTheme.colorScheme.onSurface
                        )
                    }
                }
            }

            Button(
                onClick = {
                    if (isRegisterState && generatedRecoveryCode == null) {
                        generatedRecoveryCode = "CHATNU-RCVR-9876-5432-1011"
                    } else {
                        onAuthSuccess()
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                colors = ButtonDefaults.buttonColors(containerColor = ChatNuAccent)
            ) {
                Text(
                    text = if (generatedRecoveryCode != null) "Confirm & Continue" else if (isRegisterState) "Generate Account & Keys" else "Secure Login",
                    style = MaterialTheme.typography.titleMedium
                )
            }

            TextButton(onClick = {
                isRegisterState = !isRegisterState
                generatedRecoveryCode = null
            }) {
                Text(
                    text = if (isRegisterState) "Already have an account? Login" else "Don't have an account? Register on devnu.ir",
                    color = ChatNuAccent
                )
            }
        }
    }
}
