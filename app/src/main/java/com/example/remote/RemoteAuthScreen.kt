package com.example.remote

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch

@Composable
fun RemoteAuthScreen(
    onLogin: suspend (String, String) -> AuthResult,
    onRegister: suspend (String, String, String) -> AuthResult,
    onAuthSuccess: () -> Unit
) {
    var registerMode by remember { mutableStateOf(false) }
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var displayName by remember { mutableStateOf("") }
    var loading by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var recoveryCode by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    Column(
        modifier = Modifier.fillMaxSize().padding(28.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text("ChatNU", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold)
        Text("Self-hosted messenger", color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(Modifier.height(28.dp))

        if (recoveryCode != null) {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("Recovery code", fontWeight = FontWeight.Bold)
                    Text("این کد را یک جای امن نگه دار. برای reset کردن پسورد لازم می‌شود.")
                    Text(recoveryCode!!, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Button(onClick = onAuthSuccess, modifier = Modifier.fillMaxWidth()) {
                        Text("ذخیره کردم، ادامه")
                    }
                }
            }
            return@Column
        }

        OutlinedTextField(
            value = username,
            onValueChange = { username = it },
            label = { Text("Username") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )
        if (registerMode) {
            Spacer(Modifier.height(10.dp))
            OutlinedTextField(
                value = displayName,
                onValueChange = { displayName = it },
                label = { Text("Display name") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
        }
        Spacer(Modifier.height(10.dp))
        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("Password") },
            singleLine = true,
            visualTransformation = PasswordVisualTransformation(),
            modifier = Modifier.fillMaxWidth()
        )

        error?.let {
            Spacer(Modifier.height(10.dp))
            Text(it, color = MaterialTheme.colorScheme.error)
        }

        Spacer(Modifier.height(18.dp))
        Button(
            enabled = !loading && username.trim().length >= 3 && password.length >= 10 && (!registerMode || displayName.isNotBlank()),
            onClick = {
                scope.launch {
                    loading = true
                    error = null
                    val result = if (registerMode) {
                        onRegister(username, password, displayName)
                    } else {
                        onLogin(username, password)
                    }
                    loading = false
                    if (!result.success) {
                        error = result.error
                    } else if (result.recoveryCode != null) {
                        recoveryCode = result.recoveryCode
                    } else {
                        onAuthSuccess()
                    }
                }
            },
            modifier = Modifier.fillMaxWidth()
        ) {
            if (loading) CircularProgressIndicator(modifier = Modifier.height(20.dp))
            else Text(if (registerMode) "ساخت حساب" else "ورود")
        }

        TextButton(onClick = { registerMode = !registerMode; error = null }) {
            Text(if (registerMode) "حساب داری؟ وارد شو" else "حساب نداری؟ ثبت‌نام")
        }
    }
}
